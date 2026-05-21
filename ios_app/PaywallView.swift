import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: String = "com.voxnote.app.pro.annual"
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    planPicker
                    purchaseButton
                    if let error = errorMessage {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                    legalLinks
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.purple)
            Text("VoxNote Pro")
                .font(.title.bold())
            Text("Unlimited transcriptions. Smarter memos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            FeatureRow(icon: "infinity",             color: .purple, text: "Unlimited transcriptions per month")
            FeatureRow(icon: "clock.fill",           color: .blue,   text: "Record up to 60 minutes per memo")
            FeatureRow(icon: "sparkles",             color: .orange, text: "AI summary, key points & action items")
            FeatureRow(icon: "folder.fill",          color: .green,  text: "Smart folder organization")
            FeatureRow(icon: "square.and.arrow.up",  color: .teal,   text: "Export to Notes, PDF, and clipboard")
            FeatureRow(icon: "nosign",               color: .red,    text: "No ads, ever")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var planPicker: some View {
        VStack(spacing: 12) {
            if let annual = store.proAnnual {
                PlanCard(
                    title: "Annual",
                    price: annual.displayPrice + " / year",
                    badge: "Best Value — Save 48%",
                    selected: selectedPlan == annual.id,
                    accentColor: .purple
                ) { selectedPlan = annual.id }
            }
            if let monthly = store.proMonthly {
                PlanCard(
                    title: "Monthly",
                    price: monthly.displayPrice + " / month",
                    badge: nil,
                    selected: selectedPlan == monthly.id,
                    accentColor: .purple
                ) { selectedPlan = monthly.id }
            }
            if let lifetime = store.lifetime {
                PlanCard(
                    title: "Lifetime",
                    price: lifetime.displayPrice + " one-time",
                    badge: "Pay Once, Keep Forever",
                    selected: selectedPlan == lifetime.id,
                    accentColor: .purple
                ) { selectedPlan = lifetime.id }
            }
        }
    }

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await startPurchase() }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(selectedPlan.contains("annual") ? "Try Free for 7 Days" : "Get VoxNote Pro")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.purple)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(isPurchasing)

            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var legalLinks: some View {
        VStack(spacing: 4) {
            Text("Subscriptions auto-renew. Cancel anytime in Apple ID settings.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://github.com/Koki-coder-crypto/LynQ_backend/blob/master/app_store/privacy_policy.html")!)
                Link("Terms of Use", destination: URL(string: "https://github.com/Koki-coder-crypto/LynQ_backend/blob/master/app_store/terms_of_service.html")!)
            }
            .font(.caption2)
        }
    }

    private func startPurchase() async {
        guard let product = store.products.first(where: { $0.id == selectedPlan }) else { return }
        isPurchasing = true
        errorMessage = nil
        do {
            try await store.purchase(product)
            dismiss()
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        isPurchasing = false
    }
}

// MARK: - Shared subviews

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let badge: String?
    let selected: Bool
    var accentColor: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(price).font(.subheadline).foregroundStyle(.secondary)
                    if let badge {
                        Text(badge).font(.caption.bold()).foregroundStyle(.green)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? accentColor : .secondary)
                    .font(.title3)
            }
            .padding()
            .background(selected ? accentColor.opacity(0.08) : Color(.secondarySystemBackground))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? accentColor : Color.clear, lineWidth: 2))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
