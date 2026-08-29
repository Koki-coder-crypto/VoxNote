import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var memoStore: MemoStore
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if store.isPro {
                        Label("VoxNote Pro — Active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.purple)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Free Plan")
                                .font(.subheadline.bold())
                            Text("\(StoreManager.freeTranscriptionsPerMonth) transcriptions / month · 5 min max")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("Upgrade to Pro") { showPaywall = true }
                            .foregroundStyle(.purple)
                    }
                } header: { Text("Subscription") }

                Section("Storage") {
                    LabeledContent("Saved Memos", value: "\(memoStore.memos.count)")
                    Button("Delete All Memos", role: .destructive) { showDeleteConfirm = true }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    Link("Privacy Policy", destination: URL(string: "https://koki-coder-crypto.github.io/VoxNote/privacy.html")!)
                    Link("Terms of Service", destination: URL(string: "https://koki-coder-crypto.github.io/VoxNote/terms.html")!)
                    Link("Support", destination: URL(string: "https://koki-coder-crypto.github.io/VoxNote/support.html")!)
                }

                Section {
                    Button("Restore Purchases") {
                        Task { await store.restorePurchases() }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog("Delete All Memos?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    memoStore.memos.indices.reversed().forEach { idx in
                        memoStore.delete(at: IndexSet(integer: idx))
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all memos and their audio recordings.")
            }
        }
    }
}
