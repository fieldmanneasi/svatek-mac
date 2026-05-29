import AppKit
import ServiceManagement
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Preference keys (match original behavior surface)
    private enum DefaultsKey {
        static let fontSize = "velikostFontu"           // 9...14
        static let showIconOnly = "zobrazujAppIkonou"   // true = just icon, no name
        static let useGrowl = "pouzivejGrowl"           // true = post a daily notification
        static let setMyAppInLoginItems = "setMyAppInLoginItems" // user decided once
    }

    private let provider = NameDayProvider()

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var itemDnesMaSvatek: NSMenuItem!
    private var itemOddelovacSvatek: NSMenuItem!
    private var itemZitraMaSvatek: NSMenuItem!
    private var itemPozitriMaSvatek: NSMenuItem!

    private var settingsWindowController: SettingsWindowController?

    private var midnightTimer: Timer?
    private var lastShownDay: Int = -1

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Svatek: applicationDidFinishLaunching")
        registerDefaults()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Give the button visible content immediately so the item paints even
        // if Svatky.strings fails to load or refresh() is delayed.
        if let button = statusItem.button {
            button.title = "Svátek"
            button.imagePosition = .imageLeft
            NSLog("Svatek: statusItem created, button=\(button)")
        } else {
            NSLog("Svatek: WARNING statusItem.button is nil")
        }

        buildMenu()
        statusItem.menu = menu

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // Defer refresh until after AppKit's initial status-bar layout pass.
        // Calling it inline triggers an "already being laid out" recursion warning
        // because setting the button title here is itself driven by AppKit layout.
        DispatchQueue.main.async { [weak self] in self?.refresh() }
        scheduleMidnightTimer()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(systemClockChanged),
                       name: .NSSystemClockDidChange, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification, object: nil)

        // Defer the modal login-item alert so the status item paints first.
        DispatchQueue.main.async { [weak self] in
            self?.promptForLoginItemIfNeeded()
        }
    }

    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            DefaultsKey.fontSize: 12,
            DefaultsKey.showIconOnly: false,
            DefaultsKey.useGrowl: true,
        ])
    }

    // MARK: - Menu construction

    private func buildMenu() {
        let m = NSMenu(title: "Menu")
        m.autoenablesItems = false

        itemDnesMaSvatek = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        itemDnesMaSvatek.isEnabled = false
        m.addItem(itemDnesMaSvatek)

        itemOddelovacSvatek = NSMenuItem.separator()
        m.addItem(itemOddelovacSvatek)

        itemZitraMaSvatek = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        itemZitraMaSvatek.isEnabled = false
        m.addItem(itemZitraMaSvatek)

        itemPozitriMaSvatek = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        itemPozitriMaSvatek.isEnabled = false
        m.addItem(itemPozitriMaSvatek)

        m.addItem(.separator())

        let nastaveni = NSMenuItem(
            title: NSLocalizedString("MenuPreferences", comment: ""),
            action: #selector(doNastaveni(_:)), keyEquivalent: ",")
        nastaveni.target = self
        m.addItem(nastaveni)

        let about = NSMenuItem(
            title: NSLocalizedString("MenuAbout", comment: ""),
            action: #selector(showAbout(_:)), keyEquivalent: "")
        about.target = self
        m.addItem(about)

        m.addItem(.separator())

        let quit = NSMenuItem(
            title: NSLocalizedString("MenuQuit", comment: ""),
            action: #selector(doQuit(_:)), keyEquivalent: "q")
        quit.target = self
        m.addItem(quit)

        self.menu = m
    }

    // MARK: - Refresh (a.k.a. nastavSvatek)

    @objc private func refresh() {
        let cal = Calendar(identifier: .gregorian)
        let today = Date()
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? today
        let dayAfter = cal.date(byAdding: .day, value: 2, to: today) ?? today

        let todayName = provider.name(for: today) ?? ""
        let tomorrowName = provider.name(for: tomorrow) ?? ""
        let dayAfterName = provider.name(for: dayAfter) ?? ""
        NSLog("Svatek: refresh today=\(todayName) tomorrow=\(tomorrowName) dayAfter=\(dayAfterName)")

        let useIcon = UserDefaults.standard.bool(forKey: DefaultsKey.showIconOnly)
        let fontSize = max(9, min(14, UserDefaults.standard.integer(forKey: DefaultsKey.fontSize)))

        // Fallback ensures the status item is never zero-width.
        let displayTitle = todayName.isEmpty ? "Svátek" : todayName

        guard let button = statusItem.button else {
            NSLog("Svatek: refresh aborted — statusItem.button is nil")
            return
        }

        if useIcon, let img = statusIconImage() {
            img.isTemplate = true
            button.image = img
            button.title = ""
        } else {
            button.image = nil
            button.font = NSFont.systemFont(ofSize: CGFloat(fontSize))
            button.title = displayTitle
        }

        let fmtToday = NSLocalizedString("TodayHas", comment: "")
        let fmtTomorrow = NSLocalizedString("TomorrowHas", comment: "")
        let fmtDayAfter = NSLocalizedString("DayAfterHas", comment: "")

        itemDnesMaSvatek.title = String(format: fmtToday, todayName)
        itemZitraMaSvatek.title = String(format: fmtTomorrow, tomorrowName)
        itemPozitriMaSvatek.title = String(format: fmtDayAfter, dayAfterName)

        // Send daily notification once per day if enabled (replaces Growl path)
        let day = cal.ordinality(of: .day, in: .era, for: today) ?? 0
        if day != lastShownDay,
           UserDefaults.standard.bool(forKey: DefaultsKey.useGrowl),
           !todayName.isEmpty {
            postDailyNotification(name: todayName)
            lastShownDay = day
        }
    }

    private func statusIconImage() -> NSImage? {
        if let img = NSImage(named: "Image_plocha_mala") { return img }
        if let url = Bundle.main.url(forResource: "Image_plocha_mala", withExtension: "png"),
           let img = NSImage(contentsOf: url) { return img }
        return NSImage(systemSymbolName: "calendar", accessibilityDescription: "Svátek")
    }

    private func postDailyNotification(name: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("NotifTitle", comment: "")  // "Dnes má svátek"
        content.body = name
        let req = UNNotificationRequest(identifier: "svatek.today.\(name)",
                                        content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    // MARK: - Timer & system events

    private func scheduleMidnightTimer() {
        midnightTimer?.invalidate()
        let cal = Calendar.current
        let tomorrowMidnight = cal.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .strict) ?? Date().addingTimeInterval(3600)
        let interval = tomorrowMidnight.timeIntervalSinceNow
        midnightTimer = Timer.scheduledTimer(
            withTimeInterval: max(60, interval), repeats: false) { [weak self] _ in
                self?.refresh()
                self?.scheduleMidnightTimer()
            }
    }

    @objc private func systemClockChanged() { refresh() }
    @objc private func didWake()            { refresh(); scheduleMidnightTimer() }

    // MARK: - Actions

    @objc func doQuit(_ sender: Any?)       { NSApp.terminate(sender) }
    @objc func showAbout(_ sender: Any?)    {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }

    @objc func doNastaveni(_ sender: Any?) {
        NSLog("Svatek: doNastaveni invoked")
        if settingsWindowController == nil {
            NSLog("Svatek: creating SettingsWindowController")
            settingsWindowController = SettingsWindowController(onChange: { [weak self] in
                self?.refresh()
            })
        }
        NSApp.activate(ignoringOtherApps: true)
        if let window = settingsWindowController?.window {
            window.center()
            window.makeKeyAndOrderFront(sender)
            NSLog("Svatek: settings window ordered front, visible=\(window.isVisible)")
        } else {
            NSLog("Svatek: WARNING settingsWindowController?.window is nil")
        }
    }

    // MARK: - Login items (modern replacement for kLSSharedFileListSessionLoginItems)

    private func promptForLoginItemIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: DefaultsKey.setMyAppInLoginItems) != nil { return }
        // Only ask once. Equivalent to runLoginItemsAlert.
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("NotRunTitle", comment: "")
        alert.informativeText = NSLocalizedString("NotRunMessage", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Yes", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("No", comment: ""))
        let response = alert.runModal()
        let wantsLogin = (response == .alertFirstButtonReturn)
        defaults.set(wantsLogin, forKey: DefaultsKey.setMyAppInLoginItems)
        LoginItemController.setEnabled(wantsLogin)
    }
}

// MARK: - LoginItemController

enum LoginItemController {
    static func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                NSLog("Svatek: login-item update failed: \(error)")
            }
        }
    }

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
}
