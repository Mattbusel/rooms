import SwiftUI

// MARK: Inventory (home)

struct InventoryView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    var body: some View {
        @Bindable var store = store
        let sym = store.home.symbol
        Page {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow("Everything you own")
                    Text(money(store.total, sym)).font(.serif(40, .bold)).foregroundStyle(Paper.ink).contentTransition(.numericText())
                    Text("\(store.items.count) items in \(store.rooms.count) rooms" + (store.home.cover > 0 ? " · \(Int((store.coverFraction * 100).rounded()))% of \(money(store.home.cover, sym)) cover" : "")).font(.ui(13)).foregroundStyle(Paper.ink2)
                }
                Spacer()
                Button { router.editingHome = true } label: {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(store.home.name.isEmpty ? "Your home" : store.home.name).font(.serif(15, .semibold)).foregroundStyle(Paper.ink).lineLimit(1)
                        Text(store.home.insurer.isEmpty ? "Add your policy" : store.home.insurer).font(.ui(11)).foregroundStyle(Paper.accent)
                    }
                }.buttonStyle(.plain)
            }.padding(.top, 14)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .bold)).foregroundStyle(Paper.dim)
                TextField("Search names, brands, serial numbers", text: $store.search).font(.ui(14)).foregroundStyle(Paper.ink).autocorrectionDisabled()
                if !store.search.isEmpty { Button { store.search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Paper.dim) }.buttonStyle(.plain) }
            }.padding(.horizontal, 14).padding(.vertical, 11).box(padding: 0, radius: 12)

            if !store.search.isEmpty {
                VStack(spacing: 0) {
                    ForEach(store.filtered) { it in ItemRow(item: it) }
                    if store.filtered.isEmpty { Text("Nothing matches.").font(.ui(13)).foregroundStyle(Paper.dim).padding(16) }
                }.box(padding: 6)
            } else {
                HStack { Eyebrow("Rooms"); Spacer(); RoomAdder() }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(store.rooms) { room in
                        NavigationLink(value: Route.room(room.id)) { RoomCard(room: room) }.buttonStyle(.plain)
                    }
                }
                if !store.overCaps.isEmpty {
                    Button { withAnimation { router.tab = .coverage } } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Paper.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(store.overCaps.count) categor\(store.overCaps.count == 1 ? "y is" : "ies are") over your policy cap").font(.ui(13, .bold)).foregroundStyle(Paper.ink)
                                Text(store.overCaps.map { $0.category.label }.joined(separator: ", ") + ". See Coverage.").font(.ui(12)).foregroundStyle(Paper.ink2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Paper.dim)
                        }.padding(14).background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Paper.redSoft))
                    }.buttonStyle(.plain)
                }
                if store.items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start with the room you are standing in.").font(.serif(18, .semibold)).foregroundStyle(Paper.ink)
                        Text("Tap a room, then the terracotta plus. Photo, name, what it would cost to replace. Thirty seconds an item, and one afternoon covers a house.").font(.ui(13)).foregroundStyle(Paper.ink2)
                    }.box()
                }
            }
        }
    }
}

struct RoomCard: View {
    @Environment(Store.self) private var store
    let room: Room
    var body: some View {
        let its = store.items(in: room)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: room.icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(Paper.accent)
                Spacer()
                Text("\(its.count)").font(.num(12, .bold)).foregroundStyle(Paper.dim)
            }
            Spacer(minLength: 0)
            HStack(spacing: -8) {
                ForEach(its.prefix(4)) { it in Thumb(item: it, size: 30, radius: 8).overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Paper.card, lineWidth: 2)) }
                if its.isEmpty { RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Paper.line2, style: StrokeStyle(lineWidth: 1, dash: [3, 3])).frame(width: 30, height: 30) }
            }
            Text(room.name).font(.serif(16, .semibold)).foregroundStyle(Paper.ink).lineLimit(1)
            Text(its.isEmpty ? "Empty" : money(store.roomTotal(room), store.home.symbol)).font(.num(14)).foregroundStyle(its.isEmpty ? Paper.dim : Paper.ink2)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading).box(padding: 14)
    }
}

struct RoomAdder: View {
    @Environment(Store.self) private var store
    @State private var show = false
    var body: some View {
        Button { show = true } label: { HStack(spacing: 4) { Image(systemName: "plus").font(.system(size: 11, weight: .bold)); Text("Room").font(.label(11)) }.foregroundStyle(Paper.accent) }.buttonStyle(.plain)
            .sheet(isPresented: $show) { RoomEditor().presentationBackground(Paper.bg).presentationDetents([.medium]) }
    }
}

// MARK: Room

struct RoomView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    let room: Room
    @State private var confirm = false
    var body: some View {
        let its = store.items(in: room)
        Page {
            HStack {
                Button { dismiss() } label: { HStack(spacing: 4) { Image(systemName: "chevron.left").font(.system(size: 13, weight: .bold)); Text("Rooms").font(.ui(13, .bold)) }.foregroundStyle(Paper.ink2) }.buttonStyle(.plain)
                Spacer()
                Button { confirm = true } label: { Image(systemName: "trash").font(.system(size: 13, weight: .bold)).foregroundStyle(Paper.dim) }.buttonStyle(.plain)
            }.padding(.top, 8)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) { Image(systemName: room.icon).foregroundStyle(Paper.accent); Eyebrow("Room") }
                    Text(room.name).font(.serif(34, .bold)).foregroundStyle(Paper.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(money(store.roomTotal(room), store.home.symbol)).font(.num(22, .bold)).foregroundStyle(Paper.ink)
                    Text("\(its.count) item\(its.count == 1 ? "" : "s")").font(.ui(12)).foregroundStyle(Paper.dim)
                }
            }
            if its.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nothing here yet.").font(.serif(18, .semibold)).foregroundStyle(Paper.ink)
                    Text("Stand in the doorway and go clockwise. Big things first: furniture, screens, appliances. Then open the drawers.").font(.ui(13)).foregroundStyle(Paper.ink2)
                }.box()
            } else {
                VStack(spacing: 0) { ForEach(its) { it in ItemRow(item: it) } }.box(padding: 6)
            }
            Text("The plus button adds to this room.").font(.ui(12)).foregroundStyle(Paper.dim)
        }
        .navigationBarBackButtonHidden(true).toolbar(.hidden, for: .navigationBar)
        .onAppear { router.newRoomID = room.id }
        .onDisappear { if router.path.isEmpty { router.newRoomID = nil } }
        .alert("Delete \(room.name) and its \(its.count) items?", isPresented: $confirm) {
            Button("Delete", role: .destructive) { store.deleteRoom(room); dismiss() }
            Button("Keep", role: .cancel) {}
        }
    }
}

struct ItemRow: View {
    @Environment(Store.self) private var store
    let item: Item
    var body: some View {
        NavigationLink(value: Route.item(item.id)) {
            HStack(spacing: 12) {
                Thumb(item: item, size: 50)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).font(.ui(15, .semibold)).foregroundStyle(Paper.ink).lineLimit(1)
                    Text([item.brand, item.condition.rawValue].filter { !$0.isEmpty }.joined(separator: " · ")).font(.ui(12)).foregroundStyle(Paper.dim).lineLimit(1)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(money(item.total, store.home.symbol)).font(.num(15, .bold)).foregroundStyle(Paper.ink)
                    if item.qty > 1 { Text("×\(item.qty)").font(.ui(11)).foregroundStyle(Paper.dim) }
                }
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).foregroundStyle(Paper.line2)
            }.padding(.horizontal, 8).padding(.vertical, 8).rule()
        }.buttonStyle(.plain)
    }
}

// MARK: Item

struct ItemView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var confirm = false
    var body: some View {
        if let it = store.items.first(where: { $0.id == id }) {
            let sym = store.home.symbol
            Page {
                HStack {
                    Button { dismiss() } label: { HStack(spacing: 4) { Image(systemName: "chevron.left").font(.system(size: 13, weight: .bold)); Text(store.room(it.roomID)?.name ?? "Back").font(.ui(13, .bold)) }.foregroundStyle(Paper.ink2) }.buttonStyle(.plain)
                    Spacer()
                    LineButton(title: "Edit", icon: "pencil") { router.editing = it }
                }.padding(.top, 8)
                ZStack(alignment: .bottomLeading) {
                    Hero(item: it)
                    LinearGradient(colors: [.clear, Paper.ink.opacity(0.75)], startPoint: .center, endPoint: .bottom).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) { Tag(text: it.category.label, fg: Paper.card, bg: Color.white.opacity(0.22)); if it.category.capped { Tag(text: "Capped category", fg: Paper.card, bg: Paper.accent) } }
                        Text(it.name).font(.serif(28, .bold)).foregroundStyle(Paper.card)
                        Text(money(it.total, sym) + (it.qty > 1 ? "  ·  \(it.qty) × " + money(it.value, sym) : "") + "  ·  to replace today").font(.num(14)).foregroundStyle(Paper.card.opacity(0.85))
                    }.padding(18)
                }
                let gaps = store.gaps(it)
                if !gaps.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.ellipsis").foregroundStyle(Paper.accent)
                        Text("For a claim you would want: " + gaps.joined(separator: ", ") + ".").font(.ui(12.5)).foregroundStyle(Paper.ink2)
                    }.padding(12).background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Paper.accentSoft))
                }
                VStack(spacing: 0) {
                    LedgerRow(label: "Brand or model", value: it.brand.isEmpty ? "not recorded" : it.brand)
                    LedgerRow(label: "Serial number", value: it.serial.isEmpty ? "not recorded" : it.serial)
                    LedgerRow(label: "Room", value: store.room(it.roomID)?.name ?? "")
                    LedgerRow(label: "Condition", value: it.condition.rawValue)
                    LedgerRow(label: "Bought", value: it.bought.isEmpty ? "not recorded" : Day.pretty(it.bought))
                    LedgerRow(label: "Paid", value: it.price > 0 ? money(it.price, sym) : "not recorded")
                    LedgerRow(label: "Replacement value", value: money(it.value, sym) + (it.qty > 1 ? " each" : ""), strong: true)
                    LedgerRow(label: "Value today (depreciated)", value: money(store.today(it), sym), color: Paper.ink2)
                    LedgerRow(label: "Proof of purchase", value: it.receipt.isEmpty ? "not recorded" : it.receipt)
                }.box(padding: 14)
                if !it.notes.isEmpty { VStack(alignment: .leading, spacing: 6) { Eyebrow("Notes"); Text(it.notes).font(.ui(14)).foregroundStyle(Paper.ink) }.box() }
                Button { confirm = true } label: { Text("Remove from inventory").font(.ui(13, .bold)).foregroundStyle(Paper.red).frame(maxWidth: .infinity).padding(12) }.buttonStyle(.plain)
            }
            .navigationBarBackButtonHidden(true).toolbar(.hidden, for: .navigationBar)
            .alert("Remove \(it.name)?", isPresented: $confirm) {
                Button("Remove", role: .destructive) { store.delete(it); dismiss() }
                Button("Keep", role: .cancel) {}
            }
        } else { EmptyView() }
    }
}

// MARK: Coverage

struct CoverageView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    var body: some View {
        let sym = store.home.symbol, h = store.home
        Page {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("Coverage check")
                Text("Would the policy pay?").font(.serif(32, .bold)).foregroundStyle(Paper.ink)
                Text("Your total against the contents limit, and each capped category against its cap.").font(.ui(13)).foregroundStyle(Paper.ink2)
            }.padding(.top, 14)
            if h.cover == 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Add your policy first.").font(.serif(18, .semibold)).foregroundStyle(Paper.ink)
                    Text("Contents cover and the per-category caps are on the declarations page of your policy, usually page one.").font(.ui(13)).foregroundStyle(Paper.ink2)
                    InkButton(title: "Add policy details", icon: "doc.text") { router.editingHome = true }
                }.box()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(money(store.total, sym)).font(.serif(30, .bold)).foregroundStyle(Paper.ink)
                        Text("of " + money(h.cover, sym) + " contents cover").font(.ui(13)).foregroundStyle(Paper.ink2)
                    }
                    Meter(fraction: store.coverFraction, color: store.coverFraction > 1 ? Paper.red : store.coverFraction > 0.85 ? Paper.accent : Paper.ok)
                    Text(store.coverFraction > 1 ? "You own more than the policy covers. Ask your insurer to raise the contents limit." : store.coverFraction > 0.85 ? "Close to the limit. Worth a call before the next renewal." : "Inside the limit, with \(money(h.cover - store.total, sym)) of headroom.").font(.ui(12.5)).foregroundStyle(store.coverFraction > 1 ? Paper.red : Paper.ink2)
                    if h.deductible > 0 { Text("Deductible " + money(h.deductible, sym) + ": you pay that first on any claim.").font(.ui(12)).foregroundStyle(Paper.dim) }
                }.box()
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow("Capped categories")
                    Text("Most policies cap jewelry, cash, firearms and art at a small amount unless you add a rider. Over the cap, the rest is not paid.").font(.ui(12.5)).foregroundStyle(Paper.ink2)
                    ForEach(store.capChecks) { c in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: c.category.icon).font(.system(size: 13)).foregroundStyle(c.over ? Paper.red : Paper.ink2).frame(width: 20)
                                Text(c.category.label).font(.ui(14, .semibold)).foregroundStyle(Paper.ink)
                                Spacer()
                                Text(money(c.total, sym)).font(.num(14, .bold)).foregroundStyle(c.over ? Paper.red : Paper.ink)
                                Text("/ " + money(c.cap, sym)).font(.num(12)).foregroundStyle(Paper.dim)
                            }
                            Meter(fraction: c.cap > 0 ? c.total / c.cap : 0, color: c.over ? Paper.red : Paper.ok)
                            if c.over { Text("Over by " + money(c.total - c.cap, sym) + ". Schedule the big items on a rider, or accept the cap.").font(.ui(12)).foregroundStyle(Paper.red) }
                        }.padding(.vertical, 6)
                    }
                }.box()
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow("By category")
                    ForEach(store.categoriesInUse) { c in
                        HStack {
                            Text(c.label).font(.ui(13)).foregroundStyle(Paper.ink2)
                            Spacer()
                            Text(money(store.categoryTotal(c), sym)).font(.num(13, .semibold)).foregroundStyle(Paper.ink)
                            Text(String(format: "%.0f%%", store.total > 0 ? store.categoryTotal(c) / store.total * 100 : 0)).font(.num(11)).foregroundStyle(Paper.dim).frame(width: 36, alignment: .trailing)
                        }.padding(.vertical, 5).rule()
                    }
                }.box(padding: 14)
                LineButton(title: "Edit policy", icon: "doc.text") { router.editingHome = true }
            }
        }
    }
}

struct Gap: Identifiable { let item: Item; let drop: Double; var id: UUID { item.id } }

// MARK: Value today

struct ValueView: View {
    @Environment(Store.self) private var store
    var body: some View {
        let sym = store.home.symbol
        let gaps = Array(store.items.map { Gap(item: $0, drop: $0.total - store.today($0)) }.filter { $0.drop > 0 }.sorted { $0.drop > $1.drop }.prefix(8))
        Page {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("Value today")
                Text("Replacement cost vs cash value.").font(.serif(32, .bold)).foregroundStyle(Paper.ink)
                Text("A replacement-cost policy pays what a new one costs. An actual-cash-value policy pays what yours is worth now, after wear. Know which you have.").font(.ui(13)).foregroundStyle(Paper.ink2)
            }.padding(.top, 14)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) { Eyebrow("To replace"); Text(money(store.total, sym)).font(.serif(24, .bold)).foregroundStyle(Paper.ink) }.frame(maxWidth: .infinity, alignment: .leading).box(padding: 14)
                VStack(alignment: .leading, spacing: 4) { Eyebrow("Worth today"); Text(money(store.totalToday, sym)).font(.serif(24, .bold)).foregroundStyle(Paper.accent) }.frame(maxWidth: .infinity, alignment: .leading).box(padding: 14)
            }
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("Biggest gaps")
                Text("Straight-line wear over each category's useful life, with a floor of 10%.").font(.ui(12)).foregroundStyle(Paper.dim)
                ForEach(gaps) { pair in
                    HStack(spacing: 10) {
                        Thumb(item: pair.item, size: 34, radius: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pair.item.name).font(.ui(13, .semibold)).foregroundStyle(Paper.ink).lineLimit(1)
                            Text(pair.item.bought.isEmpty ? "No purchase date" : "Bought " + Day.pretty(pair.item.bought) + " · \(Int(pair.item.category.life))-year life").font(.ui(11)).foregroundStyle(Paper.dim)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(money(store.today(pair.item), sym)).font(.num(13, .bold)).foregroundStyle(Paper.ink)
                            Text("−" + money(pair.drop, sym)).font(.num(11)).foregroundStyle(Paper.accent)
                        }
                    }.padding(.vertical, 5).rule()
                }
            }.box(padding: 14)
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("High value: what a claim will ask for")
                Text("Anything over \(money(1000, sym)) or in a capped category. Red is missing.").font(.ui(12)).foregroundStyle(Paper.dim)
                ForEach(store.highValue) { it in
                    let g = store.gaps(it)
                    HStack(spacing: 10) {
                        Thumb(item: it, size: 34, radius: 8)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(it.name).font(.ui(13, .semibold)).foregroundStyle(Paper.ink).lineLimit(1)
                            HStack(spacing: 4) {
                                if g.isEmpty { Tag(text: "Documented", fg: Paper.ok, bg: Paper.okSoft) } else { ForEach(g, id: \.self) { Tag(text: $0, fg: Paper.red, bg: Paper.redSoft) } }
                            }
                        }
                        Spacer()
                        Text(money(it.total, sym)).font(.num(13, .bold)).foregroundStyle(Paper.ink)
                    }.padding(.vertical, 5).rule()
                }
            }.box(padding: 14)
        }
    }
}

// MARK: Report

struct ReportView: View {
    @Environment(Store.self) private var store
    @State private var pdf: URL? = nil
    @State private var csv: URL? = nil
    @State private var busy = false
    var body: some View {
        let sym = store.home.symbol
        Page {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("Claim report")
                Text("The file the adjuster wants.").font(.serif(32, .bold)).foregroundStyle(Paper.ink)
                Text("Every room, every item, with photos, serials and totals. Make it now, keep a copy off the phone, and it is ready the day you need it.").font(.ui(13)).foregroundStyle(Paper.ink2)
            }.padding(.top, 14)
            ReportPreview().box(padding: 0)
            VStack(spacing: 10) {
                if let pdf {
                    ShareLink(item: pdf) { HStack(spacing: 8) { Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .bold)); Text("Share the PDF").font(.ui(15, .bold)) }.foregroundStyle(Paper.card).frame(maxWidth: .infinity).padding(.vertical, 15).background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Paper.ink)) }
                } else {
                    InkButton(title: busy ? "Making the report…" : "Make the PDF report", icon: "doc.richtext") { busy = true; Task { @MainActor in pdf = Report.pdf(store); busy = false } }
                }
                if let csv {
                    ShareLink(item: csv) { HStack(spacing: 8) { Image(systemName: "tablecells").font(.system(size: 13, weight: .bold)); Text("Share the spreadsheet (CSV)").font(.ui(13, .bold)) }.foregroundStyle(Paper.ink).frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Paper.card)).overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Paper.line2)) }
                } else {
                    Button { csv = Report.csv(store) } label: { HStack(spacing: 8) { Image(systemName: "tablecells").font(.system(size: 13, weight: .bold)); Text("Make a spreadsheet (CSV)").font(.ui(13, .bold)) }.foregroundStyle(Paper.ink).frame(maxWidth: .infinity).padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Paper.card)).overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Paper.line2)) }.buttonStyle(.plain)
                }
            }
            HStack {
                Text("\(store.items.count) items · \(store.items.filter { $0.hasPhoto }.count) with photos · " + ByteCountFormatter.string(fromByteCount: Int64(PhotoFiles.bytes), countStyle: .file) + " of photos").font(.ui(11.5)).foregroundStyle(Paper.dim)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("After a loss")
                ForEach(Array(Report.checklist.enumerated()), id: \.offset) { pair in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(pair.offset + 1)").font(.num(13, .bold)).foregroundStyle(Paper.accent).frame(width: 18, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pair.element.0).font(.ui(14, .semibold)).foregroundStyle(Paper.ink)
                            Text(pair.element.1).font(.ui(12.5)).foregroundStyle(Paper.ink2)
                        }
                    }.padding(.vertical, 6).rule()
                }
                if !store.home.claimsPhone.isEmpty { Text("Claims line: " + store.home.claimsPhone + " · Policy " + store.home.policy).font(.num(12, .semibold)).foregroundStyle(Paper.ink).padding(.top, 6) }
                Text(money(store.total, sym) + " is what you would be claiming today. Keep this list current.").font(.ui(12)).foregroundStyle(Paper.dim)
            }.box()
        }
    }
}

/// A miniature of the first PDF page, on the Report tab.
struct ReportPreview: View {
    @Environment(Store.self) private var store
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HOME INVENTORY").font(.label(9)).tracking(1.5).foregroundStyle(Paper.dim)
                    Text(store.home.name.isEmpty ? "Your home" : store.home.name).font(.serif(17, .bold)).foregroundStyle(Paper.ink)
                    Text(store.home.address).font(.ui(10)).foregroundStyle(Paper.ink2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(money(store.total, store.home.symbol)).font(.serif(17, .bold)).foregroundStyle(Paper.ink)
                    Text("\(store.items.count) items · " + Date.now.formatted(.dateTime.month(.abbreviated).day().year())).font(.ui(10)).foregroundStyle(Paper.ink2)
                }
            }.padding(14).background(Paper.bg2)
            ForEach(store.rooms.prefix(3)) { room in
                let its = store.items(in: room).prefix(2)
                HStack(spacing: 8) {
                    Text(room.name.uppercased()).font(.label(8.5)).tracking(1).foregroundStyle(Paper.accent)
                    Rectangle().fill(Paper.line).frame(height: 1)
                    Text(money(store.roomTotal(room), store.home.symbol)).font(.num(9, .bold)).foregroundStyle(Paper.ink2)
                }.padding(.horizontal, 14).padding(.top, 10)
                ForEach(its) { it in
                    HStack(spacing: 8) {
                        Thumb(item: it, size: 22, radius: 5)
                        Text(it.name).font(.ui(10, .semibold)).foregroundStyle(Paper.ink).lineLimit(1)
                        Text(it.serial).font(.num(8.5)).foregroundStyle(Paper.dim).lineLimit(1)
                        Spacer()
                        Text(money(it.total, store.home.symbol)).font(.num(10, .semibold)).foregroundStyle(Paper.ink)
                    }.padding(.horizontal, 14).padding(.vertical, 4)
                }
            }
            HStack { Spacer(); Text("… and \(max(0, store.items.count - 6)) more, room by room, with a signature line at the end.").font(.ui(9.5)).italic().foregroundStyle(Paper.dim) }.padding(12)
        }
    }
}
