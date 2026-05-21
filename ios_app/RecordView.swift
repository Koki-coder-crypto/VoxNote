import SwiftUI
import AVFoundation
import Speech

struct RecordView: View {
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var memoStore: MemoStore
    @State private var recorder: AudioRecorder?
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isProcessing = false
    @State private var showPaywall = false
    @State private var permissionDenied = false
    @State private var errorMessage: String?
    @State private var monthlyCount = 0

    private var maxDuration: TimeInterval { store.isPro ? 3600 : 300 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                waveformSection
                Spacer()
                timerDisplay
                Spacer()
                controlArea
                Spacer()
                if !store.isPro {
                    freeUsageFooter
                }
            }
            .navigationTitle("VoxNote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !store.isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Pro") { showPaywall = true }
                            .font(.footnote.bold())
                            .foregroundStyle(.purple)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Microphone Access Required",
                   isPresented: $permissionDenied,
                   actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("Please enable microphone access in Settings to record memos.")
            })
        }
    }

    // MARK: - Waveform

    private var waveformSection: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(isRecording ? 0.12 : 0.06))
                .frame(width: 200, height: 200)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)

            Circle()
                .fill(Color.purple.opacity(isRecording ? 0.2 : 0.1))
                .frame(width: 150, height: 150)

            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple)
                .symbolEffect(.pulse, isActive: isRecording)
        }
    }

    // MARK: - Timer

    private var timerDisplay: some View {
        VStack(spacing: 6) {
            Text(formatDuration(elapsed))
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundStyle(isRecording ? .primary : .secondary)

            if isRecording || elapsed > 0 {
                Text(isPaused ? "Paused" : "Recording…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Tap to start recording")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Controls

    private var controlArea: some View {
        HStack(spacing: 48) {
            if isRecording || elapsed > 0 {
                // Cancel
                Button {
                    cancelRecording()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .frame(width: 52, height: 52)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }
                .foregroundStyle(.secondary)
            }

            // Main record / stop button
            Button {
                if isProcessing { return }
                if !isRecording && elapsed == 0 {
                    startRecording()
                } else if isRecording {
                    stopAndProcess()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.purple)
                        .frame(width: 80, height: 80)

                    if isProcessing {
                        ProgressView().tint(.white)
                    } else if isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .disabled(isProcessing)

            if isRecording {
                // Pause / Resume
                Button {
                    isPaused ? resumeRecording() : pauseRecording()
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .frame(width: 52, height: 52)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }
                .foregroundStyle(.purple)
            } else if elapsed > 0 {
                Spacer().frame(width: 52)
            }
        }
    }

    private var freeUsageFooter: some View {
        let remaining = max(0, StoreManager.freeTranscriptionsPerMonth - monthlyCount)
        return HStack {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .font(.caption)
            Text("\(remaining) free transcriptions left this month")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Upgrade") { showPaywall = true }
                .font(.caption.bold())
                .foregroundStyle(.purple)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func startRecording() {
        if !store.isPro && monthlyCount >= StoreManager.freeTranscriptionsPerMonth {
            showPaywall = true
            return
        }

        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else { permissionDenied = true; return }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else { permissionDenied = true; return }
                        let r = AudioRecorder()
                        r.start(in: memoStore.audioDirectory)
                        recorder = r
                        isRecording = true
                        startTimer()
                    }
                }
            }
        }
    }

    private func pauseRecording() {
        recorder?.pause()
        isPaused = true
        timer?.invalidate()
    }

    private func resumeRecording() {
        recorder?.resume()
        isPaused = false
        startTimer()
    }

    private func cancelRecording() {
        recorder?.cancel()
        recorder = nil
        isRecording = false
        isPaused = false
        elapsed = 0
        timer?.invalidate()
    }

    private func stopAndProcess() {
        timer?.invalidate()
        isRecording = false
        isPaused = false
        isProcessing = true

        guard let r = recorder else { isProcessing = false; return }
        let audioURL = r.stop()
        recorder = nil
        let duration = elapsed

        Task {
            do {
                let transcript = try await VoxNoteAI.shared.transcribe(audioURL: audioURL)
                let analysis = try await VoxNoteAI.shared.analyze(transcript: transcript)

                let memo = Memo(
                    title: analysis.title,
                    duration: duration,
                    transcript: transcript,
                    summary: analysis.summary,
                    keyPoints: analysis.keyPoints,
                    actionItems: analysis.actionItems,
                    audioFileName: audioURL.lastPathComponent
                )
                await MainActor.run {
                    memoStore.save(memo)
                    monthlyCount += 1
                    elapsed = 0
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    elapsed = 0
                    isProcessing = false
                }
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsed += 0.1
            if elapsed >= maxDuration { stopAndProcess() }
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Audio Recorder

class AudioRecorder {
    private var engine: AVAudioEngine?
    private var file: AVAudioFile?
    private var fileURL: URL?

    func start(in directory: URL) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .default)
        try? session.setActive(true)

        let fileName = "\(UUID().uuidString).m4a"
        let url = directory.appendingPathComponent(fileName)
        fileURL = url

        let eng = AVAudioEngine()
        engine = eng
        let input = eng.inputNode
        let format = input.outputFormat(forBus: 0)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount
        ]

        file = try? AVAudioFile(forWriting: url, settings: settings)

        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            try? self?.file?.write(from: buffer)
        }

        try? eng.start()
    }

    func pause() { engine?.pause() }
    func resume() { try? engine?.start() }

    func stop() -> URL {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        file = nil
        return fileURL!
    }

    func cancel() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        file = nil
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
    }
}
