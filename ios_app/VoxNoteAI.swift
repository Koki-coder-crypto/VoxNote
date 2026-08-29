import Foundation
import Speech
import AVFoundation

/// Local transcription and memo organization. Audio and transcript text are never uploaded.
actor VoxNoteAI {
    static let shared = VoxNoteAI()

    func transcribe(audioURL: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer(locale: Locale.current)
        guard recognizer?.isAvailable == true, recognizer?.supportsOnDeviceRecognition == true else {
            throw VoxNoteError.speechUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        request.requiresOnDeviceRecognition = true

        return try await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error { continuation.resume(throwing: error); return }
                if let result, result.isFinal { continuation.resume(returning: result.bestTranscription.formattedString) }
            }
        }
    }

    struct AnalysisResult {
        let title: String
        let summary: String
        let keyPoints: [String]
        let actionItems: [String]
    }

    /// Creates deterministic, on-device highlights from the transcript.
    func analyze(transcript: String) async throws -> AnalysisResult {
        let sentences = transcript
            .split(whereSeparator: { ".!?。！？\n".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let fallbackTitle = Locale.current.language.languageCode?.identifier == "ja" ? "音声メモ" : "Voice memo"
        let title = String((sentences.first ?? fallbackTitle).prefix(48))
        let summary = String(sentences.prefix(3).joined(separator: ". ").prefix(280))
        let points = Array(sentences.prefix(5)).map { String($0.prefix(140)) }
        let actionTerms = ["todo", "to do", "action", "follow up", "やる", "対応", "確認", "期限"]
        let actions = sentences.filter { sentence in
            let lower = sentence.lowercased()
            return actionTerms.contains { lower.contains($0) || sentence.contains($0) }
        }.prefix(5).map { String($0.prefix(140)) }

        return AnalysisResult(title: title, summary: summary, keyPoints: points, actionItems: actions)
    }
}

enum VoxNoteError: LocalizedError {
    case speechUnavailable, permissionDenied

    var errorDescription: String? {
        switch self {
        case .speechUnavailable: "On-device speech recognition is unavailable for this language on this device."
        case .permissionDenied: "Microphone access is required. Please enable it in Settings."
        }
    }
}
