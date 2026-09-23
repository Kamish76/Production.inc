# 📚 Production.Inc — Master Documentation Index

Welcome to the central documentation hub for **Production.Inc**. This index provides direct access to all active technical specifications, developer guidelines, and chronological sprint archives.

---

## ⚡ Active Living Documentation

These core documents reflect the current architecture, coding conventions, and setup requirements for the active codebase.

| Category | Document | Description |
| :--- | :--- | :--- |
| **API Reference** | **[`API_DOCUMENTATION.md`](API_DOCUMENTATION.md)** | Service definitions, method signatures, game state mutations, and telemetry API reference. |
| **Database & Persistence** | **[`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md)** | SQLite tables, schema migrations (`onUpgrade`), foreign keys, and persistence service architecture. |
| **Developer Guide** | **[`DEVELOPMENT_GUIDE.md`](DEVELOPMENT_GUIDE.md)** | Contribution standards, project architecture, code styling, and best practices. |
| **UI Architecture** | **[`WIDGET_STRUCTURE.md`](WIDGET_STRUCTURE.md)** | Screen hierarchies, reusable components, design tokens, and theme standards. |
| **Testing Setup** | **[`TESTING_SETUP.md`](TESTING_SETUP.md)** | Guidelines for writing and running unit tests, widget tests, and integration scenarios. |
| **Version Management** | **[`VERSION_MANAGEMENT.md`](VERSION_MANAGEMENT.md)** | Versioning policy, release lifecycle, and deployment checklists. |

---

## 🚀 Active Roadmap & Sprint Tracking (Project Root)

For active feature work and real-time development context, reference these root files:

- **[`FUTURE_PLANS.md`](../FUTURE_PLANS.md)**: Master architecture roadmap detailing completed Phases 1–5 and planned Phases 6–7.
- **[`TODO_SEP_23.md`](../TODO_SEP_23.md)**: Granular task backlog and execution checklist for upcoming releases.
- **[`context.md`](../context.md)**: Architectural invariants, memory constraints, and core game patterns.
- **[`README.md`](../README.md)**: Main repository overview and player feature summary.
- **[`CHANGELOG.md`](../CHANGELOG.md)**: Detailed historical release notes across all versions.

---

## 🗄️ Chronological Sprint Archives (`docs/sprints/`)

Historical documentation, feature proposals, and postmortems organized by development sprint:

### [Sprint 1: Legacy Foundation & Early Development (v1.0 – v1.4)](sprints/01_legacy_v1.0-v1.4/README.md)
*August 2025 & Earlier*
- **[`Concept.txt`](sprints/01_legacy_v1.0-v1.4/Concept.txt)**: Initial game concept and pitch.
- **[`game economy.txt`](sprints/01_legacy_v1.0-v1.4/game%20economy.txt)**: Early material costs, crafting requirements, and economy formulas.
- **[`Store listing.txt`](sprints/01_legacy_v1.0-v1.4/Store%20listing.txt)**: Play Store listing draft and product positioning.
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
- **Bug Fixes Archive**: [`bug_fixes/`](sprints/03_automation_v1.5/bug_fixes/) (9 detailed postmortems and reports covering material leaks, database migrations, and unlock display synchronization).

### [Sprint 4: Version 2.0 Major Update (Phases 1–7)](sprints/04_v2.0_major_update/README.md)
*September 23, 2026 – Present*
- Master architectural documentation for the **v2.0 Major Update**, covering completed **Phases 1–5** (Factory Tiers, B2B Logistics, Industry Branches, R&D Lab, Prestige/IPO) and active release finalization in **Phases 6–7** (Ergonomics Polish & Automation Dynamic Scaling).

---

## 🧭 Navigation & Maintenance Guide

1. **Working on Code**: Start with [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) and [API_DOCUMENTATION.md](API_DOCUMENTATION.md).
2. **Database Modifications**: Consult [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) and ensure migration invariants in `.agents/rules/production_inc_context.md` are upheld.
3. **Historical Context**: Explore the relevant sprint folder in `sprints/` for design decisions and past investigations.
