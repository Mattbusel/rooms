import Foundation
import UIKit

enum Demo {
    static func fill(_ s: Store) {
        s.home = Home(name: "14 Alder Lane", address: "14 Alder Lane, Portland OR 97214", insurer: "Lemonade", policy: "HO3-4471-2290", claimsPhone: "1-844-733-8666", cover: 120_000, deductible: 1_000)
        let names: [(String, String)] = [("Living room", "sofa.fill"), ("Kitchen", "fork.knife"), ("Dining room", "table.furniture.fill"), ("Primary bedroom", "bed.double.fill"), ("Guest bedroom", "bed.double"), ("Home office", "desktopcomputer"), ("Bathroom", "shower.fill"), ("Garage", "car.fill"), ("Basement", "stairs")]
        s.rooms = names.map { Room(name: $0.0, icon: $0.1) }
        func r(_ n: String) -> UUID { s.rooms.first { $0.name == n }!.id }
        // room, name, category, brand, serial, qty, bought, paid, value, condition, receipt
        let rows: [(String, String, Category, String, String, Int, String, Double, Double, Condition, String)] = [
            ("Living room", "Sectional sofa", .furniture, "West Elm Harmony 3-piece", "", 1, "2022-09-10", 3200, 3400, .good, "Email receipt"),
            ("Living room", "65-inch OLED TV", .electronics, "LG C4 65", "405MXNZ5A231", 1, "2024-11-28", 1500, 1600, .excellent, "Best Buy receipt, Drive"),
            ("Living room", "Soundbar and sub", .electronics, "Sonos Arc, Sub Mini", "B8-2K4-91J", 1, "2024-11-28", 1300, 1300, .excellent, "Best Buy receipt"),
            ("Living room", "Books, about 300", .books, "", "", 1, "", 0, 4500, .good, ""),
            ("Living room", "Rug 8x10", .furniture, "Ruggable wool blend", "", 1, "2023-03-02", 640, 700, .good, "Order email"),
            ("Living room", "Framed print, signed", .art, "Ansel Adams reproduction", "", 1, "2019-06-15", 900, 1100, .excellent, "Gallery invoice"),
            ("Living room", "Coffee table", .furniture, "Article Seno walnut", "", 1, "2022-09-10", 550, 600, .good, "Email receipt"),
            ("Living room", "Floor lamp", .furniture, "Muuto Leaf", "", 1, "2022-10-01", 420, 450, .good, ""),
            ("Living room", "Record player and records", .electronics, "Audio-Technica LP120X, 80 LPs", "", 1, "2021-12-20", 1200, 1900, .good, ""),
            ("Living room", "Game console", .electronics, "PlayStation 5", "GA55D2J0R12", 1, "2023-12-25", 500, 500, .good, "Amazon"),
            ("Kitchen", "Refrigerator", .appliances, "Bosch 800 Series B36CL80ENS", "FD9908-00112", 1, "2022-08-14", 3400, 3600, .good, "Home Depot receipt"),
            ("Kitchen", "Range", .appliances, "GE Cafe dual fuel 30", "VH123456Q", 1, "2022-08-14", 3100, 3300, .good, "Home Depot receipt"),
            ("Kitchen", "Dishwasher", .appliances, "Bosch 500 Series", "FD9910-42881", 1, "2022-08-14", 1000, 1100, .good, "Home Depot receipt"),
            ("Kitchen", "Stand mixer", .kitchen, "KitchenAid Artisan", "", 1, "2020-11-27", 380, 450, .good, ""),
            ("Kitchen", "Pots, pans and knives", .kitchen, "All-Clad set, Wusthof knives", "", 1, "", 0, 1400, .good, ""),
            ("Kitchen", "Espresso machine", .kitchen, "Breville Barista Express", "BES870-2211", 1, "2023-05-06", 700, 750, .excellent, "Williams Sonoma"),
            ("Kitchen", "Dishes and glassware", .kitchen, "", "", 1, "", 0, 900, .good, ""),
            ("Kitchen", "Small appliances", .kitchen, "Toaster, blender, air fryer, kettle", "", 1, "", 0, 650, .good, ""),
            ("Kitchen", "Microwave", .appliances, "Panasonic 1200W", "", 1, "2021-02-11", 220, 240, .good, ""),
            ("Dining room", "Dining table and 6 chairs", .furniture, "Crate & Barrel Basque", "", 1, "2020-01-18", 2600, 3200, .good, "Crate & Barrel"),
            ("Dining room", "Sideboard", .furniture, "Vintage teak", "", 1, "2018-07-07", 900, 1400, .good, ""),
            ("Dining room", "Wine, about 40 bottles", .other, "", "", 1, "", 0, 1200, .good, ""),
            ("Primary bedroom", "King bed frame and mattress", .furniture, "Thuma bed, Tempur-Pedic ProAdapt", "", 1, "2023-02-19", 3800, 4000, .excellent, "Order emails"),
            ("Primary bedroom", "Engagement ring", .jewelry, "1.1 ct diamond, platinum", "GIA 6204889", 1, "2019-09-21", 5400, 6200, .excellent, "Jeweler appraisal 2024"),
            ("Primary bedroom", "Watch", .jewelry, "Tudor Black Bay 41", "B8T4K2F1", 1, "2022-06-04", 3600, 4100, .excellent, "Boutique receipt"),
            ("Primary bedroom", "Wardrobe of clothes and shoes", .clothing, "Two wardrobes", "", 1, "", 0, 7500, .good, ""),
            ("Primary bedroom", "Dresser and nightstands", .furniture, "Room & Board Hudson", "", 1, "2023-02-19", 2100, 2200, .excellent, "Order email"),
            ("Primary bedroom", "Gold chain and earrings", .jewelry, "14k, mixed", "", 1, "", 0, 1450, .good, ""),
            ("Primary bedroom", "Cash", .cash, "Envelope in the safe", "", 1, "", 0, 600, .new, ""),
            ("Guest bedroom", "Queen bed and mattress", .furniture, "IKEA Malm, Casper", "", 1, "2021-04-10", 1100, 1200, .good, ""),
            ("Guest bedroom", "Sewing machine", .other, "Janome HD3000", "", 1, "2020-10-02", 450, 500, .good, ""),
            ("Guest bedroom", "Guest linens and towels", .other, "", "", 1, "", 0, 400, .good, ""),
            ("Home office", "Laptop", .electronics, "MacBook Pro 14 M4", "C02XK1ABMD6T", 1, "2025-01-15", 2400, 2400, .excellent, "Apple receipt"),
            ("Home office", "Monitor", .electronics, "Apple Studio Display", "H4KF0921PW", 1, "2024-03-20", 1600, 1600, .excellent, "Apple receipt"),
            ("Home office", "Camera and two lenses", .electronics, "Fujifilm X-T5, 16-55, 35mm", "3AQ11245", 1, "2024-04-02", 3400, 3600, .excellent, "B&H invoice"),
            ("Home office", "Standing desk and chair", .furniture, "Uplift V2, Herman Miller Aeron", "", 1, "2021-09-12", 2100, 2500, .good, "Order emails"),
            ("Home office", "Printer", .electronics, "Brother laser", "U64321M1N", 1, "2022-01-30", 260, 280, .good, ""),
            ("Home office", "Tablet", .electronics, "iPad Air, Pencil", "DMPGQ3N1KJ", 1, "2024-06-11", 850, 850, .excellent, "Apple receipt"),
            ("Home office", "Guitar", .other, "Taylor 214ce", "2201234567", 1, "2019-12-24", 1000, 1300, .good, ""),
            ("Bathroom", "Hair tools and electric razor", .other, "Dyson Airwrap, Braun 9", "", 1, "2023-11-24", 700, 750, .good, ""),
            ("Bathroom", "Towels and toiletries", .other, "", "", 1, "", 0, 300, .good, ""),
            ("Garage", "Road bike", .sports, "Specialized Tarmac SL7", "WSBC612345", 1, "2022-05-14", 4200, 4600, .good, "Bike shop invoice"),
            ("Garage", "Skis and boots", .sports, "Volkl, Salomon", "", 2, "2022-11-20", 1100, 1200, .good, ""),
            ("Garage", "Power tools", .tools, "DeWalt 20V set, mitre saw", "", 1, "2021-08-08", 900, 1100, .good, ""),
            ("Garage", "Hand tools and toolbox", .tools, "", "", 1, "", 0, 600, .good, ""),
            ("Garage", "Lawn mower", .tools, "Ego 56V", "EG2101-44821", 1, "2023-04-15", 550, 600, .good, "Lowe's"),
            ("Garage", "Camping gear", .sports, "REI tent, two bags, pads, stove", "", 1, "", 0, 1300, .good, ""),
            ("Basement", "Washer", .appliances, "LG WM4000", "011KWZE2R331", 1, "2022-08-14", 950, 1000, .good, "Home Depot receipt"),
            ("Basement", "Dryer", .appliances, "LG DLEX4000", "011KWZE2R550", 1, "2022-08-14", 900, 950, .good, "Home Depot receipt"),
            ("Basement", "Treadmill", .sports, "NordicTrack 1750", "NT1750-88213", 1, "2021-01-09", 1900, 2100, .fair, ""),
            ("Basement", "Chest freezer", .appliances, "Frigidaire 15 cu ft", "", 1, "2020-05-05", 500, 550, .good, ""),
            ("Basement", "Holiday decorations", .other, "", "", 1, "", 0, 500, .good, ""),
            ("Basement", "Board games and puzzles", .books, "About 40", "", 1, "", 0, 900, .good, ""),
            ("Basement", "Spare furniture", .furniture, "Futon, two bookcases", "", 1, "", 0, 600, .fair, ""),
        ]
        var seed: UInt64 = 11
        func rnd() -> UInt64 { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return seed >> 33 }
        s.items = rows.map { row in
            var it = Item(name: row.1, roomID: r(row.0), category: row.2, brand: row.3, serial: row.4, qty: row.5, bought: row.6, price: row.7, value: row.8, condition: row.9, receipt: row.10)
            // Most items have a photo; a few do not so the gaps view has something to say.
            it.hasPhoto = rnd() % 10 < 7 || !row.10.isEmpty
            if it.hasPhoto { PhotoFiles.save(placeholder(it, tint: Int(rnd() % 6)), it.id) }
            return it
        }
    }

    /// A soft studio-style card with the item's initial, so demo thumbnails look intentional.
    static func placeholder(_ it: Item, tint: Int) -> UIImage {
        let size = CGSize(width: 720, height: 720)
        let palette: [(UIColor, UIColor)] = [(UIColor(red: 0.86, green: 0.80, blue: 0.70, alpha: 1), UIColor(red: 0.72, green: 0.62, blue: 0.48, alpha: 1)),
                                            (UIColor(red: 0.74, green: 0.80, blue: 0.78, alpha: 1), UIColor(red: 0.50, green: 0.60, blue: 0.58, alpha: 1)),
                                            (UIColor(red: 0.80, green: 0.76, blue: 0.84, alpha: 1), UIColor(red: 0.58, green: 0.52, blue: 0.66, alpha: 1)),
                                            (UIColor(red: 0.88, green: 0.78, blue: 0.72, alpha: 1), UIColor(red: 0.72, green: 0.56, blue: 0.48, alpha: 1)),
                                            (UIColor(red: 0.76, green: 0.82, blue: 0.70, alpha: 1), UIColor(red: 0.52, green: 0.62, blue: 0.44, alpha: 1)),
                                            (UIColor(red: 0.82, green: 0.82, blue: 0.86, alpha: 1), UIColor(red: 0.58, green: 0.60, blue: 0.68, alpha: 1))]
        let (a, b) = palette[tint % palette.count]
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1
        return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let cg = ctx.cgContext
            let colors = [a.cgColor, b.cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(g, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
            }
            // A soft "object" shape: a rounded slab with a shadow, like a product on a backdrop.
            cg.setShadow(offset: CGSize(width: 0, height: 30), blur: 60, color: UIColor.black.withAlphaComponent(0.25).cgColor)
            let slab = UIBezierPath(roundedRect: CGRect(x: 160, y: 210, width: 400, height: 340), cornerRadius: 32)
            UIColor.white.withAlphaComponent(0.22).setFill(); slab.fill()
            cg.setShadow(offset: .zero, blur: 0, color: nil)
            let initial = String(it.name.prefix(1)).uppercased()
            let para = NSMutableParagraphStyle(); para.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 210, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.85), .paragraphStyle: para]
            (initial as NSString).draw(in: CGRect(x: 0, y: 240, width: size.width, height: 260), withAttributes: attrs)
        }
    }
}
