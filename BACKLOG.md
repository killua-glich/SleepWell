# Backlog

## Ideas

- [x] Custom fall-asleep time — user sets how long it takes them to fall asleep (replaces hardcoded default)
- [x] Reverse mode / Sleep Now — "I'm going to sleep now, when should I wake up?" calculates optimal alarm times from current time
- [x] Take a Nap mode — power nap (20 min) and recovery nap (90 min) options calculated from current time
- [x] Default wake-up time — user sets a persistent wake-up target used for recommendations
- [x] Wake-up schedule — separate defaults for weekdays vs weekends
- [x] Custom alarm name — default alarm label configurable in Settings
- [x] Delete all alarms — destructive button in Settings to cancel all scheduled AlarmKit alarms
- [x] Widget — home screen widget showing recommended sleep time based on default wake-up schedule
- [ ] HealthKit / Apple Watch integration — read actual sleep onset data to auto-adapt the fall-asleep time setting
- [x] Siri Shortcuts — "Hey Siri, when should I go to sleep tonight?" returns recommended bedtime based on default wake-up schedule
- [x] Live Activities / Dynamic Island — countdown to bedtime on lock screen and Dynamic Island
- [x] Sleep At mode — after selecting a bedtime, starts a silent countdown; notification when 3h left; Live Activity countdown kicks in at 1h left
- [x] Accessibility — VoiceOver labels, Dynamic Type support, sufficient color contrast audit

## Pre-release

_Status: Planned_
_Goal: Tasks required before App Store submission_

- [ ] Request AlarmKit managed capability (`com.apple.developer.alarmkit`) via Apple Developer Portal → App ID → Capability Requests (~€100 Apple Developer fee)
- [ ] Localization — wrap all hardcoded UI strings, add language targets, export/import `.xliff` for translation

---
_Last updated: 2026-05-22_ (live activities, bedtime countdown, Manager tab, bedtime reminder flow)
