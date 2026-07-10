Design prompt: Paramedic Triage Intake App (Flutter) — full UI flow

Context for the agent

Build the complete Flutter UI for a Paramedic Triage Intake Application — a field tool paramedics use to log critical patient data instantly, with guaranteed offline persistence. This is a technical assessment focused as much on architecture as visuals, so the UI must look production-grade: Material 3, custom theme, no default widget styling left untouched.

Visual reference attached: use it for structural language only — soft lavender/off-white background, floating white rounded cards (20–24px radius, subtle shadow), circular avatar chips, small pill-shaped status tags ("Available"/"No available" style), a search-style header pattern, and — most importantly — the horizontal row of selectable time-slot pills on the doctor-profile screen (one filled/active, rest outlined) and the info-chip row (icon + label + value, three across). Both of these map directly onto this app's needs. Do not keep the reference's purple-as-primary-everywhere mood — reserve strong color for meaning (hazard/status), not branding, since this is a clinical field tool, not a booking app.

Design system to define in ThemeData


Background: warm off-white (#F7F6F3), not stark white — reduces glare in bright field conditions
Primary neutral accent (non-critical actions, nav, focus states): a single confident indigo/blue, used sparingly
Hazard ramp (priority 1–5), same treatment as the reference's pill row:

Priority 1: deep red #D8262B
Priority 2: burnt orange #E8630A
Priority 3: amber #E8A90A
Priority 4: steel blue #3A6EA5
Priority 5: neutral gray #6B7280



Sync status colors: pending = gray, syncing = blue (animated pulse), synced = green, failed = red
Typography: google_fonts — one clean geometric sans (e.g. Inter or Manrope), bold weights reserved for numbers, priority, and status only
Card style: Card with RoundedRectangleBorder(borderRadius: 22), soft boxShadow, matching the reference's floating-card look
Minimum tap target 48dp everywhere — gloved hands, moving vehicle



Screen-by-screen spec (concise, one per file/route)

1. Login (dummy auth)


Paramedic ID + 4-digit PIN entry (numeric keypad style)
One prominent "Quick Demo Login" button — pre-fills dummy credentials, this is the primary path
Small caption under the form: "You can log triage records even without signal"


2. Home dashboard

(styled after reference screen 1 — greeting header + filter chips + card grid)


Header: "Good morning, [Paramedic name]" + notification bell + calendar icon (kept from reference, repurposed as "sync history" icon)
Persistent connectivity banner directly under the header — not a modal, not dismissible — green "Online · Synced" or amber "Offline · N pending". This is the single most important visual element in the whole app.
Filter chip row (kept from reference style): All / Pending / Synced / Failed — filters the list below
Large single primary CTA card: "New Triage Record" — dominates visually, everything else is secondary
List below: recent records as compact rows (avatar-style priority-color dot instead of doctor photo, patient name, condition snippet, sync-status pill)


3. New Triage Intake (the core graded screen)

Single scrollable form, optimized for one-thumb use under stress:


Patient Name — large text field, autofocus
Condition Description — expandable multiline field
Priority selector — built exactly like the reference's time-slot pill row: five pills in a wrap/row, each colored in its hazard tone, the selected one filled solid + slightly larger, unselected ones outlined only. Priority 1–2 pills are visually heavier (bigger, bolder number) than 3–5 to draw the eye instinctively.
Status — two-segment toggle: Pending / In-Transit (SegmentedButton in Material 3)
Inline validation text appears above the submit button in hazard red — no blocking dialogs, they cost time in the field
Sticky bottom "Submit" button — full width, disabled/grayed until valid, exactly like the reference's "Book now" button treatment


4. Submission confirmation (micro-interaction, not a screen)

A SnackBar sliding from bottom: "Saved · will sync automatically" (offline) or "Submitted" (online). Form clears immediately — next patient entry should be possible within one second, no extra tap.

5. Records queue

(styled after reference screen 2 — back arrow + title + search/filter header + list of cards)


Search bar filters by patient name
Filter icon opens sync-status filter (Pending/Syncing/Synced/Failed)
Each row: priority-color dot avatar, patient name, condition snippet, timestamp, animated sync-status pill


6. Record detail

(styled after reference screen 3 — hero header + info-chip row + detail sections)


Header: patient name large, priority pill top-right instead of a call icon
Info-chip row copied directly from the reference (icon + label + value, 3 across): repurposed as "Priority" / "Status" / "Logged at"
Sync timeline below: "Saved locally 14:02 → Synced 14:07" as a simple vertical stepper, so the paramedic can visually confirm the system worked


7. Sync & connectivity settings


Current connection type indicator
Last successful sync timestamp
Manual "Retry sync now" ElevatedButton
Auto-sync toggle switch
Pending queue count with link back to Records queue


8. Profile (minimal)

Paramedic name/ID (dummy), unit assigned, logout button. Nothing else.


Interaction notes


Screen transitions under ~200ms — this app must feel instant, use Hero sparingly and only where it earns its keep (e.g. priority color from list → detail)
Priority pill selection animates as a color fill (AnimatedContainer), not a bounce/scale gimmick — urgency, not delight
Sync-status pill changes animate in place (color morph via AnimatedSwitcher), never a full list rebuild flash
No modal dialogs except for destructive actions (discard unsaved record)


Architecture the UI must respect (do not violate)


Widgets are presentation-only. State comes from Riverpod providers (or BLoC/Provider — pick one and stay consistent) that expose a TriageRepository interface — the UI never touches SQLite or the network client directly.
Every screen above should be its own file under lib/screens/, with shared pieces (PriorityPill, SyncStatusBadge, ConnectivityBanner) extracted to lib/widgets/.


Deliverable format

Build as a connected Flutter navigation flow (go_router recommended) — Login → Home → New Record → back to Home, with Records/Settings/Profile as bottom-nav destinations. Target a 375–414dp mobile viewport, Material 3, google_fonts, theme defined once in lib/theme/app_theme.dart and referenced everywhere — no inline hardcoded colors in widgets.