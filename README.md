# EMS Triage — Paramedic Field Intake App

A production-grade Flutter application for paramedics to log critical patient triage data instantly, with guaranteed offline persistence and automatic background sync when connectivity is restored.

---

## Demo

**[Watch the full walkthrough on Loom →](https://www.loom.com/share/9bc854bebf7947d687be9495cbdc5391)**

---

## Overview

Field paramedics operate under extreme time pressure, often with gloved hands, inside moving vehicles, in poor lighting. This app is built around those constraints — every interaction is optimised for speed, every tap target meets the 48dp minimum, and no network connection is ever required to save a record.

---

## Features

- **Offline-first** — records are written to local storage immediately; sync happens in the background when a connection appears
- **Priority triage system** — 5-level START triage categories (P1 Immediate → P5 Deceased), each with a distinct hazard colour
- **Persistent connectivity banner** — always visible, never dismissible; shows online/offline state and pending queue count
- **Animated sync status** — syncing pulse, colour-morph transitions via `AnimatedSwitcher`, never a full list rebuild flash
- **Reactive state** — all screens driven by Riverpod providers; widgets are presentation-only and never touch storage or network directly
- **Cross-platform persistence** — SQLite on Android/iOS via `sqflite`; in-memory store on Web (with realistic seeded demo data)

---

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Framework | Flutter 3 / Dart 3 | Cross-platform, Material 3 support |
| State management | Riverpod 2 (`flutter_riverpod`) | Compile-safe, testable, no BuildContext required in logic |
| Navigation | go_router 14 | Declarative, URL-based, shell routes for bottom nav |
| Local persistence | sqflite (mobile) / in-memory (web) | SQLite is reliable offline; web fallback for demo |
| Fonts | google_fonts — Manrope | Clean geometric sans, excellent legibility at small sizes |
| Connectivity | connectivity_plus | Stream-based network state |
| IDs | uuid v4 | Collision-safe offline record identifiers |

---

## Architecture

```
lib/
├── main.dart                  # App entry point, ProviderScope, theme wiring
├── theme/
│   └── app_theme.dart         # ThemeData, AppColors, PriorityColors, AppShadows
├── models/
│   └── triage_record.dart     # TriageRecord, TriageStatus, SyncStatus, RecordsFilter
├── repositories/
│   ├── triage_repository.dart           # Abstract interface
│   ├── local_triage_repository.dart     # SQLite implementation (mobile)
│   └── in_memory_triage_repository.dart # In-memory implementation (web/demo)
├── providers/
│   └── providers.dart         # All Riverpod providers (auth, records, sync, form)
├── router/
│   └── app_router.dart        # GoRouter setup with RouterNotifier bridge
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── new_record_screen.dart
│   ├── records_screen.dart
│   ├── record_detail_screen.dart
│   ├── settings_screen.dart
│   ├── profile_screen.dart
│   └── shell_scaffold.dart    # Bottom nav shell
└── widgets/
    ├── priority_pill.dart       # Selectable hazard-colour pill + dot + badge
    ├── sync_status_badge.dart   # Animated sync status pill
    ├── connectivity_banner.dart # Persistent online/offline banner
    ├── app_card.dart            # Floating card + InfoChip
    └── record_list_tile.dart    # Compact record row with priority dot
```

### Key architectural decisions

**Repository pattern** — the `TriageRepository` interface means the UI never calls SQLite or any network client directly. Swapping the backend (e.g. adding a real REST sync client) requires no widget changes.

**RouterNotifier bridge** — GoRouter's `refreshListenable` is wired to a `ChangeNotifier` that listens to `authProvider` via `ref.listen`. This avoids the Riverpod assertion that fires when `ref.read` is called inside a redirect callback during a rebuild cycle.

**Riverpod over BLoC** — providers are co-located with the logic they own, no boilerplate event/state classes, and `ref.listen` makes cross-provider reactions (e.g. auto-sync on connectivity change) concise.

---

## Design System

Defined once in `lib/theme/app_theme.dart`, referenced everywhere — no inline hardcoded colours in widgets.

| Token | Value | Usage |
|---|---|---|
| Background | `#F7F6F3` | Warm off-white, reduces glare in field |
| Primary | `#3D5AFE` | Indigo — navigation, focus, CTA only |
| Priority 1 | `#D8262B` | Immediate — deep red |
| Priority 2 | `#E8630A` | Delayed — burnt orange |
| Priority 3 | `#E8A90A` | Minimal — amber |
| Priority 4 | `#3A6EA5` | Expectant — steel blue |
| Priority 5 | `#6B7280` | Deceased — neutral grey |
| Sync Synced | `#16A34A` | Green |
| Sync Failed | `#D8262B` | Red |
| Sync Syncing | `#3D5AFE` | Blue (animated pulse) |

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.5.0
- Dart SDK ≥ 3.5.0

### Install & run

```bash
# Clone
git clone <repo-url>
cd ems_mobile_app

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Run on Chrome (uses in-memory store, no SQLite required)
flutter run -d chrome
```

### Quick demo

Tap **Quick Demo Login** on the login screen. It pre-fills `EMS-001 / 1234` and logs you in instantly. The home screen will be pre-populated with realistic demo records covering all priority levels and sync states.

---

## Navigation Flow

```
/login
  └── /home  (bottom nav shell)
        ├── /records
        │     └── /records/:id
        ├── /settings
        └── /profile
/new-record  (full-screen modal, no bottom nav)
```

---

## Testing

**85 tests, all passing.** Run the full suite with:

```bash
flutter test
```

Tests are pure Dart unit tests — no device or emulator required.

### Test files

| File | Tests | What's covered |
|---|---|---|
| `test/models/triage_record_test.dart` | 24 | Model construction, `copyWith`, serialization round-trips, equality, `RecordsFilter` labels |
| `test/repositories/in_memory_triage_repository_test.dart` | 18 | Save, retrieve, upsert, delete, pending queue ordering, reactive stream emissions |
| `test/providers/auth_notifier_test.dart` | 21 | Initial state, `login()` valid/invalid paths, `quickDemoLogin()`, `logout()` |
| `test/providers/new_record_form_test.dart` | 22 | Field updates, `isValid` gate, validation error messages, successful submit, whitespace trimming, form reset |

### Coverage highlights

**`TriageRecord` model**
- Priority boundary assertions — `0` and `6` throw, `1`–`5` are valid
- Full SQLite serialization round-trip for all field types, including nullable `syncedAt` and `failureReason`
- Graceful enum fallback for unknown values read from the database
- All 5 priority levels, all `SyncStatus` and `TriageStatus` variants survive round-trip
- Equality is id-based; `hashCode` is consistent; records are safe as map keys

**`InMemoryTriageRepository`**
- `getAllRecords` always returns newest-first
- `saveRecord` with a duplicate id replaces rather than duplicates
- `getPendingRecords` returns only `pending` and `failed` records, ordered oldest-first (critical for sync ordering)
- `watchAllRecords` stream emits a fresh snapshot after every mutation
- Deleting a non-existent id does not throw

**`AuthNotifier`**
- Any non-empty id with exactly a 4-digit PIN is accepted (dummy auth contract)
- PIN length validation: 3 digits → rejected, 4 → accepted, 5 → rejected
- `EMS-001` and `EMS-002` resolve to known display names; all other IDs get a generated name
- `logout()` is safe to call when already unauthenticated

**`NewRecordFormNotifier`**
- `isValid` is `false` until all three required fields are non-empty and non-whitespace
- Updating any field clears the active `validationError`
- Each missing field produces a distinct, specific error message
- Submitted record is correctly persisted to the repository with the right priority and sync status
- Patient name and condition are trimmed of leading/trailing whitespace before saving
- Form fully resets after a successful submit (ready for next patient within one second)

---

## Roadmap / Production Hardening

The following are out of scope for this assessment but required before a real deployment:

- [ ] Real HTTP sync client (replace the simulated delay in `SyncNotifier`)
- [ ] Biometric / secure PIN storage (replace dummy auth)
- [ ] Background sync service (WorkManager on Android, BGTaskScheduler on iOS)
- [ ] End-to-end encryption for records at rest and in transit
- [ ] Crash reporting (Sentry / Firebase Crashlytics)

---

## License

MIT
