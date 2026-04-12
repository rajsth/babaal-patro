# Bug Tracker

## Fixed

### [2026-04-12] Android widget date not updating without app running

**Symptom:** The home screen widget showed stale Nepali date, AD date, and day name unless the main Babaal Patro app was running in the background. Time (TextClock) was unaffected.

**Root cause:** The Android widget read date strings from SharedPreferences, which were only written by the Flutter app via `HomeWidgetUpdater.update()` on app launch. No native date computation existed — unlike the iOS widget which computes BS dates natively in Swift.

**Fix:**
- Created `NepaliCalendar.kt` — Kotlin port of the AD→BS conversion algorithm (same as iOS `NepaliCalendar` in Swift)
- Updated `NepaliDateWidget.kt` to compute dates natively via `NepaliCalendar.now()` instead of reading stale SharedPreferences
- Added `ACTION_DATE_CHANGED`, `ACTION_TIMEZONE_CHANGED`, `ACTION_TIME_CHANGED` broadcast receivers in `AndroidManifest.xml` to refresh the widget at midnight and on timezone changes
- Accent color still reads from SharedPreferences (user preference, not time-sensitive)

**Files changed:**
- `android/app/src/main/kotlin/com/babaal/patro/NepaliCalendar.kt` (new)
- `android/app/src/main/kotlin/com/babaal/patro/NepaliDateWidget.kt`
- `android/app/src/main/AndroidManifest.xml`

**iOS status:** Not affected — `NepaliDateWidget.swift` already has native `NepaliCalendar` and a 720-entry WidgetKit timeline that auto-refreshes every 12 hours.

---

### [2026-04-12] Android widget excessive height and padding

**Symptom:** Widget occupied 2 grid rows on Samsung One UI when the content only needed 1 row. Visible gaps above and below the date/time content inside the widget background.

**Root cause:**
1. No `targetCellHeight` set in widget info XML — launcher defaulted to 2 rows
2. Bottom date row anchored to `alignParentBottom` — created a gap between time section and date row when the widget was taller than needed
3. Dynamic padding calculation (`minHeightDp * 0.12f`, max 32dp) inflated padding on taller widgets

**Fix:**
- Added `targetCellHeight="1"` and `targetCellWidth="4"` to `nepali_date_widget_info.xml`
- Reduced `minHeight` from 80dp to 60dp
- Changed layout to stack top-down (`layout_below`) instead of bottom-anchoring (`alignParentBottom`)
- Reduced static padding (8dp/6dp top/bottom) and capped dynamic padding (max 16dp)

**Files changed:**
- `android/app/src/main/res/xml/nepali_date_widget_info.xml`
- `android/app/src/main/res/layout/nepali_date_widget.xml`
- `android/app/src/main/kotlin/com/babaal/patro/NepaliDateWidget.kt`
