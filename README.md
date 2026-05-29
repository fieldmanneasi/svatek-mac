# Svátek — Czech name-day menu-bar app for macOS

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](LICENSE)
[![Platform: macOS 11+](https://img.shields.io/badge/platform-macOS%2011%2B-lightgrey.svg)](#requirements)
[![Apple silicon: native](https://img.shields.io/badge/Apple%20silicon-native-success.svg)](#requirements)

Shows today's Czech name day (svátek) in the macOS menu bar, with tomorrow and
the day after listed in the dropdown menu, and an optional daily notification.

This is a modern Swift/AppKit rewrite of the legacy `net.sandwichlab.svatek`
app (v1.2, 2011, Intel-only) preserving its original Czech functionality but
running natively on Apple silicon.

**Version 3.0** · **License:** [The Unlicense](LICENSE) — public domain.

## Features

- Menu-bar item with today's name in the bar; today / tomorrow / day-after in the menu.
- Settings window: font size 9–14 px, "icon only" mode, daily-notification toggle, "Open at Login" toggle.
- Daily user-notification (`UNUserNotificationCenter`) with title `Dnes má svátek`.
- Login-item registration via `SMAppService` (macOS 13+).
- Automatic refresh at midnight, on system clock change, and after sleep/wake.
- Localized in Czech (`cs`) and English (`en`).

## Requirements

- macOS 11.0 Big Sur or newer
- Xcode 15+ (Swift 5.9)
- Builds universal: `arm64` (Apple silicon) + `x86_64` (Intel)

## Build & run

```sh
git clone <this-repo>.git
cd svatek-mac          # or whatever you named the clone
open Svatek.xcodeproj  # then Product ▸ Run
```

Or from the command line:

```sh
xcodebuild -project Svatek.xcodeproj \
           -scheme Svatek \
           -configuration Release \
           -arch arm64 -arch x86_64 \
           build
```

The build product is `Svatek.app`. Drag to `/Applications`. On first launch
macOS will ask permission to send notifications and (if you tick "Open at
Login") to register as a login item.

## Project layout

```
.
├── LICENSE                            (The Unlicense)
├── README.md
├── Package.swift                      (SwiftPM library — for source inspection)
├── Svatek.xcodeproj/
└── Svatek/
    ├── Sources/
    │   ├── main.swift                 (explicit NSApplication bootstrap)
    │   ├── AppDelegate.swift          (status item, menu, refresh, notifications)
    │   ├── SettingsWindowController.swift
    │   └── NameDayProvider.swift      (loads Svatky.strings)
    └── Resources/
        ├── Info.plist
        ├── Svatky.strings             (366 Czech name-day entries, "M-D" keyed)
        ├── Credits.rtf                (About-panel credits)
        ├── svatekico.icns             (app icon)
        ├── Assets.xcassets/
        ├── cs.lproj/Localizable.strings
        ├── en.lproj/Localizable.strings
        └── (decorative PNGs/GIFs from the legacy bundle)
```

## License

Released into the public domain under [The Unlicense](LICENSE). You may use,
copy, modify, publish, and distribute this software for any purpose without
restriction or attribution.

## Acknowledgements

The list of Czech name-day mappings (`Svatky.strings`, 366 entries including
February 29) was carried over verbatim from the original legacy app. The
modern AppKit/Swift implementation is a clean-room rewrite.
