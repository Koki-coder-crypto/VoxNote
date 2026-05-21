import SwiftUI

struct MemoListView: View {
    @EnvironmentObject var memoStore: MemoStore
    @State private var searchText = ""
    @State private var selectedMemo: Memo?

    var filtered: [Memo] {
        guard !searchText.isEmpty else { return memoStore.memos }
        return memoStore.memos.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.transcript.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Memos Yet" : "No Results",
                        systemImage: "waveform.slash",
                        description: Text(searchText.isEmpty
                            ? "Your recorded memos will appear here."
                            : "Try a different search term.")
                    )
                } else {
                    List {
                        ForEach(filtered) { memo in
                            MemoRow(memo: memo)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedMemo = memo }
                        }
                        .onDelete { memoStore.delete(at: $0) }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Memos")
            .searchable(text: $searchText, prompt: "Search memos")
            .navigationDestination(item: $selectedMemo) { memo in
                MemoDetailView(memo: memo)
            }
        }
    }
}

struct MemoRow: View {
    let memo: Memo

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "waveform")
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                if let summary = memo.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if !memo.transcript.isEmpty {
                    Text(memo.transcript)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(memo.formattedDuration)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(memo.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
