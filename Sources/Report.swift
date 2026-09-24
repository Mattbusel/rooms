import SwiftUI
import UIKit

enum Report {
    static let checklist: [(String, String)] = [
        ("Make everyone safe, then call the emergency number if it is still happening.", "Fire, flooding and gas come before anything on this list."),
        ("Call the claims line and get a claim number.", "Do it the same day. The number is on your policy card and on the Coverage page here."),
        ("Photograph everything before you clean up.", "Wide shots of each room, then close-ups of damage. Video walking through is even better."),
        ("Do not throw anything away yet.", "The adjuster may want to see damaged items. Bag them and keep them somewhere dry."),
        ("Stop further damage.", "Board a window, tarp a roof, shut off water. Keep receipts; reasonable costs are usually covered."),
        ("Send this report.", "Share the PDF and the spreadsheet with the adjuster. It is the list they would otherwise ask you to write from memory."),
        ("Keep every receipt from now on.", "Hotel, meals, replacement clothes. Additional living expenses are a separate part of most policies."),
        ("Write down every call.", "Date, name, what was said. Claims take weeks and people change."),
    ]

    @MainActor
    static func pdf(_ s: Store) -> URL? {
        let url = FileManager.default.temporaryDirectory.appending(path: "Home inventory \(Day.today).pdf")
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { return nil }
        // Rows: a room header then its items; paginate at a fixed row budget.
        enum Row { case room(Room), item(Item) }
        var rows: [Row] = []
        for r in s.rooms { let its = s.items(in: r); if its.isEmpty { continue }; rows.append(.room(r)); for i in its { rows.append(.item(i)) } }
        var pages: [[Row]] = []
        var cur: [Row] = []; var used = 0
        let firstBudget = 12, budget = 17
        for row in rows {
            let cost: Int; switch row { case .room: cost = 1; case .item: cost = 1 }
            let limit = pages.isEmpty ? firstBudget : budget
            if used + cost > limit { pages.append(cur); cur = []; used = 0 }
            cur.append(row); used += cost
        }
        pages.append(cur)
        let n = pages.count + 1
        for (pi, page) in pages.enumerated() {
            let view = PDFPage(store: s, index: pi, total: n, first: pi == 0) {
                ForEach(Array(page.enumerated()), id: \.offset) { pair in
                    switch pair.element {
                    case .room(let r): PDFRoomHeader(room: r, total: s.roomTotal(r), sym: s.home.symbol)
                    case .item(let i): PDFItemRow(item: i, today: s.today(i), sym: s.home.symbol)
                    }
                }
            }
            render(view, ctx)
        }
        render(PDFPage(store: s, index: n - 1, total: n, first: false) { PDFSummary(store: s) }, ctx)
        ctx.closePDF()
        return url
    }

    @MainActor
    private static func render<V: View>(_ v: V, _ ctx: CGContext) {
        let r = ImageRenderer(content: v.frame(width: 612, height: 792).background(Color.white))
        r.render { _, draw in ctx.beginPDFPage(nil); draw(ctx); ctx.endPDFPage() }
    }

    static func csv(_ s: Store) -> URL? {
        let url = FileManager.default.temporaryDirectory.appending(path: "Home inventory \(Day.today).csv")
        do { try s.csv().write(to: url, atomically: true, encoding: .utf8); return url } catch { return nil }
    }
}

// MARK: PDF pages

struct PDFPage<Content: View>: View {
    let store: Store
    let index: Int
    let total: Int
    let first: Bool
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HOME INVENTORY").font(.system(size: 8, weight: .bold)).tracking(1.5).foregroundStyle(Paper.dim)
                    Text(store.home.name.isEmpty ? "Home inventory" : store.home.name).font(.system(size: first ? 22 : 14, weight: .bold, design: .serif)).foregroundStyle(Paper.ink)
                    if first {
                        Text(store.home.address).font(.system(size: 9.5)).foregroundStyle(Paper.ink2)
                        Text([store.home.insurer, store.home.policy.isEmpty ? "" : "Policy " + store.home.policy].filter { !$0.isEmpty }.joined(separator: " · ")).font(.system(size: 9.5)).foregroundStyle(Paper.ink2)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(money(store.total, store.home.symbol)).font(.system(size: first ? 22 : 14, weight: .bold, design: .serif)).foregroundStyle(Paper.ink)
                    Text("\(store.items.count) items in \(store.rooms.count) rooms").font(.system(size: 9.5)).foregroundStyle(Paper.ink2)
                    Text("Prepared " + Date.now.formatted(.dateTime.month(.wide).day().year())).font(.system(size: 9.5)).foregroundStyle(Paper.ink2)
                }
            }.padding(.bottom, 10)
            Rectangle().fill(Paper.ink).frame(height: 1.5)
            if first {
                HStack(spacing: 0) {
                    Text("Item").frame(width: 250, alignment: .leading)
                    Text("Serial").frame(width: 100, alignment: .leading)
                    Text("Bought").frame(width: 60, alignment: .leading)
                    Text("Replace").frame(width: 70, alignment: .trailing)
                    Text("Today").frame(width: 62, alignment: .trailing)
                }.font(.system(size: 8, weight: .bold)).foregroundStyle(Paper.dim).padding(.top, 6).padding(.leading, 36)
            }
            content
            Spacer(minLength: 0)
            HStack {
                Text("Made with Rooms. Values are the owner's estimates of replacement cost; serial numbers and receipts as recorded.").font(.system(size: 7.5)).foregroundStyle(Paper.dim)
                Spacer()
                Text("Page \(index + 1) of \(total)").font(.system(size: 8, weight: .semibold)).foregroundStyle(Paper.dim)
            }.padding(.top, 8)
        }
        .padding(EdgeInsets(top: 40, leading: 40, bottom: 34, trailing: 40))
        .frame(width: 612, height: 792, alignment: .top)
        .background(Color.white)
    }
}

struct PDFRoomHeader: View {
    let room: Room
    let total: Double
    let sym: String
    var body: some View {
        HStack(spacing: 8) {
            Text(room.name.uppercased()).font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(Paper.accent)
            Rectangle().fill(Paper.line2).frame(height: 0.6)
            Text(money(total, sym)).font(.system(size: 9.5, weight: .bold, design: .serif)).foregroundStyle(Paper.ink)
        }.padding(.top, 14).padding(.bottom, 4)
    }
}

struct PDFItemRow: View {
    let item: Item
    let today: Double
    let sym: String
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                if item.hasPhoto, let img = PhotoFiles.load(item.id) { Image(uiImage: img).resizable().scaledToFill() } else { Paper.bg2 }
            }.frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name + (item.qty > 1 ? "  ×\(item.qty)" : "")).font(.system(size: 9.5, weight: .semibold)).foregroundStyle(Paper.ink).lineLimit(1)
                Text([item.brand, item.condition.rawValue, item.receipt.isEmpty ? "" : "Proof: " + item.receipt].filter { !$0.isEmpty }.joined(separator: " · ")).font(.system(size: 7.5)).foregroundStyle(Paper.ink2).lineLimit(1)
            }.frame(width: 214, alignment: .leading)
            Text(item.serial).font(.system(size: 8, design: .monospaced)).foregroundStyle(Paper.ink2).frame(width: 100, alignment: .leading).lineLimit(1)
            Text(item.bought.isEmpty ? "" : Day.pretty(item.bought)).font(.system(size: 8)).foregroundStyle(Paper.ink2).frame(width: 60, alignment: .leading)
            Text(money(item.total, sym)).font(.system(size: 9.5, weight: .bold, design: .serif)).foregroundStyle(Paper.ink).frame(width: 70, alignment: .trailing)
            Text(money(today, sym)).font(.system(size: 8.5, design: .serif)).foregroundStyle(Paper.ink2).frame(width: 62, alignment: .trailing)
        }
        .padding(.vertical, 3)
        .overlay(alignment: .bottom) { Rectangle().fill(Paper.line).frame(height: 0.5) }
    }
}

struct PDFSummary: View {
    let store: Store
    var body: some View {
        let sym = store.home.symbol
        VStack(alignment: .leading, spacing: 14) {
            Text("Summary").font(.system(size: 14, weight: .bold, design: .serif)).foregroundStyle(Paper.ink).padding(.top, 14)
            VStack(spacing: 0) {
                ForEach(store.rooms) { r in
                    HStack { Text(r.name).font(.system(size: 9.5)); Spacer(); Text("\(store.items(in: r).count) items").font(.system(size: 8.5)).foregroundStyle(Paper.ink2).frame(width: 60, alignment: .trailing); Text(money(store.roomTotal(r), sym)).font(.system(size: 9.5, weight: .semibold, design: .serif)).frame(width: 80, alignment: .trailing) }
                        .foregroundStyle(Paper.ink).padding(.vertical, 3).overlay(alignment: .bottom) { Rectangle().fill(Paper.line).frame(height: 0.5) }
                }
                HStack { Text("Total replacement cost").font(.system(size: 10, weight: .bold)); Spacer(); Text(money(store.total, sym)).font(.system(size: 11, weight: .bold, design: .serif)) }.foregroundStyle(Paper.ink).padding(.top, 6)
                HStack { Text("Estimated value today, after wear").font(.system(size: 9.5)); Spacer(); Text(money(store.totalToday, sym)).font(.system(size: 10, design: .serif)) }.foregroundStyle(Paper.ink2).padding(.top, 2)
            }
            Text("By category").font(.system(size: 11, weight: .bold, design: .serif)).foregroundStyle(Paper.ink).padding(.top, 6)
            VStack(spacing: 0) {
                ForEach(store.categoriesInUse) { c in
                    HStack { Text(c.label).font(.system(size: 9.5)); Spacer(); if let cap = store.home.cap(c) { Text("cap " + money(cap, sym)).font(.system(size: 8.5)).foregroundStyle(store.categoryTotal(c) > cap ? Paper.red : Paper.ink2).frame(width: 90, alignment: .trailing) }; Text(money(store.categoryTotal(c), sym)).font(.system(size: 9.5, weight: .semibold, design: .serif)).frame(width: 80, alignment: .trailing) }
                        .foregroundStyle(Paper.ink).padding(.vertical, 3).overlay(alignment: .bottom) { Rectangle().fill(Paper.line).frame(height: 0.5) }
                }
            }
            Spacer(minLength: 20)
            Text("I declare that this inventory is a true record of the contents of the property named above, to the best of my knowledge, and that the values are my honest estimate of the cost to replace each item with one of like kind and quality.").font(.system(size: 9)).foregroundStyle(Paper.ink2)
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 4) { Rectangle().fill(Paper.ink).frame(height: 0.8); Text("Signed").font(.system(size: 8)).foregroundStyle(Paper.dim) }
                VStack(alignment: .leading, spacing: 4) { Rectangle().fill(Paper.ink).frame(height: 0.8); Text("Date").font(.system(size: 8)).foregroundStyle(Paper.dim) }.frame(width: 140)
            }.padding(.top, 30)
        }
    }
}
