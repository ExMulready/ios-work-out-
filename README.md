# Salvager — Apple Watch Idle Salvage RPG

> Working title: **"Salvager"** (placeholder — check name availability on the
> App Store and for trademark before committing). Bundle/IDs use `com.salvager.*`.

An Apple Watch–first idle RPG: you're a lone drone-operator stripping derelict
ships in deep space. Crack hazards with your cutter, let your auto-salvage drones
work while you're away, upgrade your rig, and ride the **live, clock-driven sector
events**. An iPhone companion app runs the Salvage Exchange and in-app purchases.

This started as a RuneBlade-style clicker, then was deliberately re-themed and
given a signature mechanic so it stands on its own (see **"Differentiation"**).

- **Watch app** — tap the CUTTER to destroy hazards, idle auto-salvage runs while
  away, upgrade rig **Modules** with scrap, trigger timed **Overclocks**, fight a
  **Sentinel** boss every 5 depths, watch for rare **Salvage Caches**, and **Deep
  Jump** (prestige) to drift deeper.
- **iPhone app** — the **Salvage Exchange**: spend Cores on Salvaged Tech, fit
  Cutters/Plating, and buy Core packs via real-money In-App Purchases.
- **World Events** — the hour of day & day of week select a live event (Ion Storm,
  Pirate Raid, Salvage Rush, Meteor Shower…) that changes scrap payouts, enemy
  toughness, rare-cache odds, and Exchange discounts. A rare clock-seeded **Anomaly**
  tier (Quantum Anomaly, Ghost Fleet) can override the schedule with huge payouts.
  **This is the headline feature.**
- **Bio-Boost (HealthKit)** — your real-world **Active Energy** and **Exercise
  minutes** today multiply your in-game cutter & auto-salvage power (up to +100%).
  Move IRL, hit harder in-game. Watch-only functionality and a major differentiator.
- **Achievements** — 14 permanent achievements that reward Cores on unlock, with an
  in-game toast and a browser on both Watch and Phone.
- **Daily Salvage Bonus** — a once-per-day Core reward with a growing streak.
- **First-launch onboarding** — a paged intro that teaches the loop and the World
  Events rhythm.
- **Audio & haptics** — centralized feedback with user toggles (haptics on by
  default; bundled sound effects opt-in).
- **Watch-face complication** — depth, scrap, and the live event at a glance.
- **Idle reminders** — a local notification nudges you back to collect scrap.

---

## Differentiation (why this isn't a clone)

Two separate concerns, both addressed deliberately:

1. **Copyright** — game *mechanics/genre* (clicking, idle, prestige) aren't
   copyrightable; only *expression* is (name, art, specific named content). This
   project shares **none** of RuneBlade's name, assets, theme, or named items.
2. **App Store Guideline 4.3 (Spam/Copycat)** — the #1 rejection reason. Apple
   wants **distinct functionality**, not a reskin. Our answer is the **World Events
   system**: real-time, clock-driven game state is a genuine mechanic a reviewer can
   point to, and the **Watch-first** design (sensors, complication) is itself
   uncommon. When submitting, call these out explicitly in the review notes.

---

## File layout

```
appleWatchGame/
├── README.md                  ← you are here
├── AppStoreAssets.md          # icon/screenshot specs + submission guide
├── Assets/
│   └── AppIcon.svg            # starter 1024×1024 vector app icon (salvage theme)
├── Shared/
│   └── Sources/
│       ├── Models.swift        # GameState, Monster (hazards), Rune (Modules),
│       │                       #   Artifact (Tech), Equipment, CrystalPack (Cores)
│       ├── Spells.swift        # Overclocks (timed buffs) + active/cooldown status
│       ├── WorldEvents.swift   # ★ signature: clock-driven events + anomalies + scheduler
│       ├── WorldEvent+UI.swift # SwiftUI color/duration helpers for events
│       ├── Achievements.swift  # achievement catalog + predicates + Core rewards
│       ├── GameEngine.swift    # tick loop, damage, events, caches, achievements, prestige
│       └── SharedStore.swift   # App Group + iCloud persistence (app & widget)
├── WatchApp/
│   ├── RuneClickerApp.swift            # @main watchOS entry (display name: Salvager)
│   ├── ExtendedRuntimeManager.swift    # short background runtime session
│   ├── NotificationManager.swift       # idle "come back" reminders
│   ├── HealthManager.swift             # ★ HealthKit → Bio-Boost power
│   ├── FeedbackManager.swift           # centralized haptics + optional SFX
│   ├── WatchConnectivityManager.swift  # Watch↔Phone sync
│   └── Views/
│       ├── BattleView.swift    # cutter screen + event banner + toasts + daily bonus
│       ├── RuneView.swift      # upgrade rig Modules with scrap
│       ├── SpellsView.swift    # trigger Overclocks
│       ├── BossView.swift      # Sentinel intro screen
│       ├── StatsView.swift     # stats, Bio-Boost, settings, Deep Jump, reset
│       ├── AchievementsView.swift  # achievement browser
│       ├── BioBoostView.swift      # HealthKit activity → power explainer
│       └── OnboardingView.swift    # first-launch paged intro
├── WatchWidget/
│   └── RuneClickerWidget.swift # watch-face complication (depth/scrap/event)
└── iOSApp/
    ├── RuneClickerCompanionApp.swift   # @main iOS entry (TabView)
    ├── CompanionModel.swift            # phone-side wallet/inventory + event pricing
    ├── WatchConnectivityManager.swift  # Phone↔Watch sync
    ├── StoreKitManager.swift           # StoreKit 2 IAP (Core packs)
    ├── Products.storekit               # local IAP test config
    └── Views/
        ├── WalletHeader.swift  # wallet + live World Event strip
        ├── ShopView.swift      # Salvage Exchange (event discounts)
        ├── EquipmentView.swift # Cutter/Plating loadout
        ├── StoreView.swift     # buy Core packs (real money)
        └── InventoryView.swift # cargo manifest + synced run stats
```

> File/struct names keep the legacy `RuneClicker` prefix for internal stability —
> the *shipping product name* is "Salvager", set via `CFBundleDisplayName` in Xcode.
> Internal Swift types also keep neutral names (`Rune`, `Artifact`, `Spell`); only
> the player-facing strings are themed. Rename later if you like — it's cosmetic.

---

## Tech stack

| Concern | Choice |
|---|---|
| Language | Swift 5.9+ |
| UI | SwiftUI (both targets + widget) |
| Watch ↔ Phone | WatchConnectivity (`WCSession`) |
| In-App Purchase | StoreKit 2 (`Product`, `Transaction.updates`) |
| Persistence | App Group `UserDefaults` + `NSUbiquitousKeyValueStore` (iCloud) |
| Min OS | watchOS 10 / iOS 17 |

---

## Assembling the Xcode project (on a Mac)

You still need a Mac with Xcode to build/run/ship (watchOS/iOS SDKs are macOS-only).
These files are plain Swift — create the project shell once, then add them.

1. **Install Xcode** from the Mac App Store.
2. **New project** → *iOS* → **App**. Name `Salvager`, Interface **SwiftUI**, bundle
   id `com.salvager` (must be unique — change the suffix if taken).
3. **Add a Watch target**: *File ▸ New ▸ Target… ▸ watchOS ▸ App* → "Watch App for
   iOS App". 
4. **Add the Widget target**: *File ▸ New ▸ Target… ▸ watchOS ▸ Widget Extension*,
   name `SalvagerWidget`, uncheck "Include Configuration Intent".
5. **Delete** the placeholder `ContentView.swift` / `*App.swift` / generated widget
   files Xcode created (you're replacing them).
6. **Drag the folders in** from Finder:
   - `Shared/Sources/*.swift` → add to the **iOS app, Watch app, AND Widget** targets.
   - `WatchApp/**` → Watch target only.
   - `iOSApp/**` → iOS target only.
   - `WatchWidget/RuneClickerWidget.swift` → Widget target only.
7. **Deployment targets**: iOS 17, watchOS 10.
8. **Capabilities** (Signing & Capabilities):
   - **App Groups** → add `group.com.salvager.shared` to **all three** targets
     (must match `SharedStore.appGroupID`). This lets the complication read the save.
   - **iCloud ▸ Key-Value storage** on iOS + Watch targets.
   - **In-App Purchase** on the iOS target.
   - **HealthKit** on the **Watch target** (for Bio-Boost). Then add this key to the
     Watch app's Info.plist:
     - `NSHealthShareUsageDescription` = "Salvager uses your activity (active energy
       and exercise minutes) to power up your rig." *(Read-only — no write access.)*
   - *(Optional)* Sound effects: add short `.wav` files named `tap`, `kill`,
     `levelup`, `upgrade`, `achievement`, `boss`, `fail` to the Watch target. Missing
     files are simply skipped (see `FeedbackManager`).
9. **App display name**: set `CFBundleDisplayName` = `Salvager` for iOS + Watch targets.
10. **App icon**: export `Assets/AppIcon.svg` → 1024×1024 PNG → AppIcon catalog
    (see [AppStoreAssets.md](AppStoreAssets.md)).
11. **StoreKit testing**: *Edit Scheme ▸ Run ▸ Options ▸ StoreKit Configuration* →
    `iOSApp/Products.storekit`. Buy Cores in the Simulator with no real money.
12. **Run** the Watch + iPhone schemes together; add the complication from the
    watch-face edit screen.

---

## How the game loop works

- `GameEngine` runs a 1-second `Timer`. Each tick applies idle auto-salvage (DPS)
  as scrap; tapping the CUTTER applies tap damage. Scrap is multiplied by the
  active World Event.
- Clearing 10 hazards (or 1 Sentinel on boss depths) advances the depth. HP & scrap
  scale per depth in `Bestiary.monster(forLevel:)`.
- **Rare Salvage Caches** spawn by chance (base 2% + the event's bonus): low HP,
  big scrap, don't count toward depth progress.
- **Overclocks** are timed buffs triggered with scrap (`Spell.catalog`), tracked by
  a single cast-timestamp (active while `now < cast+duration`, then on cooldown).
- **World Events** (`WorldEventScheduler`) are derived purely from the clock, so the
  Watch, Phone, and complication agree with **no server**. They modify scrap
  multiplier, enemy HP, rare-cache odds, and which Tech the Exchange discounts. A
  clock-seeded LCG gives a rare **Anomaly** (~1 in 11 four-hour blocks) that overrides
  the schedule — same result on every device.
- **Achievements** (`Achievement.catalog`) are checked after each kill/cache/jump;
  unlocking credits Cores and queues a toast (`GameEngine.recentlyUnlocked`). They
  persist through Deep Jumps.
- Backgrounding saves a timestamp; on next launch `applyOfflineEarnings()` grants up
  to **8 hours** of idle scrap as "Welcome back".
- **Bio-Boost** (`HealthManager` → `GameEngine.bioBoostMultiplier`) reads today's
  HealthKit Active Energy + Exercise minutes and multiplies cutter & auto power up to
  ×2. It refreshes on launch/foreground and resets daily with HealthKit's own totals.
- **Daily Salvage Bonus** grants Cores once per day (`claimDailyReward`), with a
  streak that grows the payout (capped at 50 Cores).
- At **Depth 100**, `canPrestige` flips → **Deep Jump**: restart at Depth 1, keep
  Tech & gear, gain **+10% permanent power**. Lifetime stats persist.
- The save lives in an **App Group** (`SharedStore`) so the **complication** reads
  the same state; every save calls `WidgetCenter.reloadAllTimelines()`.

## Watch ↔ Phone sync model

- **Watch is authoritative** for run progress: depth, scrap, modules.
- **Phone is authoritative** for the wallet & inventory: Cores, Tech, fitted gear.
- Both send the full `GameState` over `WCSession`; each side's `merge…` copies only
  the fields it trusts. No tug-of-war over shared numbers.

---

## Where to customize / expand

| Want to change… | Edit… |
|---|---|
| Hazard/Sentinel HP curve, names | `Bestiary` in `Models.swift` |
| Rig Module list, costs, bonuses | `Rune.starterRunes` in `Models.swift` |
| Overclock list, effects, cooldowns | `Spell.catalog` in `Spells.swift` |
| **World Events, anomalies & schedule** | `WorldEvent` catalog + `WorldEventScheduler` (anomaly rate in `anomaly(at:)`) |
| Achievements & Core rewards | `Achievement.catalog` in `Achievements.swift` |
| Bio-Boost formula / cap | `GameEngine.bioBoostMultiplier` |
| Health metrics read | `HealthManager` (`activeEnergyBurned`, `appleExerciseTime`) |
| Daily reward amount / streak | `GameEngine.claimDailyReward` |
| Haptic/sound mapping | `FeedbackManager` (`haptic(for:)`, `soundFile(for:)`) |
| Onboarding pages | `WatchApp/Views/OnboardingView.swift` |
| Salvaged Tech catalog & prices | `Artifact.catalog` in `Models.swift` |
| Cutter/Plating catalog | `Equipment.catalog` in `Models.swift` |
| Rare-cache base chance | `GameEngine.baseRareCacheChance` |
| Hazards per depth / boss interval | `GameState.killsPerLevel`, `isBossLevel` |
| Offline cap, Sentinel timer | `GameEngine` (`applyOfflineEarnings`, `bossTimeLimit`) |
| Idle reminder timing | `NotificationManager.scheduleIdleReminder` |
| Core pack contents/prices | `CrystalPack.all` + `Products.storekit` |
| App Group / complication | `SharedStore.appGroupID`, `WatchWidget/` |

---

## App Store submission

See [AppStoreAssets.md](AppStoreAssets.md) for the full checklist — icon/screenshot
specs, metadata template, the three Core IAPs, and the review-notes language that
highlights World Events as the differentiating functionality.
