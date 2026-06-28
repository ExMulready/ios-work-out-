# App Store Assets & Submission Guide — Salvager

Everything you need to prepare for App Store review. The code is done; this is
the marketing/asset checklist you'll complete on a Mac in Xcode + App Store
Connect.

> **Name check first:** "Salvager" is a placeholder. Search the App Store and the
> [USPTO TESS](https://www.uspto.gov/trademarks) database before committing — pick
> a name that's free, then update `CFBundleDisplayName` and the `com.salvager.*`
> identifiers to match.

---

## 1. App Icon

A starter vector icon is in [`Assets/AppIcon.svg`](Assets/AppIcon.svg) — a cutter
beam slicing a derelict hull in deep space. Restyle freely, then export to PNG.

**Modern Xcode (15+) only needs a single 1024×1024 PNG.**

| Requirement | Value |
|---|---|
| Format | PNG, **no alpha/transparency** |
| Size | 1024 × 1024 px |
| Corners | **Square** — Apple applies the rounded mask |
| Color space | sRGB or P3 |

**Export from SVG:** open in a browser and screenshot, or
`inkscape AppIcon.svg -w 1024 -h 1024 -o AppIcon.png`, or any online converter.
Drop the PNG into the AppIcon catalog for **both** the iOS and Watch targets.

---

## 2. Screenshots (required for review)

Capture from the **Simulator** (⌘S) or a real device.

### iPhone

| Display | Resolution (portrait) | Example device |
|---|---|---|
| 6.9" | 1320 × 2868 | iPhone 16 Pro Max |
| 6.7" | 1290 × 2796 | iPhone 15 Pro Max |
| 6.5" | 1242 × 2688 | iPhone 11 Pro Max |

> App Store Connect requires the **6.9"/6.7"** set at minimum.

### Apple Watch (required)

| Watch size | Resolution |
|---|---|
| Ultra 49mm | 410 × 502 |
| 45mm | 396 × 484 |
| 41mm | 352 × 430 |

Show the loop: the **cutter/battle screen with a live event banner**, **Modules**,
a **Sentinel** fight, the **Overclocks** screen, the **complication** on a watch
face, and the **iPhone Salvage Exchange with an event discount**.

### Suggested captions
1. "Strip derelict ships — your drones salvage while you're away."
2. "Live sector events change the rules by the hour."
3. "Upgrade your rig. Overclock. Crack the Sentinels."
4. "Shop the Salvage Exchange on your iPhone."

---

## 3. App Store Connect metadata template

```
App Name:        Salvager  (≤ 30 chars; must be unique — confirm availability)
Subtitle:        Idle space salvage RPG  (≤ 30 chars)
Primary Category: Games
Secondary:        Role Playing  (or Casual)

Promotional Text (≤ 170 chars, editable without review):
  Your workouts now power your rig! Plus live sector events — Ion Storms, Pirate Raids, rare Anomalies.

Description (≤ 4000 chars):
  Salvager is an Apple Watch–first idle RPG. You're a lone drone-operator
  stripping derelict ships in deep space. Tap your cutter to crack hazards, and
  your auto-salvage drones keep working even when your wrist is down.

  Move in the real world, hit harder in the game. The Bio-Boost reads your Apple
  Watch activity — the more Active Energy you burn and Exercise minutes you log
  today, the more your cutter and auto-salvage power surge (up to +100%).

  And the sector is ALIVE: the real-world clock drives rotating World Events — Ion
  Storms boost scrap, Pirate Raids bring tougher foes and richer hauls, weekend
  Salvage Rushes flood the field with rare caches, and rare Anomalies pay triple.
  Learn the rhythm and return when the payouts spike.

  • Bio-Boost: your real workouts power up your rig
  • Real-time sector events that change scrap, enemies, and shop deals
  • One-handed, glanceable play in 5–15 second sessions
  • Idle auto-salvage while you're away (collect on return)
  • Rig Modules, Overclocks, Salvaged Tech, Cutters & Plating to upgrade
  • Sentinel boss fights every 5 depths, and Deep Jump prestige
  • Achievements, a daily bonus streak, and a watch-face complication

  Use the iPhone companion to shop the Salvage Exchange for Tech, fit your rig,
  and stock up on Cores.

Keywords (≤ 100 chars, comma-separated, no spaces):
  idle,clicker,rpg,watch,salvage,space,scifi,workout,fitness,scrap,events,prestige

Support URL:     https://your-site.example/support
Marketing URL:   https://your-site.example   (optional)
Copyright:       © 2026 Your Name
```

---

## 4. In-App Purchases (register in App Store Connect)

Match these to `CrystalPack.all` in `Shared/Sources/Models.swift`:

| Reference Name | Product ID | Type | Price |
|---|---|---|---|
| Core Cache | `com.salvager.cores.small` | Consumable | $0.99 |
| Core Crate | `com.salvager.cores.medium` | Consumable | $3.99 |
| Core Vault | `com.salvager.cores.large` | Consumable | $7.99 |

Each IAP needs a localized name, description, and a review screenshot (a shot of
the Cores tab works).

---

## 5. Privacy (read HealthKit notice carefully)

Saves are local + the user's own iCloud — no accounts, no analytics, no ads as
written. **However, the Bio-Boost feature reads HealthKit data** (Active Energy and
Exercise minutes), so:

- In **App Privacy**, declare **Health & Fitness** data. It is used **on-device only**
  to compute the in-game boost — not collected, transmitted, or linked to identity.
  Select "used for App Functionality / Not Linked / Not used for Tracking".
- The Watch target needs the **HealthKit capability** and the Info.plist key
  **`NSHealthShareUsageDescription`** (read-only; no write access requested).
- Apps that access HealthKit **must have a Privacy Policy URL** — this is required by
  App Review even though no data leaves the device. Add one before submitting.
- HealthKit data must not be used for advertising or shared with third parties
  (guideline 5.1.3) — this app does neither.

---

## 6. Review notes (paste into "Notes for Review")

> This is an Apple Watch–first idle RPG with two pieces of functionality unique to
> the platform. (1) A real-time **World Events system**: the device clock
> deterministically drives rotating sector events that modify scrap payouts, enemy
> difficulty, rare-spawn rates, and in-app shop pricing — so gameplay changes by time
> of day and day of week. (2) A **HealthKit "Bio-Boost"**: the player's Active Energy
> and Exercise minutes for the day increase their in-game power, read-only and used
> entirely on-device. Together these are distinct functionality well beyond a standard
> incremental game. The companion iPhone app provides the shop and consumable IAPs;
> the watchOS app and a watch-face complication are the primary experience.

This pre-empts a **Guideline 4.3** "copycat/spam" flag by naming the distinct
functionality up front, and explains the **HealthKit** usage for the 5.1.3 reviewers.

---

## 7. Final submission checklist

- [ ] App name confirmed available + bundle/IDs updated to match
- [ ] Apple Developer Program membership active ($99/yr)
- [ ] App Group `group.com.salvager.shared` added to all 3 targets
- [ ] iCloud Key-Value + In-App Purchase capabilities enabled
- [ ] HealthKit capability on Watch target + `NSHealthShareUsageDescription` set
- [ ] Privacy Policy URL added (required because the app uses HealthKit)
- [ ] App Privacy declares Health & Fitness (on-device, not linked, not tracking)
- [ ] `CFBundleDisplayName` = chosen name on iOS + Watch
- [ ] 1024 app icon added (iOS + Watch)
- [ ] Screenshots uploaded (iPhone + Watch sizes)
- [ ] 3 consumable Core IAPs created and attached to the version
- [ ] Metadata filled (name, subtitle, description, keywords)
- [ ] App privacy questionnaire completed
- [ ] Review notes pasted (Section 6)
- [ ] Build archived (*Product ▸ Archive*) and uploaded
- [ ] Submit for review
