import Foundation

struct Memo: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var duration: TimeInterval
    var transcript: String
    var summary: String?
    var keyPoints: [String]
    var actionItems: [String]
    var audioFileName: String

    init(
        id: UUID = UUID(),
        title: String = "",
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        transcript: String = "",
        summary: String? = nil,
        keyPoints: [String] = [],
        actionItems: [String] = [],
        audioFileName: String = ""
    ) {
        self.id = id
        self.title = title.isEmpty ? "Memo \(Self.formattedDate(createdAt))" : title
        self.createdAt = createdAt
        self.duration = duration
        self.transcript = transcript
        self.summary = summary
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.audioFileName = audioFileName
    }

    private static func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d HH:mm"
        return f.string(from: date)
    }

    var formattedDuration: String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

@MainActor
class MemoStore: ObservableObject {
    @Published private(set) var memos: [Memo] = []

    private let storageURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voxnote_memos.json")
    }()

    var audioDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voxnote_audio", isDirectory: true)
    }

    init() {
        try? FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        load()
    }

    func save(_ memo: Memo) {
        if let idx = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[idx] = memo
        } else {
            memos.insert(memo, at: 0)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        offsets.forEach { idx in
            let memo = memos[idx]
            let audioURL = audioDirectory.appendingPathComponent(memo.audioFileName)
            try? FileManager.default.removeItem(at: audioURL)
        }
        memos.remove(atOffsets: offsets)
        persist()
    }

    func audioURL(for memo: Memo) -> URL {
        audioDirectory.appendingPathComponent(memo.audioFileName)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Memo].self, from: data)
        else { return }
        memos = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(memos) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
