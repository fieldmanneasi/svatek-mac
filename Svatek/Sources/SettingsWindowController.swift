import AppKit

final class SettingsWindowController: NSWindowController {

    private let onChange: () -> Void
    private var iconOnlyCheckbox: NSButton!
    private var growlCheckbox: NSButton!
    private var loginCheckbox: NSButton!
    private var sizeSlider: NSSlider!

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = NSLocalizedString("SettingsTitle", comment: "")
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.center()
        super.init(window: window)
        buildUI()
        loadValues()
        NSLog("Svatek: SettingsWindowController initialised, contentView subviews=\(window.contentView?.subviews.count ?? -1)")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let label = NSTextField(labelWithString: NSLocalizedString("FontSizeLabel", comment: ""))
        label.frame = NSRect(x: 20, y: 220, width: 340, height: 18)
        content.addSubview(label)

        sizeSlider = NSSlider(value: 12, minValue: 9, maxValue: 14,
                              target: self, action: #selector(sliderChanged(_:)))
        sizeSlider.numberOfTickMarks = 6
        sizeSlider.allowsTickMarkValuesOnly = true
        sizeSlider.tickMarkPosition = .below
        sizeSlider.frame = NSRect(x: 20, y: 188, width: 340, height: 22)
        content.addSubview(sizeSlider)

        for (i, px) in (9...14).enumerated() {
            let t = NSTextField(labelWithString: "\(px)px")
            t.font = NSFont.systemFont(ofSize: 10)
            t.frame = NSRect(x: 20 + i * 65, y: 168, width: 40, height: 14)
            content.addSubview(t)
        }

        iconOnlyCheckbox = NSButton(checkboxWithTitle:
            NSLocalizedString("IconOnly", comment: ""),
            target: self, action: #selector(iconOnlyChanged(_:)))
        iconOnlyCheckbox.frame = NSRect(x: 20, y: 130, width: 340, height: 22)
        content.addSubview(iconOnlyCheckbox)

        growlCheckbox = NSButton(checkboxWithTitle:
            NSLocalizedString("UseGrowl", comment: ""),
            target: self, action: #selector(growlChanged(_:)))
        growlCheckbox.frame = NSRect(x: 20, y: 100, width: 340, height: 22)
        content.addSubview(growlCheckbox)

        loginCheckbox = NSButton(checkboxWithTitle:
            NSLocalizedString("OpenAtLogin", comment: ""),
            target: self, action: #selector(loginChanged(_:)))
        loginCheckbox.frame = NSRect(x: 20, y: 70, width: 340, height: 22)
        content.addSubview(loginCheckbox)
    }

    private func loadValues() {
        let d = UserDefaults.standard
        sizeSlider.integerValue = max(9, min(14, d.integer(forKey: "velikostFontu")))
        iconOnlyCheckbox.state = d.bool(forKey: "zobrazujAppIkonou") ? .on : .off
        growlCheckbox.state = d.bool(forKey: "pouzivejGrowl") ? .on : .off
        loginCheckbox.state = LoginItemController.isEnabled ? .on : .off
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.integerValue, forKey: "velikostFontu")
        onChange()
    }
    @objc private func iconOnlyChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "zobrazujAppIkonou")
        onChange()
    }
    @objc private func growlChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "pouzivejGrowl")
    }
    @objc private func loginChanged(_ sender: NSButton) {
        LoginItemController.setEnabled(sender.state == .on)
        UserDefaults.standard.set(sender.state == .on, forKey: "setMyAppInLoginItems")
    }
}
