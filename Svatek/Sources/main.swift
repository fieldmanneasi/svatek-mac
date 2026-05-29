import AppKit

// Explicit bootstrap. `@main` on a plain NSApplicationDelegate does not
// install the delegate on NSApp and applicationDidFinishLaunching never
// fires — the process stays alive but no status item appears. Doing it by
// hand is the safe, version-independent path on modern macOS.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// LSUIElement=1 already hides the Dock icon, but set the activation policy
// explicitly so the status item paints reliably on every macOS version.
app.setActivationPolicy(.accessory)
app.run()
