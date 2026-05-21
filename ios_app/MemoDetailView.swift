import SwiftUI
import AVFoundation

struct MemoDetailView: View {
    let memo: Memo
    @EnvironmentObject var memoStore: MemoStore
    @State private var isPlaying = false
    @State private var player: AVAudioPlayer?
    @State private var playbackProgress: Double = 0
    @State private var playbackTimer: Timer?
    @State private var copiedSection: String?
    @State private var selectedTab: DetailTab = .summary

    enum DetailTab: String, CaseIterable { case summary = "Summary", transcript = "Transcript" }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                audioPlayer
                tabPicker

                switch selectedTab {
                case .summary:  summarySection
                case .transcript: transcriptSection
                }
            }
            .padding()
        }
        .navigationTitle(memo.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: exportText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onDisappear { stopPlayback() }
    }

    // MARK: - Audio Player

    private var audioPlayer: some View {
        VStack(spacing: 12) {
            ProgressView(value: playbackProgress, total: 1.0)
                .tint(.purple)

            HStack {
                Text(formatTime(playbackProgress * memo.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(memo.formattedDuration)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Button {
                isPlaying ? stopPlayback() : startPlayback()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                    Text(isPlaying ? "Pause" : "Play Recording")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.purple)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary

    @ViewBuilder
    private var summarySection: some View {
        if let summary = memo.summary, !summary.isEmpty {
            InfoCard(title: "AI Summary", icon: "sparkles", color: .purple) {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }

        if !memo.keyPoints.isEmpty {
            InfoCard(title: "Key Points", icon: "list.bullet", color: .blue) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(memo.keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.blue)
                                .padding(.top, 6)
                            Text(point).font(.subheadline)
                        }
                    }
                }
            }
        }

        if !memo.actionItems.isEmpty {
            InfoCard(title: "Action Items", icon: "checkmark.circle", color: .green) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(memo.actionItems, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "square")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                            Text(item).font(.subheadline)
                        }
                    }
                }
            }
        }

        metaCard
    }

    private var metaCard: some View {
        InfoCard(title: "Details", icon: "info.circle", color: .secondary) {
            VStack(spacing: 8) {
                MetaRow(label: "Recorded", value: memo.createdAt.formatted(date: .abbreviated, time: .shortened))
                MetaRow(label: "Duration", value: memo.formattedDuration)
                MetaRow(label: "Words", value: "\(memo.transcript.split(separator: " ").count) words")
            }
        }
    }

    // MARK: - Transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Full Transcript")
                    .font(.headline)
                Spacer()
                Button {
                    UIPasteboard.general.string = memo.transcript
                    copiedSection = "transcript"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedSection = nil }
                } label: {
                    Label(
                        copiedSection == "transcript" ? "Copied!" : "Copy",
                        systemImage: copiedSection == "transcript" ? "checkmark" : "doc.on.doc"
                    )
                    .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }

            Text(memo.transcript.isEmpty ? "No transcript available." : memo.transcript)
                .font(.body)
                .textSelection(.enabled)
                .foregroundStyle(memo.transcript.isEmpty ? .secondary : .primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }

    // MARK: - Playback

    private func startPlayback() {
        let url = memoStore.audioURL(for: memo)
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        player = p
        p.play()
        isPlaying = true

        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard p.isPlaying else { stopPlayback(); return }
            playbackProgress = p.currentTime / p.duration
        }
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        playbackProgress = 0
        playbackTimer?.invalidate()
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(max(0, t)) / 60
        let s = Int(max(0, t)) % 60
        return String(format: "%d:%02d", m, s)
    }

    private var exportText: String {
        var lines = ["# \(memo.title)", "", "**Duration:** \(memo.formattedDuration)", "**Date:** \(memo.createdAt.formatted())", ""]
        if let summary = memo.summary { lines += ["## Summary", summary, ""] }
        if !memo.keyPoints.isEmpty { lines += ["## Key Points"] + memo.keyPoints.map { "- \($0)" } + [""] }
        if !memo.actionItems.isEmpty { lines += ["## Action Items"] + memo.actionItems.map { "- [ ] \($0)" } + [""] }
        lines += ["## Transcript", memo.transcript]
        return lines.joined(separator: "\n")
    }
}

// MARK: - Shared components

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct MetaRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
}
