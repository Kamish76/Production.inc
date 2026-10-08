# 📚 Production.Inc — Master Documentation Index

Welcome to the central documentation hub for **Production.Inc**. This index provides direct access to all active technical specifications, developer guidelines, and chronological sprint archives.

---

## ⚡ Active Living Documentation

These core documents reflect the current architecture, coding conventions, and setup requirements for the active codebase.

| Category | Document | Description |
| :--- | :--- | :--- |
| **Developer & Agent Guide** | **[`context.md`](context.md)** | Single source of truth for architecture invariants, memory constraints, and core patterns. |
| **Developer Guidelines** | **[`DEVELOPMENT_GUIDE.md`](DEVELOPMENT_GUIDE.md)** | Contribution standards, project architecture, code styling, and best practices. |
| **API Reference** | **[`API_DOCUMENTATION.md`](API_DOCUMENTATION.md)** | Service definitions, method signatures, game state mutations, and telemetry API reference. |
| **Database & Persistence** | **[`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md)** | SQLite tables, schema migrations (`onUpgrade` v1–v13), foreign keys, and persistence architecture. |
| **UI Architecture** | **[`WIDGET_STRUCTURE.md`](WIDGET_STRUCTURE.md)** | Screen hierarchies, reusable components, design tokens, and theme standards. |
| **Testing Setup** | **[`TESTING_SETUP.md`](TESTING_SETUP.md)** | Guidelines for writing and running unit tests, widget tests, and integration scenarios. |
| **Version Management** | **[`VERSION_MANAGEMENT.md`](VERSION_MANAGEMENT.md)** | Versioning policy, release lifecycle, and deployment checklists. |

---

## 🚀 Active Project Root Files

For quick access at the repository root:

- **[`CHECKLIST.md`](../CHECKLIST.md)**: Master release deliverables and recurring **quarterly maintenance & audit checklist**.
- **[`RELEASE_PREPARATION_AND_CLEANUP.md`](../RELEASE_PREPARATION_AND_CLEANUP.md)**: Technical tracker for Google Play release prep, asset integration, and sanitization.
- **[`ICON_DESIGN_ROADMAP.md`](../ICON_DESIGN_ROADMAP.md)**: 80-icon master visual design and integration roadmap (80/80 Complete).
- **[`README.md`](../README.md)**: Main repository overview, gameplay mechanics, and technical architecture for **Version 2.0.0**.
- **[`CHANGELOG.md`](../CHANGELOG.md)**: Detailed historical release notes across all versions through **v2.0.0**.
- **[`pubspec.yaml`](../pubspec.yaml)**: Project dependencies, asset registrations, and build version (`2.0.0+20`).

---

## 🗄️ Chronological Sprint Archives (`docs/sprints/`)

Historical documentation, feature proposals, and postmortems organized by development sprint:

### [Sprint 1: Legacy Foundation & Early Development (v1.0 – v1.4)](sprints/01_legacy_v1.0-v1.4/README.md)
*August 2025 & Earlier*
- **[`Concept.txt`](sprints/01_legacy_v1.0-v1.4/Concept.txt)**: Initial game concept and pitch.
- **[`game economy.txt`](sprints/01_legacy_v1.0-v1.4/game%20economy.txt)**: Early material costs, crafting requirements, and economy formulas.
- **[`Store listing.txt`](sprints/01_legacy_v1.0-v1.4/Store%20listing.txt)**: Play Store listing draft and product positioning.
- **[`README_production.md`](sprints/01_legacy_v1.0-v1.4/README_production.md)**: Legacy v1.4.19 project overview.
- **[`release_notes/`](sprints/01_legacy_v1.0-v1.4/release_notes/)**: Early release notes.
- **[`version_documentation/`](sprints/01_legacy_v1.0-v1.4/version_documentation/)**: Detailed logs for v1.2, v1.3, v1.4, and v1.5 draft concepts.

### [Sprint 2: Architecture Decomposition & Industry Standards (v1.4)](sprints/02_standards_refactoring_v1.4/README.md)
*October 8–9, 2025*
- **Audits & Metrics**: [`INDUSTRY_STANDARDS_REPORT.md`](sprints/02_standards_refactoring_v1.4/INDUSTRY_STANDARDS_REPORT.md), [`TODO_INDUSTRY_STANDARDS.md`](sprints/02_standards_refactoring_v1.4/TODO_INDUSTRY_STANDARDS.md), [`REFACTORING_SUMMARY.md`](sprints/02_standards_refactoring_v1.4/REFACTORING_SUMMARY.md).
- **Consolidation Reports**: [`COMPLETE_WIDGET_CONSOLIDATION_SUCCESS.md`](sprints/02_standards_refactoring_v1.4/COMPLETE_WIDGET_CONSOLIDATION_SUCCESS.md), [`ITEM_CARD_CONSOLIDATION_SUCCESS.md`](sprints/02_standards_refactoring_v1.4/ITEM_CARD_CONSOLIDATION_SUCCESS.md), [`WIDGET_CONSOLIDATION_SUCCESS.md`](sprints/02_standards_refactoring_v1.4/WIDGET_CONSOLIDATION_SUCCESS.md).
- **Screen Decomposition**: [`BUY_MATERIALS_DECOMPOSITION_SUCCESS.md`](sprints/02_standards_refactoring_v1.4/BUY_MATERIALS_DECOMPOSITION_SUCCESS.md), [`TIER_EXPANSION_SUCCESS.md`](sprints/02_standards_refactoring_v1.4/TIER_EXPANSION_SUCCESS.md).

### [Sprint 3: Automation System, Control Screen & Quality Hardening (v1.5)](sprints/03_automation_v1.5/README.md)
*October 10–11, 2025*
- **Specifications & Releases**: [`V.1.5.md`](sprints/03_automation_v1.5/V.1.5.md), [`QUICK_SUMMARY.md`](sprints/03_automation_v1.5/QUICK_SUMMARY.md), [`GOOGLE_PLAY_BETA_RELEASE_NOTES.md`](sprints/03_automation_v1.5/GOOGLE_PLAY_BETA_RELEASE_NOTES.md), [`PRE_RELEASE_CHECKLIST.md`](sprints/03_automation_v1.5/PRE_RELEASE_CHECKLIST.md).
- **Automation & Design**: [`automation/`](sprints/03_automation_v1.5/automation/) (Auto-Buy & Auto-Build logic), [`design_notes/`](sprints/03_automation_v1.5/design_notes/) (Control Screen wireframes & ideas).
- **Implementations**: [`CONTROL_SCREEN_SPLIT_IMPLEMENTATION.md`](sprints/03_automation_v1.5/CONTROL_SCREEN_SPLIT_IMPLEMENTATION.md), [`BUILD_SPEED_MINIMUM_FLOOR.md`](sprints/03_automation_v1.5/BUILD_SPEED_MINIMUM_FLOOR.md), [`UNLOCK_PERSISTENCE.md`](sprints/03_automation_v1.5/UNLOCK_PERSISTENCE.md).
- **Bug Fixes Archive**: [`bug_fixes/`](sprints/03_automation_v1.5/bug_fixes/) (9 detailed postmortems covering material leaks, database migrations, and unlock display synchronization).

### [Sprint 4: Version 2.0 Major Update (Phases 1–12 Completed & Verified)](sprints/04_v2.0_major_update/README.md)
*September 23, 2026 – September 27, 2026*
- **[`TODO_SEP_23.md`](sprints/04_v2.0_major_update/TODO_SEP_23.md)**: Sprint task backlog, implementation specifications, and completion records for Phases 6 through 12.
- **[`FUTURE_PLANS.md`](sprints/04_v2.0_major_update/FUTURE_PLANS.md)**: Master architectural blueprint detailing the 12-phase lifecycle and technical foundations.
- **[`PHASE12_VERIFICATION_RESULTS.md`](sprints/04_v2.0_major_update/PHASE12_VERIFICATION_RESULTS.md)**: Final verification results report, test scorecard (314/314 green), and harmonization matrix.
- **[`ICON_DESIGN_ROADMAP.md`](sprints/04_v2.0_major_update/ICON_DESIGN_ROADMAP.md)**: Icon design roadmap and batch production guide for all game assets.
- **[`RELEASE_PREPARATION_AND_CLEANUP.md`](../RELEASE_PREPARATION_AND_CLEANUP.md)**: Master release readiness checklist, secret redeem code system (`888888`), settings lazy loading, developer cleanup, icon integration, and Google Play Console release preparation.

---

## 🧭 Navigation & Maintenance Guide

1. **Working on Code**: Start with [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) and [context.md](context.md).
2. **Database Modifications**: Consult [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) and ensure migration invariants in `.agents/rules/production_inc_context.md` are upheld.
3. **Historical Context**: Explore the relevant sprint folder in `sprints/` for design decisions and past investigations.
