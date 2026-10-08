# 📋 Production.INC — Master Release & Quarterly Maintenance Checklist (`CHECKLIST.md`)

> **Document Status**: 🟢 **Active Master Checklist**  
> **Target Version**: Version 2.0.0 Final Release Candidate (`2.0.0+20`)  
> **Platform**: Google Play Console (Android) & Offline Single-Player  
> **Purpose**: Serves as the single master checklist for pre-launch deliverables, release packaging, and recurring **quarterly maintenance reviews**.

---

## 📌 Executive Summary & Policy Compliance Status

> [!NOTE]
> **Google Play Store Compliance Note**: All standard Google Play Store policy declarations (Data Safety form, hosted public Privacy Policy URL, zero-tracking disclosures, and IARC content ratings) are **centrally configured and satisfied across developer organization accounts / companion projects**. You do **not** need to re-verify or regenerate them per individual build. Use the [Quarterly Maintenance Audit](#-part-3-quarterly-maintenance--audit-checklist) section below for periodic checks.

---

## 🚀 Part 1: Immediate Pre-Launch Deliverables

These are the remaining actionable tasks before launching on the Google Play Store:

### 1.1 Android Signing & Production Build Packaging
- [x] Ignore keystore files (`*.jks`, `*.keystore`, `*.p12`, `*.cer`) and `android/key.properties` in [`.gitignore`](file:///.gitignore).
- [x] Configure R8 minification, resource shrinking, and ProGuard keep rules in [`android/app/build.gradle.kts`](file:///android/app/build.gradle.kts) and [`proguard-rules.pro`](file:///android/app/proguard-rules.pro).
- [x] Configure Android 13+ Material You monochrome adaptive icon in [`launcher_icon.xml`](file:///android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml).
- [ ] **Setup `android/key.properties`**:
  - Copy [`android/key.properties.template`](file:///android/key.properties.template) to `android/key.properties`.
  - Provide valid credentials (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`).
- [ ] **Build Release Android App Bundle (AAB)**:
  ```bash
  flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
  ```
  - Verify bundle output in `build/app/outputs/bundle/release/app-release.aab`.

### 1.2 Store Listing Visual Assets & Media
- [ ] **High-Resolution App Icon**:
  - `512 × 512 px` PNG, 32-bit color, no alpha transparency.
- [ ] **Feature Graphic Banner**:
  - `1024 × 500 px` PNG/JPEG, landscape showcasing the factory floor and logistics carriers.
- [ ] **Promotional Screenshots (1080 × 2400 Portrait)**:
  - [ ] 1. Factory Production Floor (Assembly lines & Tier badges)
  - [ ] 2. Sales Hub & Staged Manifest Cart (Multi-product bulk tray & drawer)
  - [ ] 3. Logistics Fleet Operations (Bikes, Vans, Trucks, Planes in transit)
  - [ ] 4. Control Center Automation (Auto-Buy, Auto-Build, Auto-Sell dispatchers)
  - [ ] 5. B2B Corporate Contracts (Retail & Manufacturing requisitions with client reputation)
  - [ ] 6. R&D Lab & Tech Tree (Speed perks, material science, deconstruction bay)
  - [ ] 7. Wall Street Prestige & IPO (Golden Shares valuation & opening bell)
  - [ ] 8. 100% Offline Gameplay (Zero ads, zero data connection needed)

### 1.3 Store Listing Copywriting
- [ ] **App Title**: `Production.Inc: Factory Tycoon` ($\le$ 30 chars).
- [ ] **Short Description**: `Build, automate, and ship! Run an industrial tycoon manufacturing empire.` ($\le$ 80 chars).
- [ ] **Full Description**: Highlighting deep 4-tier factory progression, 80+ custom vector icons, corporate B2B contracts, R&D tech tree, and 100% offline single-player gameplay.

### 1.4 Git Branch Merge & Final Release Tag
- [ ] Commit all staged changes on `dev`.
- [ ] Merge `dev` branch into `main`.
- [ ] Tag git commit: `git tag -a v2.0.0 -m "Release v2.0.0 (Build 20)"`.
- [ ] Push to remote: `git push origin main --tags`.

---

## 🛡️ Part 2: Verified Compliance & Architecture Invariants

Reference table of all compliance and security standards already satisfied and enforced in the codebase:

| Compliance / Pillar Area | Status | Implementation Details |
| :--- | :---: | :--- |
| **Network & Offline Policy** | ✅ Verified | `android.permission.INTERNET` removed from main manifest. Zero HTTP sockets or WebViews. |
| **Data Safety & Collection** | ✅ Handled | **0 Data Collected**, **0 Data Shared**. 100% local SQLite (`app_database.db`) & SharedPreferences. |
| **In-App Privacy Policy** | ✅ Verified | Clickable disclosure dialog in [`SettingsScreen`](file:///lib/screens/settings_screen.dart) under *Help & Tutorial*. |
| **Public Privacy Policy URL** | ✅ Handled | Centrally hosted and linked across organization developer accounts. |
| **IARC Content Rating** | ✅ Handled | Rated **Everyone / PEGI 3 / USK 0** (no violence, gambling, or loot boxes). |
| **Target SDK Version** | ✅ Verified | `compileSdk = 36`, `targetSdk = 36`, `minSdk = 24` (exceeds Google Play API 34+ baseline). |
| **Dangerous Permissions** | ✅ Verified | **Zero** dangerous permissions (no location, camera, mic, or storage access). |
| **Debug Mode & Mods Gating** | ✅ Verified | Dev tools gated behind secret code `888888` (ephemeral session only). Verbose logging disabled. |
| **Community Discord Link** | ✅ Verified | Handled via OS external intent (`android_intent_plus`) with zero in-app networking. |

---

## 🔄 Part 3: Quarterly Maintenance & Audit Checklist

Use this section to perform recurring **Quarterly Health Checks (Q1, Q2, Q3, Q4)** to keep *Production.INC* compliant, performant, and up-to-date with Google Play requirements.

### 📅 Audit Log Tracker

| Quarter / Date | Reviewer | Dependencies Audited | Target SDK Status | Google Play Policy Audit | Status / Notes |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **Q4 2026** (Oct 2026) | Initial Baseline | Flutter 3.7+ / Dart 3 | `targetSdk = 36` (Compliant) | Data Safety & Offline verified | 🟢 v2.0 Release Ready |
| **Q1 2027** | | | | | ⚪ Scheduled |
| **Q2 2027** | | | | | ⚪ Scheduled |
| **Q3 2027** | | | | | ⚪ Scheduled |
| **Q4 2027** | | | | | ⚪ Scheduled |

---

### 📋 Quarterly Audit Action Items

#### 1. 📱 Google Play Target SDK & Android Platform Baseline
- [ ] **Check Google Play Annual Target SDK Policy**:
  - Google Play mandates updating `targetSdk` within 1 year of every major Android release (typically by August 31st each year).
  - Verify [`android/app/build.gradle.kts`](file:///android/app/build.gradle.kts) meets or exceeds Google Play's required `targetSdk`.
- [ ] **Verify Java / Gradle / Kotlin Toolchain**:
  - Run `./gradlew -v` inside `android/` to ensure Gradle and Kotlin plugins remain compatible with Android Studio releases.

#### 2. 📦 Flutter Dependencies & Security Advisory Audit
- [ ] **Check for Outdated Packages**:
  ```bash
  flutter pub outdated
  ```
  - Review non-breaking updates for key libraries: `sqflite`, `shared_preferences`, `go_router`, `provider`, `flutter_svg`, `android_intent_plus`.
- [ ] **Static Code & Lint Analysis**:
  ```bash
  dart analyze
  ```
  - Ensure zero warnings, zero deprecation notices, and zero analyzer errors.
- [ ] **Automated Test Suite Pass**:
  ```bash
  flutter test
  ```
  - Verify all 360+ tests pass (100% green).

#### 3. 🛡️ Google Play Policy & Data Safety Quarterly Sanity Check
- [ ] **Google Play Console Policy Alerts**:
  - Log in to [Google Play Console](https://play.google.com/console) and check the **Policy Status** and **App Content** tabs for any newly required forms or declarations.
- [ ] **Verify Zero-Network Invariant**:
  - Confirm no newly added plugins have introduced `android.permission.INTERNET` back into `android/app/src/main/AndroidManifest.xml`.
- [ ] **Data Safety Re-Verification**:
  - Ensure local save format has not introduced cloud telemetry or user tracking.
- [ ] **Privacy Policy URL Active Check**:
  - Confirm the public Privacy Policy URL remains reachable and active.

#### 4. 📊 Android Vitals & Quality Review (Play Console)
- [ ] **Crash Rate**: Verify user-perceived crash rate is below Google Play's bad behavior threshold ($< 1.09\%$, target $< 0.1\%$).
- [ ] **ANR Rate**: Verify Application Not Responding (ANR) rate is below the threshold ($< 0.47\%$, target $< 0.05\%$).
- [ ] **App Download Size**: Verify release AAB download size remains optimal ($\le 25\text{ MB}$).

#### 5. 💾 Database Integrity & Migration Sanity
- [ ] **Save File Backward Compatibility**:
  - Verify that upgrading from older database versions (v1 through v10) loads smoothly via `GamePersistenceService.loadGameState()`.
  - Confirm the "Repair Database" dev tool remains fully operational.

---

## 🔗 Related Documentation
- [`RELEASE_PREPARATION_AND_CLEANUP.md`](file:///RELEASE_PREPARATION_AND_CLEANUP.md) — Comprehensive technical implementation tracker for Version 2.0.
- [`ICON_DESIGN_ROADMAP.md`](file:///ICON_DESIGN_ROADMAP.md) — 80-icon master visual asset catalog and specifications.
- [`CHANGELOG.md`](file:///CHANGELOG.md) — Complete release history across Version 1.0 through 2.0.
- [`docs/context.md`](file:///docs/context.md) — Core architecture, persistence gotchas, and engineering invariants.
