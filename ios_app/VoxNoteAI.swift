import Foundation
import Speech
import AVFoundation

// MARK: - Transcription + AI Summary Engine

actor VoxNoteAI {
    static let shared = VoxNoteAI()

    private let claudeURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
    }()

    // MARK: - Transcription (Apple Speech, on-device)

    func transcribe(audioURL: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer(locale: Locale.current)
        guard recognizer?.isAvailable == true else {
            throw VoxNoteError.speechUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        return try await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error { continuation.resume(throwing: error); return }
                if let result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    // MARK: - AI Analysis (Claude)

    struct AnalysisResult {
        let title: String
        let summary: String
        let keyPoints: [String]
        let actionItems: [String]
    }

    func analyze(transcript: String) async throws -> AnalysisResult {
        guard !apiKey.isEmpty else { throw VoxNoteError.missingAPIKey }

        let wordCount = transcript.split(separator: " ").count
        guard wordCount > 5 else {
            return AnalysisResult(
                title: "Short Memo",
                summary: transcript,
                keyPoints: [],
                actionItems: []
            )
        }

        let prompt = """
        Analyze this voice memo transcript and respond with ONLY valid JSON, no other text.

        Transcript:
        \(transcript.prefix(4000))

        Respond with exactly this JSON structure:
        {
          "title": "Short descriptive title (max 40 chars)",
          "summary": "2-3 sentence summary of the main content",
          "key_points": ["point 1", "point 2", "point 3"],
          "action_items": ["action 1", "action 2"]
        }

        Rules:
        - title: concise and descriptive
        - summary: clear and useful
        - key_points: up to 5 most important points (empty array if none)
        - action_items: concrete tasks or follow-ups (empty array if none)
        - Use the same language as the transcript
        """

        var request = URLRequest(url: claudeURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 600,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw VoxNoteError.apiError
        }

        let apiResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        let text = apiResponse.content.first?.text ?? "{}"

        if let jsonData = text.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            return AnalysisResult(
                title: parsed["title"] as? String ?? "Voice Memo",
                summary: parsed["summary"] as? String ?? "",
                keyPoints: parsed["key_points"] as? [String] ?? [],
                actionItems: parsed["action_items"] as? [String] ?? []
            )
        }

        return AnalysisResult(title: "Voice Memo", summary: transcript, keyPoints: [], actionItems: [])
    }
}

// MARK: - Supporting types

enum VoxNoteError: LocalizedError {
    case speechUnavailable, missingAPIKey, apiError, permissionDenied

    var errorDescription: String? {
        switch self {
        case .speechUnavailable: return "Speech recognition is not available on this device."
        case .missingAPIKey:     return "API key not configured. Please check settings."
        case .apiError:          return "AI analysis failed. Please try again."
        case .permissionDenied:  return "Microphone access is required. Please enable it in Settings."
        }
    }
}

private struct AnthropicResponse: Decodable {
    struct Content: Decodable { let text: String }
    let content: [Content]
}
