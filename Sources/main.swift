import Cocoa
import ServiceManagement

struct QuotaSnapshot {
    let remaining: Int
    let used: Int
    let resetDate: String
    let cycle: String
    let plan: String
    let updatedAt: String
}

final class QuotaStore {
    private enum Key {
        static let remaining = "remaining"
        static let resetDate = "resetDate"
        static let plan = "plan"
        static let cycle = "cycle"
        static let launchAtLogin = "launchAtLogin"
        static let updatedAt = "updatedAt"
    }

    var remaining: Int {
        get {
            let value = UserDefaults.standard.object(forKey: Key.remaining) as? Int ?? 87
            return min(100, max(0, value))
        }
        set { UserDefaults.standard.set(min(100, max(0, newValue)), forKey: Key.remaining) }
    }

    var resetDate: String {
        get { UserDefaults.standard.string(forKey: Key.resetDate) ?? "7月25日 11:24" }
        set { UserDefaults.standard.set(newValue, forKey: Key.resetDate) }
    }

    var plan: String {
        get { UserDefaults.standard.string(forKey: Key.plan) ?? "PRO" }
        set { UserDefaults.standard.set(newValue, forKey: Key.plan) }
    }

    var cycle: String {
        get { UserDefaults.standard.string(forKey: Key.cycle) ?? "1 周" }
        set { UserDefaults.standard.set(newValue, forKey: Key.cycle) }
    }

    var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: Key.launchAtLogin) }
        set { UserDefaults.standard.set(newValue, forKey: Key.launchAtLogin) }
    }

    var updatedAt: String {
        get { UserDefaults.standard.string(forKey: Key.updatedAt) ?? "未读取" }
        set { UserDefaults.standard.set(newValue, forKey: Key.updatedAt) }
    }

    func apply(_ snapshot: QuotaSnapshot) {
        remaining = snapshot.remaining
        resetDate = snapshot.resetDate
        cycle = snapshot.cycle
        plan = snapshot.plan
        updatedAt = snapshot.updatedAt
    }
}

final class CodexQuotaReader {
    private let sessionsURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex/sessions")
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    func readLatest() -> QuotaSnapshot? {
        guard let enumerator = FileManager.default.enumerator(
            at: sessionsURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var files: [(url: URL, modified: Date)] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "jsonl" {
            let modified = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            files.append((fileURL, modified))
        }

        for item in files.sorted(by: { $0.modified > $1.modified }).prefix(40) {
            if let snapshot = parse(fileURL: item.url) {
                return snapshot
            }
        }
        return nil
    }

    private func parse(fileURL: URL) -> QuotaSnapshot? {
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }
        for line in text.split(separator: "\n", omittingEmptySubsequences: true).reversed() {
            guard line.contains("\"token_count\""),
                  line.contains("\"rate_limits\""),
                  let data = line.data(using: .utf8),
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload = root["payload"] as? [String: Any],
                  let type = payload["type"] as? String,
                  type == "token_count",
                  let limits = payload["rate_limits"] as? [String: Any],
                  let primary = limits["primary"] as? [String: Any],
                  let usedPercent = primary["used_percent"] as? Double
            else {
                continue
            }

            let used = min(100, max(0, Int(usedPercent.rounded())))
            let remaining = 100 - used
            let windowMinutes = primary["window_minutes"] as? Double
            let cycle = formatCycle(minutes: windowMinutes)
            let resetDate = formatReset(primary["resets_at"])
            let updatedAt = formatTimestamp(root["timestamp"])
            let plan = formatPlan(limits["plan_type"])
            return QuotaSnapshot(remaining: remaining, used: used, resetDate: resetDate, cycle: cycle, plan: plan, updatedAt: updatedAt)
        }
        return nil
    }

    private func formatPlan(_ raw: Any?) -> String {
        guard let text = raw as? String, !text.isEmpty else { return "未知" }
        return text.uppercased()
    }

    private func formatCycle(minutes: Double?) -> String {
        guard let minutes else { return "未知" }
        let days = Int((minutes / 1440).rounded())
        if days >= 1 { return "\(days) 天" }
        let hours = Int((minutes / 60).rounded())
        return "\(max(1, hours)) 小时"
    }

    private func formatReset(_ raw: Any?) -> String {
        if let seconds = raw as? Double {
            return formatter.string(from: Date(timeIntervalSince1970: seconds))
        }
        if let seconds = raw as? Int {
            return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
        }
        return "未知"
    }

    private func formatTimestamp(_ raw: Any?) -> String {
        let date: Date
        if let text = raw as? String {
            let iso = ISO8601DateFormatter()
            date = iso.date(from: text) ?? Date()
        } else {
            date = Date()
        }
        return formatter.string(from: date)
    }
}

final class RingView: NSView {
    var value: Int = 87 { didSet { needsDisplay = true } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize { NSSize(width: 220, height: 220) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds.insetBy(dx: 11, dy: 11)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2
        let lineWidth: CGFloat = 22

        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setStrokeColor(NSColor(calibratedRed: 0.65, green: 0.86, blue: 0.92, alpha: 0.28).cgColor)
        context.addArc(center: center, radius: radius - lineWidth / 2, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()

        let start = CGFloat.pi * 0.72
        let end = start + CGFloat(value) / 100 * CGFloat.pi * 2
        let colors = [
            NSColor(calibratedRed: 0.19, green: 0.88, blue: 0.62, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.14, green: 0.62, blue: 0.91, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.36, green: 0.27, blue: 0.93, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.58, 1])!

        context.saveGState()
        context.addArc(center: center, radius: radius - lineWidth / 2, startAngle: start, endAngle: end, clockwise: false)
        context.replacePathWithStrokedPath()
        context.clip()
        context.drawLinearGradient(gradient, start: CGPoint(x: bounds.minX, y: bounds.maxY), end: CGPoint(x: bounds.maxX, y: bounds.minY), options: [])
        context.restoreGState()

        let markerAngle = start
        let marker = CGPoint(x: center.x + cos(markerAngle) * (radius - lineWidth / 2), y: center.y + sin(markerAngle) * (radius - lineWidth / 2))
        context.setFillColor(NSColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: marker.x - 8, y: marker.y - 8, width: 16, height: 16))
        context.setStrokeColor(NSColor(calibratedRed: 0.36, green: 0.27, blue: 0.93, alpha: 1).cgColor)
        context.setLineWidth(5)
        context.strokeEllipse(in: CGRect(x: marker.x - 8, y: marker.y - 8, width: 16, height: 16))
    }
}

final class GradientBar: NSView {
    var value: Int = 87 { didSet { needsDisplay = true } }
    private var shimmer: CGFloat = -0.35
    private var animationTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        startAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize { NSSize(width: 460, height: 22) }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let radius = bounds.height / 2
        let track = CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil)
        context.setFillColor(NSColor(calibratedRed: 0.63, green: 0.79, blue: 0.83, alpha: 0.28).cgColor)
        context.addPath(track)
        context.fillPath()

        let fillWidth = max(bounds.height, bounds.width * CGFloat(value) / 100)
        let fillRect = CGRect(x: bounds.minX, y: bounds.minY, width: fillWidth, height: bounds.height)
        let fill = CGPath(roundedRect: fillRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        let colors = [
            NSColor(calibratedRed: 0.19, green: 0.88, blue: 0.62, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.12, green: 0.62, blue: 0.91, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.36, green: 0.27, blue: 0.93, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.6, 1])!
        context.saveGState()
        context.addPath(fill)
        context.clip()
        context.drawLinearGradient(gradient, start: CGPoint(x: fillRect.minX, y: fillRect.midY), end: CGPoint(x: fillRect.maxX, y: fillRect.midY), options: [])

        let shineWidth = max(52, bounds.width * 0.16)
        let shineX = fillRect.minX + (fillRect.width + shineWidth * 2) * shimmer - shineWidth
        let shineRect = CGRect(x: shineX, y: fillRect.minY, width: shineWidth, height: fillRect.height)
        let shineColors = [
            NSColor.white.withAlphaComponent(0).cgColor,
            NSColor.white.withAlphaComponent(0.55).cgColor,
            NSColor.white.withAlphaComponent(0).cgColor
        ] as CFArray
        let shine = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: shineColors, locations: [0, 0.5, 1])!
        context.drawLinearGradient(shine, start: CGPoint(x: shineRect.minX, y: shineRect.midY), end: CGPoint(x: shineRect.maxX, y: shineRect.midY), options: [])
        context.restoreGState()
    }

    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            shimmer += 0.018
            if shimmer > 1.25 { shimmer = -0.35 }
            needsDisplay = true
        }
    }

    deinit {
        animationTimer?.invalidate()
    }
}

final class QuotaPanelController: NSWindowController {
    private let store: QuotaStore
    private let onUpdate: () -> Void
    private let ring = RingView(frame: .zero)
    private let bar = GradientBar(frame: .zero)
    private let percentLabel = NSTextField(labelWithString: "87%")
    private let usedLabel = NSTextField(labelWithString: "已用 13%")
    private let updatedLabel = NSTextField(labelWithString: "未读取")
    private let slider = NSSlider(value: 87, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let launchButton = NSButton(checkboxWithTitle: "登录启动已开启", target: nil, action: nil)
    private let resetLabel = NSTextField(labelWithString: "7月25日 11:24")

    init(store: QuotaStore, onUpdate: @escaping () -> Void) {
        self.store = store
        self.onUpdate = onUpdate
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 620, height: 452), styleMask: [.titled, .closable, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "Codex 余量"
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        super.init(window: panel)
        build()
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh() {
        let value = store.remaining
        ring.value = value
        bar.value = value
        percentLabel.stringValue = "\(value)%"
        usedLabel.stringValue = "已用 \(100 - value)%"
        slider.integerValue = value
        resetLabel.stringValue = store.resetDate
        updatedLabel.stringValue = "更新 \(store.updatedAt)"
        launchButton.state = store.launchAtLogin ? .on : .off
        launchButton.title = store.launchAtLogin ? "登录启动已开启" : "登录启动未开启"
    }

    private func build() {
        guard let content = window?.contentView else { return }
        content.wantsLayer = true
        content.layer?.cornerRadius = 30
        content.layer?.backgroundColor = NSColor(calibratedRed: 0.84, green: 0.97, blue: 1, alpha: 0.84).cgColor
        content.layer?.borderColor = NSColor.white.withAlphaComponent(0.68).cgColor
        content.layer?.borderWidth = 1

        let root = NSStackView()
        root.orientation = .vertical
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 24, left: 26, bottom: 22, right: 26)
        root.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            root.topAnchor.constraint(equalTo: content.topAnchor),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])

        let header = NSStackView()
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 16

        let logo = LogoView(frame: NSRect(x: 0, y: 0, width: 54, height: 54))
        logo.widthAnchor.constraint(equalToConstant: 54).isActive = true
        logo.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let titleStack = NSStackView()
        titleStack.orientation = .vertical
        titleStack.spacing = 4
        let title = label("Codex 余量", size: 28, weight: .medium, color: NSColor(calibratedRed: 0.07, green: 0.13, blue: 0.19, alpha: 1))
        let subtitle = label("自动读取本机 Codex 限额", size: 16, weight: .regular, color: NSColor(calibratedRed: 0.31, green: 0.43, blue: 0.54, alpha: 1))
        titleStack.addArrangedSubview(title)
        titleStack.addArrangedSubview(subtitle)

        let live = pill("●  自动")
        header.addArrangedSubview(logo)
        header.addArrangedSubview(titleStack)
        header.addArrangedSubview(NSView())
        header.addArrangedSubview(live)
        root.addArrangedSubview(header)

        let middle = NSStackView()
        middle.orientation = .horizontal
        middle.alignment = .centerY
        middle.spacing = 18
        middle.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        middle.wantsLayer = true
        middle.layer?.cornerRadius = 26
        middle.layer?.backgroundColor = NSColor(calibratedRed: 0.77, green: 0.96, blue: 1, alpha: 0.46).cgColor
        middle.layer?.borderColor = NSColor.white.withAlphaComponent(0.62).cgColor
        middle.layer?.borderWidth = 1

        let gaugeStack = NSStackView()
        gaugeStack.orientation = .vertical
        gaugeStack.alignment = .centerX
        gaugeStack.spacing = 0
        let gaugeOverlay = NSView()
        gaugeOverlay.translatesAutoresizingMaskIntoConstraints = false
        gaugeOverlay.addSubview(ring)
        ring.translatesAutoresizingMaskIntoConstraints = false
        gaugeOverlay.addSubview(percentLabel)
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        percentLabel.font = .systemFont(ofSize: 52, weight: .medium)
        percentLabel.textColor = NSColor(calibratedRed: 0.07, green: 0.13, blue: 0.19, alpha: 1)
        percentLabel.alignment = .center
        let remain = label("剩余", size: 17, weight: .medium, color: NSColor(calibratedRed: 0.31, green: 0.43, blue: 0.54, alpha: 1))
        gaugeOverlay.addSubview(remain)
        remain.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gaugeOverlay.widthAnchor.constraint(equalToConstant: 198),
            gaugeOverlay.heightAnchor.constraint(equalToConstant: 198),
            ring.centerXAnchor.constraint(equalTo: gaugeOverlay.centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: gaugeOverlay.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: 188),
            ring.heightAnchor.constraint(equalToConstant: 188),
            percentLabel.centerXAnchor.constraint(equalTo: gaugeOverlay.centerXAnchor),
            percentLabel.centerYAnchor.constraint(equalTo: gaugeOverlay.centerYAnchor, constant: -8),
            remain.centerXAnchor.constraint(equalTo: gaugeOverlay.centerXAnchor),
            remain.topAnchor.constraint(equalTo: percentLabel.bottomAnchor, constant: 2)
        ])
        gaugeStack.addArrangedSubview(gaugeOverlay)

        let details = NSStackView()
        details.orientation = .vertical
        details.spacing = 11
        details.widthAnchor.constraint(equalToConstant: 286).isActive = true
        details.addArrangedSubview(detail(title: "周期", value: store.cycle))
        details.addArrangedSubview(detail(title: "重置", valueView: resetLabel))
        details.addArrangedSubview(detail(title: "套餐", value: store.plan))
        middle.addArrangedSubview(gaugeStack)
        middle.addArrangedSubview(details)
        root.addArrangedSubview(middle)

        bar.heightAnchor.constraint(equalToConstant: 20).isActive = true
        root.addArrangedSubview(bar)
        let meta = NSStackView()
        meta.orientation = .horizontal
        updatedLabel.font = .systemFont(ofSize: 15, weight: .regular)
        updatedLabel.textColor = NSColor(calibratedRed: 0.36, green: 0.49, blue: 0.59, alpha: 1)
        meta.addArrangedSubview(updatedLabel)
        meta.addArrangedSubview(NSView())
        usedLabel.font = .systemFont(ofSize: 16, weight: .regular)
        usedLabel.textColor = NSColor(calibratedRed: 0.36, green: 0.49, blue: 0.59, alpha: 1)
        meta.addArrangedSubview(usedLabel)
        root.addArrangedSubview(meta)

        let footer = NSStackView()
        footer.orientation = .horizontal
        footer.alignment = .centerY
        launchButton.target = self
        launchButton.action = #selector(toggleLaunchAtLogin)
        launchButton.font = .systemFont(ofSize: 16, weight: .regular)
        let refresh = NSButton(title: "立即刷新", target: self, action: #selector(refreshClicked))
        let quit = NSButton(title: "退出", target: NSApp, action: #selector(NSApplication.terminate(_:)))
        footer.addArrangedSubview(launchButton)
        footer.addArrangedSubview(NSView())
        footer.addArrangedSubview(refresh)
        footer.addArrangedSubview(quit)
        root.addArrangedSubview(footer)
    }

    @objc private func sliderChanged() {
        store.remaining = slider.integerValue
        refresh()
        onUpdate()
    }

    @objc private func refreshClicked() {
        refresh()
        onUpdate()
    }

    @objc private func toggleLaunchAtLogin() {
        store.launchAtLogin = launchButton.state == .on
        refresh()
        onUpdate()
    }

    private func detail(title: String, value: String) -> NSView {
        let valueLabel = label(value, size: 28, weight: .medium, color: NSColor(calibratedRed: 0.07, green: 0.13, blue: 0.19, alpha: 1))
        return detail(title: title, content: valueLabel)
    }

    private func detail(title: String, valueView: NSTextField) -> NSView {
        valueView.font = .systemFont(ofSize: 28, weight: .medium)
        valueView.textColor = NSColor(calibratedRed: 0.07, green: 0.13, blue: 0.19, alpha: 1)
        valueView.lineBreakMode = .byTruncatingTail
        valueView.maximumNumberOfLines = 1
        valueView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return detail(title: title, content: valueView)
    }

    private func detail(title: String, content: NSView) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 4
        stack.addArrangedSubview(label(title, size: 16, weight: .medium, color: NSColor(calibratedRed: 0.36, green: 0.49, blue: 0.59, alpha: 1)))
        stack.addArrangedSubview(content)
        return stack
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: size, weight: weight)
        field.textColor = color
        field.lineBreakMode = .byTruncatingTail
        field.maximumNumberOfLines = 1
        return field
    }

    private func pill(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: 17, weight: .medium)
        field.textColor = NSColor(calibratedRed: 0.07, green: 0.2, blue: 0.3, alpha: 1)
        field.alignment = .center
        field.wantsLayer = true
        field.layer?.cornerRadius = 18
        field.layer?.backgroundColor = NSColor(calibratedRed: 0.75, green: 0.94, blue: 0.98, alpha: 0.82).cgColor
        field.widthAnchor.constraint(equalToConstant: 116).isActive = true
        field.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return field
    }
}

final class LogoView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
            NSColor(calibratedRed: 0.36, green: 0.38, blue: 0.94, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.17, green: 0.88, blue: 0.63, alpha: 1).cgColor
        ] as CFArray, locations: [0, 1])!
        let path = CGPath(ellipseIn: bounds.insetBy(dx: 1, dy: 1), transform: nil)
        context.saveGState()
        context.addPath(path)
        context.clip()
        context.drawLinearGradient(gradient, start: CGPoint(x: bounds.midX, y: bounds.maxY), end: CGPoint(x: bounds.midX, y: bounds.minY), options: [])
        context.restoreGState()

        NSColor.white.setFill()
        star(center: CGPoint(x: bounds.midX - 5, y: bounds.midY + 2), outer: 18, inner: 6).fill()
        star(center: CGPoint(x: bounds.midX + 17, y: bounds.midY + 18), outer: 6, inner: 2).fill()
    }

    private func star(center: CGPoint, outer: CGFloat, inner: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        for index in 0..<8 {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(index) * .pi / 4 - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.line(to: point)
        }
        path.close()
        return path
    }
}

final class StatusIconFactory {
    static func image(phase: CGFloat) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        let bounds = CGRect(origin: .zero, size: size)
        let pulse = 0.5 + 0.5 * sin(phase)
        let orbRect = bounds.insetBy(dx: 1.4 + pulse * 0.4, dy: 1.4 + pulse * 0.4)
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
            NSColor(calibratedRed: 0.37, green: 0.41, blue: 0.97, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.12, green: 0.86, blue: 0.66, alpha: 1).cgColor
        ] as CFArray, locations: [0, 1])!
        context.saveGState()
        context.addEllipse(in: orbRect)
        context.clip()
        context.drawLinearGradient(gradient, start: CGPoint(x: orbRect.midX, y: orbRect.maxY), end: CGPoint(x: orbRect.midX, y: orbRect.minY), options: [])
        context.restoreGState()

        NSColor.white.setFill()
        star(center: CGPoint(x: 8.2, y: 8.8), outer: 5.6, inner: 1.8).fill()
        let sparkleAngle = phase.truncatingRemainder(dividingBy: .pi * 2)
        let sparkleCenter = CGPoint(x: 13.7 + cos(sparkleAngle) * 0.7, y: 13.8 + sin(sparkleAngle) * 0.7)
        star(center: sparkleCenter, outer: 2.3 + pulse * 0.7, inner: 0.75).fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func star(center: CGPoint, outer: CGFloat, inner: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        for index in 0..<8 {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(index) * .pi / 4 - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.line(to: point)
        }
        path.close()
        return path
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = QuotaStore()
    private let reader = CodexQuotaReader()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var panelController: QuotaPanelController?
    private var timer: Timer?
    private var iconTimer: Timer?
    private var iconPhase: CGFloat = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        updateFromCodex()
        configureStatusItem()
        panelController = QuotaPanelController(store: store) { [weak self] in
            self?.updateFromCodex()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateFromCodex()
        }
        iconTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            self?.animateStatusIcon()
        }
    }

    private func configureStatusItem() {
        let value = store.remaining
        statusItem.length = 78
        statusItem.button?.title = "\(value)%"
        statusItem.button?.font = .systemFont(ofSize: 14, weight: .medium)
        statusItem.button?.image = StatusIconFactory.image(phase: iconPhase)
        statusItem.button?.imagePosition = .imageLeft
        statusItem.button?.toolTip = "Codex 余量 \(value)%"
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel)
    }

    private func animateStatusIcon() {
        iconPhase += 0.34
        statusItem.button?.image = StatusIconFactory.image(phase: iconPhase)
    }

    private func updateFromCodex() {
        if let snapshot = reader.readLatest() {
            store.apply(snapshot)
        }
        configureStatusItem()
        panelController?.refresh()
    }

    @objc private func togglePanel() {
        guard let button = statusItem.button, let window = panelController?.window else { return }
        panelController?.refresh()
        if window.isVisible {
            window.orderOut(nil)
            return
        }

        let buttonRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
        let origin = NSPoint(x: buttonRect.midX - window.frame.width / 2, y: buttonRect.minY - window.frame.height - 8)
        window.setFrameOrigin(origin)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
