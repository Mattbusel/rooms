import Foundation
import Observation
import UIKit

enum Category: String, Codable, CaseIterable, Identifiable {
    case furniture, electronics, appliances, jewelry, clothing, art, sports, tools, books, kitchen, cash, firearms, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .furniture: return "Furniture"
        case .electronics: return "Electronics"
        case .appliances: return "Appliances"
        case .jewelry: return "Jewelry & watches"
        case .clothing: return "Clothing & shoes"
        case .art: return "Art & collectibles"
        case .sports: return "Sports & outdoor"
        case .tools: return "Tools & garage"
        case .books: return "Books & media"
        case .kitchen: return "Kitchen"
        case .cash: return "Cash"
        case .firearms: return "Firearms"
        case .other: return "Other"
        }
    }
    /// Useful life in years for straight-line depreciation.
    var life: Double {
        switch self {
        case .furniture: return 15
        case .electronics: return 5
        case .appliances: return 12
        case .jewelry: return 50
        case .clothing: return 4
        case .art: return 50
        case .sports: return 8
        case .tools: return 12
        case .books: return 20
        case .kitchen: return 10
        case .cash: return 100
        case .firearms: return 30
        case .other: return 10
        }
    }
    var icon: String {
        switch self {
        case .furniture: return "sofa.fill"
        case .electronics: return "tv.fill"
        case .appliances: return "refrigerator.fill"
        case .jewelry: return "sparkles"
        case .clothing: return "tshirt.fill"
        case .art: return "paintpalette.fill"
        case .sports: return "bicycle"
        case .tools: return "wrench.and.screwdriver.fill"
        case .books: return "books.vertical.fill"
        case .kitchen: return "fork.knife"
        case .cash: return "banknote.fill"
        case .firearms: return "shield.fill"
        case .other: return "shippingbox.fill"
        }
    }
    /// Categories most policies cap per item or in total.
    var capped: Bool { self == .jewelry || self == .cash || self == .firearms || self == .art }
}

enum Condition: String, Codable, CaseIterable { case new = "New", excellent = "Excellent", good = "Good", fair = "Fair", poor = "Poor" }

struct Home: Codable {
    var name = ""
    var address = ""
    var insurer = ""
    var policy = ""
    var claimsPhone = ""
    var cover: Double = 0
    var deductible: Double = 0
    var caps: [String: Double] = ["jewelry": 1500, "cash": 200, "firearms": 2500, "art": 2500]
    var symbol = "$"
    func cap(_ c: Category) -> Double? { caps[c.rawValue] }
}

struct Room: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var icon: String = "door.left.hand.closed"
    static let presets: [(String, String)] = [("Living room", "sofa.fill"), ("Kitchen", "fork.knife"), ("Dining room", "table.furniture.fill"), ("Primary bedroom", "bed.double.fill"), ("Guest bedroom", "bed.double"), ("Kids room", "teddybear.fill"), ("Home office", "desktopcomputer"), ("Bathroom", "shower.fill"), ("Garage", "car.fill"), ("Basement", "stairs"), ("Attic", "house.fill"), ("Hallway", "door.left.hand.open"), ("Outdoors", "leaf.fill"), ("Storage", "shippingbox.fill")]
}

struct Item: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var roomID: UUID
    var category: Category = .other
    var brand: String = ""
    var serial: String = ""
    var qty: Int = 1
    var bought: String = ""            // yyyy-MM-dd or empty
    var price: Double = 0              // what was paid
    var value: Double = 0              // replacement value today, per unit
    var condition: Condition = .good
    var receipt: String = ""
    var notes: String = ""
    var hasPhoto: Bool = false
    var total: Double { value * Double(qty) }
}

/// Quick-add presets with typical replacement values.
struct QuickAdd { let name: String; let category: Category; let value: Double }
let quickAdds: [QuickAdd] = [
    .init(name: "TV", category: .electronics, value: 900), .init(name: "Laptop", category: .electronics, value: 1400), .init(name: "Phone", category: .electronics, value: 1000),
    .init(name: "Sofa", category: .furniture, value: 1800), .init(name: "Bed and mattress", category: .furniture, value: 2200), .init(name: "Dining table and chairs", category: .furniture, value: 1500),
    .init(name: "Fridge", category: .appliances, value: 2000), .init(name: "Washer", category: .appliances, value: 900), .init(name: "Dryer", category: .appliances, value: 800),
    .init(name: "Bike", category: .sports, value: 900), .init(name: "Watch", category: .jewelry, value: 800), .init(name: "Ring", category: .jewelry, value: 2500),
    .init(name: "Guitar", category: .other, value: 700), .init(name: "Wardrobe of clothes", category: .clothing, value: 3000), .init(name: "Pots, pans and knives", category: .kitchen, value: 600),
]

enum Day {
    static let cal: Calendar = { var c = Calendar(identifier: .iso8601); c.timeZone = .current; return c }()
    static let f: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.calendar = cal; f.timeZone = .current; return f }()
    static func key(_ d: Date) -> String { f.string(from: d) }
    static func date(_ k: String) -> Date? { f.date(from: k) }
    static var today: String { key(.now) }
    static func years(since k: String) -> Double {
        guard let d = date(k) else { return 0 }
        return max(0, Date.now.timeIntervalSince(d) / (365.25 * 86400))
    }
    static func pretty(_ k: String) -> String {
        guard let d = date(k) else { return "" }
        return d.formatted(.dateTime.month(.abbreviated).year())
    }
}

@Observable
final class Store {
    var home = Home()
    var rooms: [Room] = []
    var items: [Item] = []
    var search = ""
    private var saveTask: Task<Void, Never>?
    private let url = URL.documentsDirectory.appending(path: "rooms.json")
    struct Disk: Codable { var home: Home; var rooms: [Room]; var items: [Item] }

    init(demo: Bool) {
        if demo { Demo.fill(self); return }
        if let d = try? Data(contentsOf: url), let disk = try? JSONDecoder().decode(Disk.self, from: d) { home = disk.home; rooms = disk.rooms; items = disk.items }
        if rooms.isEmpty { rooms = [Room(name: "Living room", icon: "sofa.fill"), Room(name: "Kitchen", icon: "fork.knife"), Room(name: "Bedroom", icon: "bed.double.fill")] }
    }
    func save() {
        saveTask?.cancel(); let disk = Disk(home: home, rooms: rooms, items: items); let u = url
        saveTask = Task.detached(priority: .utility) {
            try? await Task.sleep(for: .milliseconds(200)); if Task.isCancelled { return }
            if let d = try? JSONEncoder().encode(disk) { try? d.write(to: u, options: .atomic) }
        }
    }

    // MARK: Lookups
    func room(_ id: UUID) -> Room? { rooms.first { $0.id == id } }
    func items(in room: Room) -> [Item] { items.filter { $0.roomID == room.id }.sorted { $0.total > $1.total } }
    func roomTotal(_ room: Room) -> Double { items(in: room).reduce(0) { $0 + $1.total } }
    var total: Double { items.reduce(0) { $0 + $1.total } }
    var filtered: [Item] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return [] }
        return items.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) || $0.serial.lowercased().contains(q) }.sorted { $0.total > $1.total }
    }
    func categoryTotal(_ c: Category) -> Double { items.filter { $0.category == c }.reduce(0) { $0 + $1.total } }
    var categoriesInUse: [Category] { Category.allCases.filter { c in items.contains { $0.category == c } }.sorted { categoryTotal($0) > categoryTotal($1) } }

    // MARK: Coverage
    struct CapCheck: Identifiable { let category: Category; let total: Double; let cap: Double; var over: Bool { total > cap }; var id: String { category.rawValue } }
    var capChecks: [CapCheck] {
        Category.allCases.compactMap { c in
            guard let cap = home.cap(c) else { return nil }
            let t = categoryTotal(c)
            return t > 0 || c.capped ? CapCheck(category: c, total: t, cap: cap) : nil
        }
    }
    var overCaps: [CapCheck] { capChecks.filter { $0.over } }
    var coverFraction: Double { home.cover > 0 ? total / home.cover : 0 }

    // MARK: Depreciation
    func today(_ i: Item) -> Double {
        let age = Day.years(since: i.bought)
        let f = max(0.1, 1 - age / i.category.life)
        return i.total * f
    }
    var totalToday: Double { items.reduce(0) { $0 + today($1) } }

    // MARK: High value
    var highValue: [Item] { items.filter { $0.total >= 1000 || $0.category.capped }.sorted { $0.total > $1.total } }
    func gaps(_ i: Item) -> [String] {
        var g: [String] = []
        if i.serial.isEmpty && (i.category == .electronics || i.category == .appliances || i.category == .sports || i.category == .tools) { g.append("no serial") }
        if !i.hasPhoto { g.append("no photo") }
        if i.receipt.isEmpty { g.append("no proof") }
        return g
    }

    // MARK: Mutations
    func upsert(_ i: Item) {
        if let k = items.firstIndex(where: { $0.id == i.id }) { items[k] = i } else { items.append(i) }
        save()
    }
    func delete(_ i: Item) { items.removeAll { $0.id == i.id }; PhotoFiles.delete(i.id); save() }
    func addRoom(_ name: String, icon: String) { rooms.append(Room(name: name, icon: icon)); save() }
    func deleteRoom(_ r: Room) { items.filter { $0.roomID == r.id }.forEach { PhotoFiles.delete($0.id) }; items.removeAll { $0.roomID == r.id }; rooms.removeAll { $0.id == r.id }; save() }

    // MARK: Export
    func csv() -> String {
        var s = "Room,Item,Category,Brand or model,Serial,Qty,Bought,Paid,Replacement value,Total,Value today,Condition,Proof,Notes\n"
        let q: (String) -> String = { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        for r in rooms { for i in items(in: r) {
            s += [q(r.name), q(i.name), q(i.category.label), q(i.brand), q(i.serial), "\(i.qty)", i.bought, String(format: "%.2f", i.price), String(format: "%.2f", i.value), String(format: "%.2f", i.total), String(format: "%.2f", today(i)), i.condition.rawValue, q(i.receipt), q(i.notes)].joined(separator: ",") + "\n"
        } }
        return s
    }
}

// MARK: Money

func money(_ v: Double, _ sym: String = "$", cents: Bool = false) -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = cents ? 2 : 0; f.minimumFractionDigits = cents ? 2 : 0
    return sym + (f.string(from: NSNumber(value: v)) ?? "0")
}

// MARK: Photos on disk

enum PhotoFiles {
    static let dir: URL = {
        let d = URL.documentsDirectory.appending(path: "photos"); try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true); return d
    }()
    static let cache = NSCache<NSString, UIImage>()
    static func url(_ id: UUID) -> URL { dir.appending(path: id.uuidString + ".jpg") }
    static func save(_ img: UIImage, _ id: UUID) {
        let m: CGFloat = 1200
        let s = min(1, m / max(img.size.width, img.size.height))
        let size = CGSize(width: img.size.width * s, height: img.size.height * s)
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1
        let out = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in img.draw(in: CGRect(origin: .zero, size: size)) }
        if let d = out.jpegData(compressionQuality: 0.82) { try? d.write(to: url(id), options: .atomic) }
        cache.setObject(out, forKey: id.uuidString as NSString)
    }
    static func load(_ id: UUID) -> UIImage? {
        if let c = cache.object(forKey: id.uuidString as NSString) { return c }
        guard let d = try? Data(contentsOf: url(id)), let img = UIImage(data: d) else { return nil }
        cache.setObject(img, forKey: id.uuidString as NSString); return img
    }
    static func delete(_ id: UUID) { try? FileManager.default.removeItem(at: url(id)); cache.removeObject(forKey: id.uuidString as NSString) }
    static var bytes: Int {
        let fs = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return fs.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }
}
