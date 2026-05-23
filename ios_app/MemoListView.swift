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
            ZStack {
                Color.appBG.ignoresSafeArea()

                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { memo in
                            MemoCard(memo: memo)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedMemo = memo }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        if let i = memoStore.memos.firstIndex(where: { $0.id == memo.id }) {
                                            memoStore.delete(at: IndexSet(integer: i))
                                        }
                                    } label: { Label("Delete", systemImage: "trash.fill") }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.appBG)
                }
            }
            .navigationTitle("Memos")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appBG, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search memos")
            .navigationDestination(item: $selectedMemo) { MemoDetailView(memo: $0) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.appAccent.opacity(0.08)).frame(width: 100, height: 100)
                Image(systemName: "waveform.slash").font(.system(size: 40)).foregroundStyle(Color.appMuted)
            }
            VStack(spacing: 8) {
                Text("No Memos Yet").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                Text("Your recorded memos will appear here.")
                    .font(.system(size: 15)).foregroundStyle(Color.appMuted).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MemoCard: View {
    let memo: Memo

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let summary = memo.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                        .lineLimit(2)
                } else if !memo.transcript.isEmpty {
                    Text(memo.transcript)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                        .lineLimit(2)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(memo.formattedDuration)
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(Color.appMuted)
                Text(memo.createdAt, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appMuted.opacity(0.6))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
        )
    }
}
