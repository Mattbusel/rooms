import SwiftUI

/// Paper ledger. Warm off-white stock, navy ink, one terracotta accent, serif numerals.
enum Paper {
    static let bg = Color(red: 0.957, green: 0.945, blue: 0.918)        // #F4F1EA
    static let bg2 = Color(red: 0.929, green: 0.910, blue: 0.867)       // #EDE8DD
    static let card = Color(red: 0.984, green: 0.976, blue: 0.957)      // #FBF9F4
    static let ink = Color(red: 0.090, green: 0.137, blue: 0.227)       // #17233A
    static let ink2 = Color(red: 0.090, green: 0.137, blue: 0.227).opacity(0.68)
    static let dim = Color(red: 0.090, green: 0.137, blue: 0.227).opacity(0.42)
    static let line = Color(red: 0.090, green: 0.137, blue: 0.227).opacity(0.12)
    static let line2 = Color(red: 0.090, green: 0.137, blue: 0.227).opacity(0.24)
    static let accent = Color(red: 0.776, green: 0.322, blue: 0.169)    // #C6522B
    static let accentSoft = Color(red: 0.776, green: 0.322, blue: 0.169).opacity(0.12)
    static let ok = Color(red: 0.184, green: 0.490, blue: 0.310)        // #2F7D4F
    static let okSoft = Color(red: 0.184, green: 0.490, blue: 0.310).opacity(0.12)
    static let red = Color(red: 0.722, green: 0.196, blue: 0.165)       // #B8322A
    static let redSoft = Color(red: 0.722, green: 0.196, blue: 0.165).opacity(0.12)
    static let navySoft = Color(red: 0.090, green: 0.137, blue: 0.227).opacity(0.06)
    /// Soft tints for procedurally drawn thumbnails.
    static let tints: [Color] = [Color(red: 0.86, green: 0.80, blue: 0.70), Color(red: 0.74, green: 0.80, blue: 0.78), Color(red: 0.80, green: 0.76, blue: 0.84), Color(red: 0.88, green: 0.78, blue: 0.72), Color(red: 0.76, green: 0.82, blue: 0.70), Color(red: 0.82, green: 0.82, blue: 0.86)]
}

extension Font {
    static func serif(_ size: CGFloat, _ w: Font.Weight = .semibold) -> Font { .system(size: size, weight: w, design: .serif) }
    static func num(_ size: CGFloat, _ w: Font.Weight = .semibold) -> Font { .system(size: size, weight: w, design: .serif).monospacedDigit() }
    static func ui(_ size: CGFloat, _ w: Font.Weight = .medium) -> Font { .system(size: size, weight: w, design: .default) }
    static func label(_ size: CGFloat = 10.5) -> Font { .system(size: size, weight: .bold, design: .default) }
}

struct PaperBackground: View {
    var body: some View {
        ZStack {
            Paper.bg
            // Faint grid, like drafting paper.
            Canvas { ctx, size in
                var p = Path()
                var x: CGFloat = 0
                while x < size.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)); x += 28 }
                var y: CGFloat = 0
                while y < size.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)); y += 28 }
                ctx.stroke(p, with: .color(Paper.ink.opacity(0.035)), lineWidth: 0.5)
            }
            LinearGradient(colors: [Paper.bg.opacity(0), Paper.bg.opacity(0.9)], startPoint: .top, endPoint: .bottom)
        }.ignoresSafeArea()
    }
}

struct Eyebrow: View {
    let text: String
    var color: Color = Paper.dim
    init(_ t: String, color: Color = Paper.dim) { text = t; self.color = color }
    var body: some View { Text(text.uppercased()).font(.label()).tracking(1.6).foregroundStyle(color) }
}

extension View {
    /// A labelled box on the ledger.
    func box(padding: CGFloat = 16, radius: CGFloat = 14) -> some View {
        self.padding(padding)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Paper.card))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Paper.line2, lineWidth: 1))
    }
    func rule() -> some View { self.overlay(alignment: .bottom) { Rectangle().fill(Paper.line).frame(height: 1) } }
}

struct Page<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) { content }.padding(.horizontal, 18).padding(.top, 6).padding(.bottom, 120)
        }
    }
}

struct InkButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = Paper.ink
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 14, weight: .bold)) }
                Text(title).font(.ui(15, .bold))
            }
            .foregroundStyle(Paper.card).frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint))
        }.buttonStyle(.plain)
    }
}

struct LineButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 12, weight: .bold)) }
                Text(title).font(.ui(13, .bold))
            }
            .foregroundStyle(Paper.ink).padding(.horizontal, 13).padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Paper.card)).overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Paper.line2))
        }.buttonStyle(.plain)
    }
}

/// A ledger row: label on the left, value on the right, hairline under.
struct LedgerRow: View {
    let label: String
    let value: String
    var strong = false
    var color: Color = Paper.ink
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.ui(13, .medium)).foregroundStyle(Paper.ink2)
            Spacer(minLength: 12)
            Text(value).font(strong ? .num(16, .bold) : .num(14, .medium)).foregroundStyle(color).multilineTextAlignment(.trailing)
        }.padding(.vertical, 8).rule()
    }
}

struct Tag: View {
    let text: String
    var fg: Color = Paper.ink2
    var bg: Color = Paper.navySoft
    var body: some View { Text(text).font(.label(10)).foregroundStyle(fg).padding(.horizontal, 7).padding(.vertical, 4).background(Capsule().fill(bg)) }
}

/// A thin bar with a marker, used for cover and caps.
struct Meter: View {
    let fraction: Double
    var color: Color = Paper.ink
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Paper.line)
                Capsule().fill(color).frame(width: max(4, g.size.width * min(1, fraction)))
            }
        }.frame(height: 7)
    }
}

/// Thumbnail: the photo if there is one, otherwise a soft tinted card with the initial.
struct Thumb: View {
    let item: Item
    var size: CGFloat = 52
    var radius: CGFloat = 10
    var body: some View {
        ZStack {
            if item.hasPhoto, let img = PhotoFiles.load(item.id) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Paper.tints[stableHash(item.name) % Paper.tints.count]
                Image(systemName: item.category.icon).font(.system(size: size * 0.36, weight: .medium)).foregroundStyle(Paper.ink.opacity(0.45))
            }
        }
        .frame(width: size, height: size).clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Paper.line2))
    }
}

/// Bottom rail: four tabs on a card, plus the terracotta add button.
struct Rail: View {
    @Binding var selection: Tab
    var add: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button { withAnimation(.snappy(duration: 0.25)) { selection = t } } label: {
                        VStack(spacing: 4) {
                            Image(systemName: t.icon).font(.system(size: 16, weight: selection == t ? .bold : .medium))
                            Text(t.rawValue).font(.label(9.5))
                        }
                        .foregroundStyle(selection == t ? Paper.card : Paper.dim)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(Group { if selection == t { RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Paper.ink) } })
                    }.buttonStyle(.plain)
                }
            }
            .padding(5)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Paper.card).shadow(color: Paper.ink.opacity(0.18), radius: 18, y: 8))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Paper.line2))
            Button(action: add) {
                Image(systemName: "plus").font(.system(size: 20, weight: .bold)).foregroundStyle(Paper.card)
                    .frame(width: 58, height: 58).background(Circle().fill(Paper.accent).shadow(color: Paper.accent.opacity(0.4), radius: 14, y: 6))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }
}

/// Same colour for the same name on every launch (hashValue is randomised per process).
func stableHash(_ s: String) -> Int { s.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff } }

/// The big photo at the top of an item page.
struct Hero: View {
    let item: Item
    var body: some View {
        ZStack {
            if item.hasPhoto, let img = PhotoFiles.load(item.id) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Paper.tints[stableHash(item.name) % Paper.tints.count]
                Image(systemName: item.category.icon).font(.system(size: 64, weight: .medium)).foregroundStyle(Paper.ink.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity).frame(height: 260).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Paper.line2))
    }
}
