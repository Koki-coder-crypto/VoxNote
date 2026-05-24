import SwiftUI
import AVFoundation
import Speech

struct RecordView: View {
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var memoStore: MemoStore
    @State private var ambientPhase = false
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
    @State private var pulseScale: CGFloat = 1.0

    private var maxDuration: TimeInterval { store.isPro ? 3600 : 300 }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            ambientGlow

            VStack(spacing: 0) {
                topBar
                Spacer()
                waveformOrb
                Spacer()
                timerDisplay.padding(.bottom, 24)
                controlRow.padding(.bottom, 28)
                if !store.isPro { freeFooter.padding(.bottom, 100) }
                else { Spacer().frame(height: 100) }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("Microphone Access Required", isPresented: $permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable microphone access in Settings to record memos.")
        }
        .onAppear { startPulse() } ambientPhase = true;
    }

    // MARK: - Components

    private var ambientGlow: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            Ellipse()
                .fill(Color.appAccent.opacity(isRecording ? 0.22 : 0.14))
                .frame(width: 380, height: 280).blur(radius: 80)
                .offset(x: 60, y: -200).offset(y: ambientPhase ? 22 : -22)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: ambientPhase)
            Ellipse()
                .fill(Color(hex: "A78BFA").opacity(0.09))
                .frame(width: 320, height: 220).blur(radius: 70)
                .offset(x: -80, y: 120).offset(x: ambientPhase ? 18 : -18)
                .animation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true), value: ambientPhase)
            Ellipse()
                .fill(Color.appAccent.opacity(0.07))
                .frame(width: 220, height: 160).blur(radius: 60)
                .offset(x: 20, y: 340).scaleEffect(ambientPhase ? 1.25 : 1.0)
                .animation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true), value: ambientPhase)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack {
            Text("VoxNote")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Color.appAccent, Color(hex: "60A5FA")],
                                   startPoint: .leading, endPoint: .trailing)
                )
            Spacer()
            if !store.isPro {
                Button { showPaywall = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "crown.fill").font(.system(size: 10))
                            .foregroundStyle(Color(hex: "F59E0B"))
                        Text("Pro").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    private var waveformOrb: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.appAccent.opacity(isRecording ? 0.12 - Double(i) * 0.03 : 0), lineWidth: 1)
                    .frame(width: 180 + CGFloat(i) * 30, height: 180 + CGFloat(i) * 30)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(Double(i) * 0.2), value: pulseScale)
            }

            // Mid ring
            Circle()
                .fill(Color.appAccent.opacity(isRecording ? 0.18 : 0.08))
                .frame(width: 160, height: 160)
                .animation(.easeInOut(duration: 0.4), value: isRecording)

            // Core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appAccent.opacity(0.3), Color.appAccent.opacity(0.05)],
                        center: .center, startRadius: 0, endRadius: 70
                    )
                )
                .frame(width: 120, height: 120)

            // Icon
            Image(systemName: isProcessing ? "waveform.circle" : (isRecording ? "waveform" : "mic.fill"))
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(
                    LinearGradient(colors: [Color.appAccent, Color(hex: "60A5FA")],
                                   startPoint: .top, endPoint: .bottom)
                )
                .symbolEffect(.pulse, isActive: isRecording)

            if isProcessing {
                Circle()
                    .stroke(Color.appAccent.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.6)
                            .stroke(Color.appAccent, lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(isProcessing ? 360 : 0))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isProcessing)
                    )
            }
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(formatDuration(elapsed))
                .font(.system(size: 60, weight: .thin, design: .monospaced))
                .foregroundStyle(isRecording ? .white : Color.appMuted)
                .animation(.easeInOut(duration: 0.3), value: isRecording)

            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appMuted)
                .animation(.easeInOut, value: isRecording)
        }
    }

    private var statusText: String {
        if isProcessing { return "AI is analyzing…" }
        if isPaused { return "Paused" }
        if isRecording { return "Recording…" }
        if elapsed > 0 { return "Ready to process" }
        return "Tap to start recording"
    }

    private var controlRow: some View {
        HStack(spacing: 40) {
            // Cancel (visible when recording or after)
            if isRecording || elapsed > 0 {
                Button { cancelRecording() } label: {
                    ZStack {
                        Circle()
                            .fill(Color.appSurface)
                            .frame(width: 56, height: 56)
                            .overlay(Circle().stroke(Color.appBorder, lineWidth: 1))
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appMuted)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Spacer().frame(width: 56)
            }

            // Main button
            Button {
                guard !isProcessing else { return }
                if !isRecording && elapsed == 0 { startRecording() }
                else if isRecording { stopAndProcess() }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color.appAccent, Color.appAccentAlt],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: Color.appAccent.opacity(isRecording ? 0.5 : 0.3),
                                radius: isRecording ? 20 : 12, y: 6)

                    if isProcessing {
                        ProgressView().tint(.white)
                    } else if isRecording {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(.white)
                            .frame(width: 30, height: 30)
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: 34, height: 34)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            // Pause / Resume
            if isRecording {
                Button { isPaused ? resumeRecording() : pauseRecording() } label: {
                    ZStack {
                        Circle()
                            .fill(Color.appSurface)
                            .frame(width: 56, height: 56)
                            .overlay(Circle().stroke(Color.appBorder, lineWidth: 1))
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Spacer().frame(width: 56)
            }
        }
    }

    private var freeFooter: some View {
        let remaining = max(0, StoreManager.freeTranscriptionsPerMonth - monthlyCount)
        return HStack(spacing: 8) {
            Image(systemName: "sparkles").font(.system(size: 12)).foregroundStyle(Color(hex: "F39C12"))
            Text("\(remaining) free transcriptions left this month")
                .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.appMuted)
            Spacer()
            Button("Upgrade") { showPaywall = true }
                .font(.system(size: 12, weight: .bold)).foregroundStyle(Color.appAccent)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Logic

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulseScale = 1.08 }
    }

    private func startRecording() {
        if !store.isPro && monthlyCount >= StoreManager.freeTranscriptionsPerMonth {
            showPaywall = true; return
        }
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else { permissionDenied = true; return }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else { permissionDenied = true; return }
                        Haptics.impact(.medium)
                        let r = AudioRecorder()
                        r.start(in: memoStore.audioDirectory)
                        recorder = r
                        withAnimation { isRecording = true }
                        startTimer()
                    }
                }
            }
        }
    }

    private func pauseRecording() {
        recorder?.pause(); isPaused = true; timer?.invalidate()
        Haptics.impact(.light)
    }
    private func resumeRecording() {
        recorder?.resume(); isPaused = false; startTimer()
        Haptics.impact(.light)
    }
    private func cancelRecording() {
        recorder?.cancel(); recorder = nil
        withAnimation { isRecording = false }
        isPaused = false; elapsed = 0; timer?.invalidate()
        Haptics.impact(.medium)
    }

    private func stopAndProcess() {
        timer?.invalidate()
        withAnimation { isRecording = false }
        isPaused = false; isProcessing = true
        Haptics.notification(.success)

        guard let r = recorder else { isProcessing = false; return }
        let audioURL = r.stop(); recorder = nil
        let duration = elapsed

        Task {
            do {
                let transcript = try await VoxNoteAI.shared.transcribe(audioURL: audioURL)
                let analysis   = try await VoxNoteAI.shared.analyze(transcript: transcript)
                let memo = Memo(title: analysis.title, duration: duration, transcript: transcript,
                                summary: analysis.summary, keyPoints: analysis.keyPoints,
                                actionItems: analysis.actionItems, audioFileName: audioURL.lastPathComponent)
                await MainActor.run {
                    memoStore.save(memo); monthlyCount += 1; elapsed = 0; isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription; elapsed = 0; isProcessing = false
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
        String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Audio Recorder (unchanged from original)

class AudioRecorder {
    private var engine: AVAudioEngine?
    private var file: AVAudioFile?
    private var fileURL: URL?

    func start(in directory: URL) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .default)
        try? session.setActive(true)
        let url = directory.appendingPathComponent("\(UUID().uuidString).m4a")
        fileURL = url
        let eng = AVAudioEngine(); engine = eng
        let input = eng.inputNode
        let format = input.outputFormat(forBus: 0)
        let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                        AVSampleRateKey: format.sampleRate,
                                        AVNumberOfChannelsKey: format.channelCount]
        file = try? AVAudioFile(forWriting: url, settings: settings)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buf, _ in
            try? self?.file?.write(from: buf)
        }
        try? eng.start()
    }

    func pause() { engine?.pause() }
    func resume() { try? engine?.start() }
    func stop() -> URL {
        engine?.inputNode.removeTap(onBus: 0); engine?.stop(); file = nil; return fileURL!
    }
    func cancel() {
        engine?.inputNode.removeTap(onBus: 0); engine?.stop(); file = nil
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
    }
}
