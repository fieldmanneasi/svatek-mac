import Foundation

struct NameDayProvider {
    private let table: [String: String]

    init(bundle: Bundle = .main) {
        self.table = Self.loadTable(bundle: bundle)
        NSLog("Svatek: NameDayProvider loaded \(self.table.count) entries")
    }

    private static func loadTable(bundle: Bundle) -> [String: String] {
        // Xcode's strings compiler may localize this file into Base.lproj or
        // cs.lproj, so look both at the bundle root and via the localized lookup.
        let candidates: [URL?] = [
            bundle.url(forResource: "Svatky", withExtension: "strings"),
            bundle.url(forResource: "Svatky", withExtension: "strings", subdirectory: nil, localization: "Base"),
            bundle.url(forResource: "Svatky", withExtension: "strings", subdirectory: nil, localization: "cs"),
            bundle.url(forResource: "Svatky", withExtension: "strings", subdirectory: nil, localization: "en"),
        ]

        for case let url? in candidates {
            guard let data = try? Data(contentsOf: url) else { continue }
            if let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                var out: [String: String] = [:]
                out.reserveCapacity(dict.count)
                for (k, v) in dict { if let s = v as? String { out[k] = s } }
                if !out.isEmpty { return out }
            }
        }

        NSLog("Svatek: NameDayProvider FAILED to load Svatky.strings from bundle \(bundle.bundlePath)")
        return [:]
    }

    func name(for date: Date, calendar: Calendar = .current) -> String? {
        let comps = calendar.dateComponents([.month, .day], from: date)
        guard let m = comps.month, let d = comps.day else { return nil }
        return table["\(m)-\(d)"]
    }
}
