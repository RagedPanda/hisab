# Hisab — Architecture, Feature Plan and Sync Design

## Goals
Free, ad-free, open-source expense tracker for Android and iOS with:
multi-item entries, a broad category catalogue, on-device bank SMS parsing (Android),
Splitwise-style groups, budgets, encrypted backup and (next) encrypted cloud sync.

## Stack
| Layer | Choice | Why |
|---|---|---|
| UI | Flutter 3.47, Material 3, light + dark via `ThemeMode` | One codebase, native performance on both platforms, built-in dark mode |
| State | Riverpod 3 | Compile-safe providers, stream-friendly, testable without widgets |
| Navigation | go_router with `StatefulShellRoute` | Bottom tabs keep state; deep links (`hisab://`) for free |
| Storage | Drift (SQLite) | Reactive queries, typed schema, migrations |
| Charts | fl_chart | Pure Dart, no platform views |
| Crypto | `cryptography` (AES-256-GCM, PBKDF2) | Pure Dart, same bytes on both platforms |

## Code layout
```
lib/core        money, dates, ids, theme, icons, settings, providers
lib/domain      pure logic, no Flutter: split calculator, debt simplifier, SMS parser,
                categorizer, category catalogue, budget math, backup codec   (unit-tested)
lib/data        Drift schema, repositories, SMS ingest, backup service
lib/features    one folder per screen: dashboard, transactions, expense_editor,
                categories, groups, split, sms, budgets, accounts, settings, shell
android/.../MainActivity.kt   SMS inbox + live receiver platform channel
```
Rule: anything that can be a pure function lives in `lib/domain` with a test.

## Data model (all tables carry `updatedAt` + `deletedAt` for sync)
- **accounts** bank / card / wallet / cash, `smsKey` (bank:ac:1234) links SMS to an account
- **categories** seeded from `category_catalog.dart` (18 expense groups, 100+ subcategories,
  13 income, 5 transfer); user-editable; `units` per category for item entry
- **entries** expense / income / transfer; `source` manual | sms | import; optional `groupId`
- **entry_items** name, quantity, unit, unit price → remembered-item suggestions per category
- **groups, members, splits, settlements** Splitwise model; balances computed, never stored
- **entry_payers** who paid what when several members paid one group expense; empty for a
  single payer, and `entries.paidByMemberId` keeps the biggest payer as the main one
- **reminders** generic reminder log (kind, group, member, channel, sent time); settle-up
  reminders use it today
- **group_activities** append-only log of who added, edited, deleted or restored which group
  expense or payment, and when, with JSON snapshots of the state before and after; it backs
  the activity feeds and restoring a deleted expense with its exact split and payer rows
- **budgets** overall or per category, monthly
- **sms_log** every parsed SMS with status pending | added | ignored | skipped (dedupe by hash)

## Feature matrix vs references
| Feature | Hisab | FinArt | Walnut/Axio | Splitwise | Money Manager |
|---|---|---|---|---|---|
| Free, no trial, no ads | ✅ | ❌ (trial) | ❌ | partial | ads |
| Multi-item entries with qty/unit/price + memory | ✅ | ❌ | ❌ | ❌ | ❌ |
| 100+ categories, editable, archivable | ✅ | ✅ | ✅ | ❌ | ✅ |
| SMS auto-tracking, on-device | ✅ Android | ✅ | ✅ | ❌ | partial |
| Review inbox before adding | ✅ | ✅ | ✅ | – | – |
| Balance from bank SMS | ✅ | ✅ | ✅ | – | – |
| Groups: equal / exact / % / shares / adjustment / by item | ✅ | ❌ | partial | ✅ | ❌ |
| Simplify debts | ✅ | – | – | ✅ | – |
| Budgets with pace indicator | ✅ | ✅ | ✅ | – | ✅ |
| Salary-month cycle | ✅ | ❌ | ❌ | – | ✅ |
| Encrypted backup | ✅ | ❌ | ❌ | – | plain |
| iOS SMS workaround (Shortcut → URL) | ✅ | ❌ | ❌ | – | – |
| Works offline, no account | ✅ | ❌ | ❌ | ❌ | ✅ |

## SMS pipeline
1. `SmsChannel.readInbox(since)` (Android) or pasted/Shortcut text (any platform)
2. `looksLikeBankSender` + financial-keyword gate drops personal/promo SMS before storage
3. `parseBankSms` → amount, direction, instrument, account, balance, counterparty, reference
4. `suggestCategoryKey` keyword rules → category
5. Account auto-created from `accountKey`; reported balance applied if newer
6. `SmsLog` row: pending (review inbox) or added (auto-add on)
7. Manual entries adjust account balance; SMS entries do not (bank already reported it)

## Sync plan (next milestone)
**Principle:** the server never sees plaintext. Reuse `backup_codec` (AES-256-GCM, key from
passphrase via PBKDF2, 200k iterations). Key is held in the platform keystore.

### Personal data (entries, accounts, budgets, categories)
- Android: Google Drive `appDataFolder` (`drive.appdata` scope, hidden from the user's Drive,
  deleted with the app). Sign in with `google_sign_in`.
- iOS: CloudKit private database (`cloud_kit` / `icloud_storage`), no sign-in UI needed.
- Format: one encrypted blob per table per device plus a change log of rows since the last
  push (`updatedAt > lastSync`). Merge rule: last-writer-wins by `updatedAt`, tombstones via
  `deletedAt`. This is exactly what `BackupService.importSnapshot` already does.
- Cross-platform: a user moving Android → iOS restores from an encrypted backup file;
  Drive ↔ iCloud bridging is out of scope.

### Shared groups (the Splitwise part)
Groups need a relay both members can reach regardless of platform:
- Free tier of Firebase Firestore or Supabase. Each group has a random 256-bit group key,
  exchanged out-of-band through the invite link (`hisab:///join?g=<id>&k=<key>`), so the relay
  stores only ciphertext.
- Every group entry / split / payer / item assignment / settlement is pushed as an encrypted
  row keyed by UUID with `updatedAt`; clients merge with LWW. Conflicts are rare (one editor
  per expense). An expense travels as one unit: the entry row plus its `entry_payers` rows
  (several payers) and, for a by-item split, its item rows and their member assignments, so
  a client never applies the payers or assignments of one version against the total of
  another. Split rows are recomputed from the entry's method on the client.
- Activity rows are append-only and never edited, so they merge by plain union; each names
  its actor member, so a synced feed reads "Rahul edited Dinner" on the other phone.
- Members without the app see a read-only web summary generated from the share text.
- Identity: anonymous Firebase auth bound to the device; the member record holds a display
  name. No phone number or contacts upload.

### Order of work
1. Settings → "Connect Google / iCloud" → upload encrypted backup nightly (one blob).
2. Incremental row sync for personal data.
3. Group relay with invite links.

## Reference-app learnings applied
Full study in [REFERENCE_APPS.md](REFERENCE_APPS.md). Already in the app:
- Dashboard leads with "spent this month" and account balances (FinArt, Walnut).
- Review inbox with Add / Edit / Ignore per SMS (FinArt) behind a PennyWise-style disclosure.
- Day-grouped entries list with day totals (Money Manager).
- Six split methods and settle-up suggestions with "record payment" (Splitwise), by-item assignment (Cashew).
- Salary-month start day (Money Manager, Axio).
- No login, no paywall, works offline (the opposite of axio and Splitwise).

## Still to do
- Recurring entries and reminders
- CSV / PDF statement import
- Home-screen widget and quick-add notification
- Receipt photos (needs camera permission; deliberately deferred)
- Cloud sync as above
- Hindi and Spanish dictionaries (framework ready, see LOCALIZATION.md)
- Calculator keypad, save-and-add-another, merchant autocomplete, smart rules (see REFERENCE_APPS.md backlog)
