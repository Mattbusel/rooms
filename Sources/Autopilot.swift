import SwiftUI

/// Drives the real screens for the App Review recording (-demoAutoplay).
@Observable
final class Autopilot {
    static let shared = Autopilot()
    static var on: Bool { ProcessInfo.processInfo.arguments.contains("-demoAutoplay") }
    private var running = false
    @MainActor private func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
    @MainActor
    func run(_ store: Store, _ router: Router) {
        guard Autopilot.on, !running else { return }
        running = true
        Task { @MainActor in
            await wait(3.5)
            let kitchen = store.rooms.first { $0.name == "Kitchen" } ?? store.rooms[0]
            withAnimation { router.path = [.room(kitchen.id)] }; await wait(3.5)
            if let hero = store.items(in: kitchen).first { withAnimation { router.path.append(.item(hero.id)) }; await wait(4) }
            withAnimation { router.path = [] }; await wait(1.5)
            withAnimation { router.tab = .coverage }; await wait(4.5)
            withAnimation { router.tab = .value }; await wait(4)
            withAnimation { router.tab = .report }; await wait(5)
            withAnimation { router.tab = .inventory }; await wait(1.2)
            router.creating = true; await wait(4)
            router.creating = false; await wait(1.5)
            try? Data("ok".utf8).write(to: URL.documentsDirectory.appending(path: "demo_done"))
        }
    }
}
