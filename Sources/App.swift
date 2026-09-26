import SwiftUI
import Observation

@main
struct RoomsApp: App {
    @State private var store: Store
    @State private var router = Router()
    @State private var pro: Pro
    init() {
        let a = ProcessInfo.processInfo.arguments
        let demo = a.contains("-shot") || a.contains("-demoAutoplay")
        _store = State(initialValue: Store(demo: demo))
        // Screenshots and the review recording never touch StoreKit. The paywall shot shows the free app.
        let paywallShot = a.firstIndex(of: "-shot").map { $0 + 1 < a.count && a[$0 + 1] == "paywall" } ?? false
        let p = demo ? Pro(forced: !paywallShot) : Pro()
        if paywallShot { p.paywall = .report }
        _pro = State(initialValue: p)
    }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).environment(router).environment(pro).preferredColorScheme(.light).tint(Paper.ink)
                .onAppear { router.applyShotArgs(store); Autopilot.shared.run(store, router) }
        }
    }
}

enum Tab: String, CaseIterable {
    case inventory = "Inventory", coverage = "Coverage", value = "Value", report = "Report"
    var icon: String {
        switch self {
        case .inventory: return "house.fill"
        case .coverage: return "shield.lefthalf.filled"
        case .value: return "chart.line.downtrend.xyaxis"
        case .report: return "doc.text.fill"
        }
    }
}

enum Route: Hashable { case room(UUID), item(UUID) }

@Observable
final class Router {
    var tab: Tab = .inventory
    var path: [Route] = []
    var editing: Item? = nil
    var creating = false
    var newRoomID: UUID? = nil
    var editingHome = false
    func applyShotArgs(_ s: Store) {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-shot"), i + 1 < a.count else { return }
        let kitchen = s.rooms.first { $0.name == "Kitchen" } ?? s.rooms[0]
        let hero = s.items(in: kitchen).first { $0.name.hasPrefix("Refrigerator") } ?? s.items(in: kitchen)[0]
        switch a[i + 1] {
        case "room": path = [.room(kitchen.id)]
        case "item": path = [.room(kitchen.id), .item(hero.id)]
        case "coverage": tab = .coverage
        case "value": tab = .value
        case "report", "paywall": tab = .report
        case "add": creating = true
        default: break
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro
    var body: some View {
        @Bindable var router = router
        @Bindable var pro = pro
        ZStack(alignment: .bottom) {
            PaperBackground()
            Group {
                switch router.tab {
                case .inventory: InventoryNav()
                case .coverage: CoverageView()
                case .value: ValueView()
                case .report: ReportView()
                }
            }
            Rail(selection: $router.tab) {
                guard store.items.count < Pro.freeItems || pro.allow(.items) else { return }
                router.creating = true
            }.padding(.bottom, 2)
        }
        .sheet(item: $router.editing) { it in ItemEditor(item: it, isNew: false).presentationBackground(Paper.bg).presentationDetents([.large]) }
        .sheet(isPresented: $router.creating) {
            ItemEditor(item: Item(name: "", roomID: router.newRoomID ?? store.rooms.first?.id ?? UUID()), isNew: true).presentationBackground(Paper.bg).presentationDetents([.large])
        }
        .sheet(isPresented: $router.editingHome) { HomeEditor().presentationBackground(Paper.bg).presentationDetents([.large]) }
        .sheet(item: $pro.paywall) { r in PaywallView(reason: r).presentationBackground(Paper.bg) }
    }
}

struct InventoryNav: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            InventoryView()
                .navigationDestination(for: Route.self) { r in
                    switch r {
                    case .room(let id): if let room = store.room(id) { RoomView(room: room) } else { InventoryView() }
                    case .item(let id): if let it = store.items.first(where: { $0.id == id }) { ItemView(id: it.id) } else { InventoryView() }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
