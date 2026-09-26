import SwiftUI
import StoreKit

/// Rooms Pro: one non-consumable. Cataloguing is free: rooms, photos, serials, receipts,
/// coverage caps and depreciation for the first freeItems things you own. Pro is the whole
/// house and the payoff: unlimited items, the PDF claim report and the CSV.
///
/// Anyone whose first download was a build before firstFreemiumBuild paid for the app and keeps
/// everything. AppTransaction's originalAppVersion is that build number. Only trusted in
/// production: sandbox and Xcode report made-up values, and App Review must see the paywall.
@MainActor
@Observable
final class Pro {
    static let productID = "com.mattbusel.rooms.pro"
    /// The first build with Pro in it. Anything earlier was the paid app.
    static let firstFreemiumBuild = 2
    /// Items you can list before Pro. Nothing past it is hidden; only adding more asks.
    static let freeItems = 40

    enum Reason: String, Identifiable { case items, report, csv, general; var id: String { rawValue } }

    private(set) var unlocked: Bool
    private(set) var grandfathered = false
    private(set) var product: StoreKit.Product?
    var busy = false
    var message: String?
    var paywall: Reason? = nil

    private var updates: Task<Void, Never>?
    private let key = "rooms.pro.unlocked"
    private let forced: Bool

    /// `forced` is for screenshots and the review recording, which must not touch StoreKit.
    init(forced: Bool? = nil) {
        self.forced = forced != nil
        if let forced { unlocked = forced; return }
        unlocked = UserDefaults.standard.bool(forKey: key)
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.apply(result) }
        }
        Task { await refresh() }
    }

    var price: String { product?.displayPrice ?? "$4.99" }

    /// True when the feature may run; otherwise opens the paywall.
    @discardableResult
    func allow(_ why: Reason) -> Bool {
        if unlocked { return true }
        paywall = why
        return false
    }

    func refresh() async {
        guard !forced else { return }
        if product == nil { product = try? await StoreKit.Product.products(for: [Pro.productID]).first }
        for await result in Transaction.currentEntitlements { await apply(result) }
        if case .verified(let app)? = try? await AppTransaction.shared,
           app.environment == .production, (Int(app.originalAppVersion) ?? Int.max) < Pro.firstFreemiumBuild {
            grandfathered = true
            grant()
        }
    }

    func buy() async {
        guard !forced, !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        if product == nil { product = try? await StoreKit.Product.products(for: [Pro.productID]).first }
        guard let product else {
            message = "The App Store did not answer. Check your connection and try again."
            return
        }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await apply(result)
                if !unlocked { message = "Apple could not confirm the purchase. Try Restore in a minute." }
            case .pending:
                message = "Waiting for approval. Pro unlocks by itself once it is approved."
            case .userCancelled:
                break
            @unknown default:
                message = "Something unexpected happened. You were not charged."
            }
        } catch {
            message = "The purchase did not go through: \(error.localizedDescription)"
        }
    }

    func restore() async {
        guard !forced, !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        do { try await AppStore.sync() } catch {
            if let e = error as? StoreKitError, case .userCancelled = e { return }
            message = "Could not reach the App Store. Check your connection and try again."
            return
        }
        await refresh()
        message = unlocked ? "Pro is unlocked. Welcome back." : "No Pro purchase found on this Apple ID."
    }

    private func apply(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let t) = result, t.productID == Pro.productID else { return }
        if t.revocationDate == nil { grant() } else if !grandfathered { revoke() }
        await t.finish()
    }

    private func grant() {
        guard !unlocked else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { unlocked = true }
        paywall = nil
        UserDefaults.standard.set(true, forKey: key)
    }

    private func revoke() {
        unlocked = false
        UserDefaults.standard.set(false, forKey: key)
    }
}

// MARK: - Paywall: an insurance schedule, stamped

struct PaywallView: View {
    @Environment(Pro.self) private var pro
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let reason: Pro.Reason
    @State private var stamped = false

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Eyebrow("Rooms Pro")
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Paper.ink2)
                                .frame(width: 36, height: 36).overlay(Circle().strokeBorder(Paper.line2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close")
                    }
                    Text(headline).font(.serif(32, .bold)).foregroundStyle(Paper.ink).fixedSize(horizontal: false, vertical: true)
                    Text("Listing your things is free for the first \(Pro.freeItems). Pro covers the whole house and hands the adjuster the file.")
                        .font(.ui(14)).foregroundStyle(Paper.ink2).fixedSize(horizontal: false, vertical: true)

                    schedule
                        .overlay(alignment: .bottomTrailing) {
                            Text("COVERED")
                                .font(.system(size: 30, weight: .black, design: .serif)).tracking(3)
                                .foregroundStyle(Paper.accent.opacity(0.85))
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Paper.accent.opacity(0.85), lineWidth: 3))
                                .rotationEffect(.degrees(-12))
                                .scaleEffect(stamped ? 1 : 2.2).opacity(stamped ? 1 : 0)
                                .padding(18)
                        }

                    if let m = pro.message {
                        Text(m).font(.ui(13, .semibold)).foregroundStyle(Paper.accent).frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    }
                    InkButton(title: pro.busy ? "One moment" : "Unlock Pro for \(pro.price)", icon: "lock.open.fill", tint: Paper.accent) {
                        Task { await pro.buy() }
                    }
                    .disabled(pro.busy)
                    HStack(spacing: 10) {
                        LineButton(title: "Restore purchase", icon: "arrow.clockwise") { Task { await pro.restore() } }
                        Spacer()
                        LineButton(title: "Not now") { dismiss() }
                    }
                    Text("One payment, yours for good. No subscription. Family Sharing works. Every item and photo you have listed stays yours, Pro or not.")
                        .font(.ui(11.5)).foregroundStyle(Paper.dim).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 40)
            }
        }
        .onAppear { withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.35)) { stamped = true } }
        .onChange(of: pro.unlocked) { _, now in if now { dismiss() } }
    }

    var headline: String {
        switch reason {
        case .items: return "The whole house, not just the first \(Pro.freeItems) things."
        case .report: return "The file the adjuster wants, in one tap."
        case .csv: return "Your inventory as a spreadsheet."
        case .general: return "Cover everything you own."
        }
    }

    /// A policy schedule: what Pro adds, as numbered lines on the form.
    var schedule: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SCHEDULE OF COVER").font(.label(10)).tracking(1.6).foregroundStyle(Paper.dim)
                Spacer()
                Text("\(store.items.count) listed").font(.num(12)).foregroundStyle(Paper.ink2)
            }
            .padding(.bottom, 10)
            line(1, "Unlimited items", "Every room, every drawer. No cap at \(Pro.freeItems).")
            line(2, "PDF claim report", "Photos, serials, receipts and totals, room by room.")
            line(3, "Spreadsheet (CSV)", "For the adjuster, your agent or your own records.")
        }
        .box()
    }

    func line(_ n: Int, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)").font(.num(13, .bold)).foregroundStyle(Paper.accent).frame(width: 18, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ui(14.5, .semibold)).foregroundStyle(Paper.ink)
                Text(body).font(.ui(12.5)).foregroundStyle(Paper.ink2).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 9).rule()
    }
}

/// On the Report tab: what the free plan covers, or proof of Pro, and Restore either way.
struct ProCard: View {
    @Environment(Pro.self) private var pro
    @Environment(Store.self) private var store
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow("Rooms Pro")
                Spacer()
                if pro.unlocked { Image(systemName: "checkmark.seal.fill").foregroundStyle(Paper.ok) }
            }
            Text(pro.unlocked ? "Unlocked. Unlimited items, the PDF claim report and the spreadsheet."
                 : "\(min(store.items.count, Pro.freeItems)) of \(Pro.freeItems) free items used. Pro adds unlimited items, the PDF claim report and the spreadsheet for one payment of \(pro.price).")
                .font(.ui(13)).foregroundStyle(Paper.ink2).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                if !pro.unlocked { LineButton(title: "See Pro", icon: "shield.lefthalf.filled") { pro.paywall = .general } }
                LineButton(title: "Restore purchase", icon: "arrow.clockwise") { Task { await pro.restore() } }
                Spacer(minLength: 0)
            }
            if let m = pro.message, pro.paywall == nil {
                Text(m).font(.ui(12, .semibold)).foregroundStyle(Paper.accent)
            }
        }
        .box()
    }
}
