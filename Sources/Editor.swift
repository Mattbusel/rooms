import SwiftUI
import PhotosUI
import UIKit

// MARK: Item editor

struct ItemEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var item: Item
    let isNew: Bool
    @State private var image: UIImage? = nil
    @State private var photoChanged = false
    @State private var pick: PhotosPickerItem? = nil
    @State private var camera = false
    @State private var boughtOn = false
    @State private var boughtDate = Date.now
    @State private var priceText = ""
    @State private var valueText = ""
    private var canSave: Bool { !item.name.trimmingCharacters(in: .whitespaces).isEmpty }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }.font(.ui(14, .semibold)).foregroundStyle(Paper.ink2)
                Spacer()
                Text(isNew ? "New item" : "Edit item").font(.serif(17, .bold)).foregroundStyle(Paper.ink)
                Spacer()
                Button("Save") { save() }.font(.ui(14, .bold)).foregroundStyle(canSave ? Paper.accent : Paper.dim).disabled(!canSave)
            }.padding(.horizontal, 18).padding(.vertical, 14)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Photo
                    HStack(spacing: 12) {
                        ZStack {
                            if let image { Image(uiImage: image).resizable().scaledToFill() }
                            else if item.hasPhoto, let img = PhotoFiles.load(item.id) { Image(uiImage: img).resizable().scaledToFill() }
                            else { Paper.bg2; Image(systemName: "camera").font(.system(size: 22)).foregroundStyle(Paper.dim) }
                        }.frame(width: 96, height: 96).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Paper.line2))
                        VStack(alignment: .leading, spacing: 8) {
                            Text("A photo is the strongest proof you own it.").font(.ui(12.5)).foregroundStyle(Paper.ink2)
                            HStack(spacing: 8) {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) { LineButton(title: "Camera", icon: "camera.fill") { camera = true } }
                                PhotosPicker(selection: $pick, matching: .images) {
                                    HStack(spacing: 6) { Image(systemName: "photo.on.rectangle").font(.system(size: 12, weight: .bold)); Text("Library").font(.ui(13, .bold)) }
                                        .foregroundStyle(Paper.ink).padding(.horizontal, 13).padding(.vertical, 9)
                                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Paper.card)).overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Paper.line2))
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }.box(padding: 12)

                    if isNew {
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow("Quick add")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(quickAdds, id: \.name) { q in
                                        Button { item.name = q.name; item.category = q.category; item.value = q.value; valueText = String(Int(q.value)) } label: {
                                            HStack(spacing: 5) { Text(q.name).font(.ui(12, .semibold)); Text(money(q.value, store.home.symbol)).font(.num(11)).foregroundStyle(Paper.dim) }
                                                .foregroundStyle(Paper.ink).padding(.horizontal, 11).padding(.vertical, 8).background(Capsule().fill(Paper.card)).overlay(Capsule().strokeBorder(Paper.line2))
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    Field("Name") { TextField("Sectional sofa", text: $item.name).font(.ui(16, .semibold)) }
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Room")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) { ForEach(store.rooms) { r in Chip(text: r.name, on: item.roomID == r.id) { item.roomID = r.id } } }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Category")
                        FlowChips(Category.allCases.map { ($0.label, $0.rawValue) }, selected: item.category.rawValue) { item.category = Category(rawValue: $0) ?? .other }
                    }
                    HStack(spacing: 10) {
                        Field("Replacement value, each") { HStack(spacing: 2) { Text(store.home.symbol).foregroundStyle(Paper.dim); TextField("0", text: $valueText).keyboardType(.decimalPad).onChange(of: valueText) { _, v in item.value = Double(v.replacingOccurrences(of: ",", with: "")) ?? 0 } } }
                        Field("Quantity") { Stepper("\(item.qty)", value: $item.qty, in: 1...999).font(.num(15, .bold)) }.frame(width: 140)
                    }
                    Field("Brand or model") { TextField("West Elm Harmony 3-piece", text: $item.brand) }
                    Field("Serial number") { TextField("On the back or the box", text: $item.serial).autocorrectionDisabled().textInputAutocapitalization(.characters) }
                    HStack(spacing: 10) {
                        Field("Paid") { HStack(spacing: 2) { Text(store.home.symbol).foregroundStyle(Paper.dim); TextField("0", text: $priceText).keyboardType(.decimalPad).onChange(of: priceText) { _, v in item.price = Double(v.replacingOccurrences(of: ",", with: "")) ?? 0 } } }
                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow("Bought")
                            HStack {
                                Toggle("", isOn: $boughtOn).labelsHidden().tint(Paper.accent)
                                if boughtOn { DatePicker("", selection: $boughtDate, in: ...Date.now, displayedComponents: .date).labelsHidden() } else { Text("Not sure").font(.ui(13)).foregroundStyle(Paper.dim) }
                                Spacer()
                            }.padding(.horizontal, 8).frame(height: 44).box(padding: 0, radius: 10)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Condition")
                        HStack(spacing: 6) { ForEach(Condition.allCases, id: \.self) { c in Chip(text: c.rawValue, on: item.condition == c) { item.condition = c } } }
                    }
                    Field("Proof of purchase") { TextField("Email receipt, Amazon, appraisal in the safe", text: $item.receipt) }
                    Field("Notes") { TextField("Anything an adjuster should know", text: $item.notes, axis: .vertical).lineLimit(2...5) }
                    if !isNew { Text("Item added to " + (store.room(item.roomID)?.name ?? "")).font(.ui(11)).foregroundStyle(Paper.dim) }
                }.padding(.horizontal, 18).padding(.bottom, 40)
            }
        }
        .onAppear {
            if item.value > 0 { valueText = trim(item.value) }
            if item.price > 0 { priceText = trim(item.price) }
            if let d = Day.date(item.bought) { boughtOn = true; boughtDate = d }
        }
        .onChange(of: pick) { _, p in
            guard let p else { return }
            Task { if let d = try? await p.loadTransferable(type: Data.self), let img = UIImage(data: d) { image = img; photoChanged = true } }
        }
        .fullScreenCover(isPresented: $camera) { CameraPicker { img in image = img; photoChanged = true }.ignoresSafeArea() }
    }
    private func trim(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(format: "%.2f", v) }
    private func save() {
        var it = item
        it.name = it.name.trimmingCharacters(in: .whitespaces)
        it.bought = boughtOn ? Day.key(boughtDate) : ""
        if photoChanged, let image { PhotoFiles.save(image, it.id); it.hasPhoto = true }
        store.upsert(it)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

struct Field<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content
    init(_ label: String, @ViewBuilder content: () -> Content) { self.label = label; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(label)
            content.font(.ui(15)).foregroundStyle(Paper.ink).padding(.horizontal, 12).frame(minHeight: 44).box(padding: 0, radius: 10)
        }
    }
}

struct Chip: View {
    let text: String
    let on: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(.ui(12.5, .semibold)).foregroundStyle(on ? Paper.card : Paper.ink)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(on ? Paper.ink : Paper.card)).overlay(Capsule().strokeBorder(on ? Paper.ink : Paper.line2))
        }.buttonStyle(.plain)
    }
}

/// Wrapping chips, laid out in rows by hand (no Layout protocol tricks needed for a short list).
struct FlowChips: View {
    let items: [(String, String)]
    let selected: String
    var pick: (String) -> Void
    init(_ items: [(String, String)], selected: String, pick: @escaping (String) -> Void) { self.items = items; self.selected = selected; self.pick = pick }
    var body: some View {
        let rows = stride(from: 0, to: items.count, by: 3).map { Array(items[$0..<min($0 + 3, items.count)]) }
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { row in
                HStack(spacing: 6) {
                    ForEach(row.element, id: \.1) { it in Chip(text: it.0, on: selected == it.1) { pick(it.1) } }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// MARK: Camera

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController(); p.sourceType = .camera; p.delegate = context.coordinator; return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ p: CameraPicker) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImage(img) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: Home / policy editor

struct HomeEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var h = Home()
    @State private var cover = ""
    @State private var ded = ""
    @State private var caps: [String: String] = [:]
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }.font(.ui(14, .semibold)).foregroundStyle(Paper.ink2)
                Spacer()
                Text("Home and policy").font(.serif(17, .bold)).foregroundStyle(Paper.ink)
                Spacer()
                Button("Save") {
                    var n = h
                    n.cover = Double(cover.replacingOccurrences(of: ",", with: "")) ?? 0
                    n.deductible = Double(ded.replacingOccurrences(of: ",", with: "")) ?? 0
                    for (k, v) in caps { if let d = Double(v.replacingOccurrences(of: ",", with: "")) { n.caps[k] = d } }
                    if n.symbol.isEmpty { n.symbol = "$" }
                    store.home = n; store.save(); dismiss()
                }.font(.ui(14, .bold)).foregroundStyle(Paper.accent)
            }.padding(.horizontal, 18).padding(.vertical, 14)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Field("Home name") { TextField("14 Alder Lane", text: $h.name) }
                    Field("Address") { TextField("Street, city, postcode", text: $h.address) }
                    Text("From the declarations page of your policy. The numbers here drive the Coverage check.").font(.ui(12.5)).foregroundStyle(Paper.ink2)
                    Field("Insurer") { TextField("Who you pay", text: $h.insurer) }
                    HStack(spacing: 10) {
                        Field("Policy number") { TextField("HO3-…", text: $h.policy).autocorrectionDisabled() }
                        Field("Claims phone") { TextField("1-800-…", text: $h.claimsPhone).keyboardType(.phonePad) }
                    }
                    HStack(spacing: 10) {
                        Field("Contents cover") { HStack(spacing: 2) { Text(h.symbol).foregroundStyle(Paper.dim); TextField("0", text: $cover).keyboardType(.numberPad) } }
                        Field("Deductible") { HStack(spacing: 2) { Text(h.symbol).foregroundStyle(Paper.dim); TextField("0", text: $ded).keyboardType(.numberPad) } }
                    }
                    Eyebrow("Category caps")
                    Text("Most policies limit these unless you schedule items separately. Set each to what your policy says, or 0 to ignore it.").font(.ui(12)).foregroundStyle(Paper.dim)
                    ForEach(Category.allCases.filter { $0.capped }) { c in
                        HStack {
                            Text(c.label).font(.ui(14)).foregroundStyle(Paper.ink)
                            Spacer()
                            HStack(spacing: 2) { Text(h.symbol).foregroundStyle(Paper.dim); TextField("0", text: Binding(get: { caps[c.rawValue] ?? "" }, set: { caps[c.rawValue] = $0 })).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                                .font(.num(15)).foregroundStyle(Paper.ink).padding(.horizontal, 12).frame(width: 130, height: 40).box(padding: 0, radius: 10)
                        }
                    }
                    Field("Currency symbol") { TextField("$", text: $h.symbol) }.frame(width: 120)
                }.padding(.horizontal, 18).padding(.bottom, 40)
            }
        }
        .onAppear {
            h = store.home
            if h.cover > 0 { cover = String(Int(h.cover)) }
            if h.deductible > 0 { ded = String(Int(h.deductible)) }
            for (k, v) in h.caps { caps[k] = String(Int(v)) }
        }
    }
}

// MARK: Room editor

struct RoomEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = "door.left.hand.closed"
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Cancel") { dismiss() }.font(.ui(14, .semibold)).foregroundStyle(Paper.ink2)
                Spacer()
                Text("New room").font(.serif(17, .bold)).foregroundStyle(Paper.ink)
                Spacer()
                Button("Add") { store.addRoom(name.trimmingCharacters(in: .whitespaces), icon: icon); dismiss() }.font(.ui(14, .bold)).foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Paper.dim : Paper.accent).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }.padding(.top, 14)
            Field("Name") { TextField("Guest bedroom", text: $name) }
            Eyebrow("Or pick one")
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Room.presets.filter { p in !store.rooms.contains { $0.name == p.0 } }, id: \.0) { p in
                        Button { name = p.0; icon = p.1 } label: {
                            HStack(spacing: 8) { Image(systemName: p.1).font(.system(size: 13)).foregroundStyle(Paper.accent).frame(width: 20); Text(p.0).font(.ui(13, .semibold)).foregroundStyle(Paper.ink); Spacer() }
                                .padding(10).background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(name == p.0 ? Paper.accentSoft : Paper.card)).overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(name == p.0 ? Paper.accent : Paper.line2))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }.padding(.horizontal, 18)
    }
}
