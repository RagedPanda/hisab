# Hisab — Permissions and Store Approvals

This file lists every permission Hisab requests on each platform, why it needs it,
the exact user-facing wording, and what the stores require for approval. It also
lists the permissions used by comparable apps so reviewers can see Hisab asks for
the same or less.

Last reviewed: 2026-10-28.

## 1. Permissions Hisab uses

### Android (`android/app/src/main/AndroidManifest.xml`)

| Permission | Type | When requested | Why | Can the user refuse? |
|---|---|---|---|---|
| `android.permission.READ_SMS` | Runtime, **restricted by Play policy** | Only after the user turns on *Settings → Bank SMS* and accepts the in-app disclosure dialog | Scan the inbox for bank / UPI / card alerts to log transactions and show account balances. Processing is fully on-device; no SMS text ever leaves the phone. OTPs, promotions and personal messages are ignored by the parser and never stored. | Yes. The app works fully with manual entry, paste, or CSV. The toggle is off by default. |
| `android.permission.RECEIVE_SMS` | Runtime, **restricted by Play policy** | Same opt-in as above (granted together under the SMS group) | Catch new bank alerts in real time while the app is open so the review inbox stays current. | Yes, same as above. |
| `android.permission.INTERNET` | Normal (no prompt) | Never prompts | Only for the opt-in *Settings → Back up to Google Drive*: reaching Google sign-in and the user's own Drive `appDataFolder`. Nothing else uses the network, and the app never contacts a Hisab server (there is none). Also used by debug hot-reload. | N/A. Hisab works fully offline; without connecting Drive nothing is sent. |
| `android.permission.USE_BIOMETRIC` | Normal (no prompt) | Never prompts | Only for the opt-in *Settings → App lock*: shows the system fingerprint / face prompt (with the device PIN, pattern or password as the fallback). Hisab never sees the fingerprint or face; the system only answers "unlocked" or not. Declared by `local_auth`. | N/A. App lock is off by default. |

No other permissions are declared. Hisab does **not** request contacts, location, camera,
microphone, phone state, call log, accessibility, notification access, or storage.
File export/import uses the system document picker and share sheet, which need no permission.

### iOS (`ios/Runner/Info.plist`)

iOS does not let third-party apps read SMS, so Hisab requests **no** privacy-sensitive
permissions on iOS. The only `NS*UsageDescription` key is `NSFaceIDUsageDescription`, which iOS
shows the first time the user turns on the opt-in *Settings → App lock*.

| Capability | Why |
|---|---|
| Custom URL scheme `hisab://` | Lets a Shortcuts automation ("When I get a message containing 'debited' → Open URL `hisab:///sms?text=[Message]`") hand a bank SMS to Hisab. The user builds the automation themselves; Hisab never reads Messages. |
| Document picker / share sheet | Encrypted backup export and restore. No permission prompt. |

### Google account access (Drive backup)

Not an OS permission: an OAuth scope the user grants on Google's own screen, only after
tapping *Settings → Back up to Google Drive* and then *Connect Google Drive* on Hisab's consent
screen. Never asked at launch.

| Scope | When requested | Why | Can the user refuse? |
|---|---|---|---|
| `https://www.googleapis.com/auth/drive.appdata` | On *Connect Google Drive*, and again by Google only if the grant has lapsed | Store and read **one encrypted backup file** in the hidden, per-app `appDataFolder` of the user's own Drive (`hisab-backup.hisab`). The file is AES-256-GCM ciphertext from the same codec as the export file; neither Google nor the developer can read it. Hisab cannot see any other Drive file. | Yes. *Skip for now* is as prominent as *Connect*; the app works the same without it. *Disconnect* revokes access, *Delete Drive copy* removes the file. |

Hisab never requests `https://www.googleapis.com/auth/drive` (full Drive access). Shared groups
(not shipped yet) will add `drive.file`, which only reaches files Hisab created. No Firebase, no
`google-services.json`, no client secret: the app holds only the Web OAuth client ID, which is
not a secret (`lib/data/backup/drive_account.dart`). Setup is in
[GOOGLE_CLOUD_SETUP.md](GOOGLE_CLOUD_SETUP.md).

**Consent screen wording** (shown before Google's own screen; English below, Hindi ships with it
in `lib/l10n/app_hi.arb`, keys `driveConsent*`):

> **Back up & sync with Google Drive** — *optional*
>
> Hisab works fully offline. Your data stays on this phone and nothing is ever sent anywhere —
> unless you turn this on.
>
> Turn on Drive sync and Hisab keeps an encrypted copy of your data in your own Google Drive, so
> you can restore everything if you lose or change your phone, and share a group with friends
> and family.
>
> **Why Hisab asks for Drive access:** only to read and write its own files in your Drive.
> - It cannot see your photos, documents, or anything else in your Drive.
> - The data is encrypted — Google can't read it, and neither can we. There is no Hisab server.
> - You can turn this off and disconnect any time, and delete the Drive copy with one tap.
>
> Don't want it? Just skip this — Hisab works exactly the same without it.
>
> `Skip for now` · `Connect Google Drive`

The Settings row repeats the short why line: *"Optional. An encrypted copy in your own Drive;
Hisab can only see its own files."*

Planned (not yet shipped): iCloud key-value / CloudKit container for sync. This will add the
iCloud entitlement, which Apple approves as part of the normal review.

## 2. Google Play — SMS permission declaration

READ_SMS / RECEIVE_SMS are in Play's *Restricted Permissions* list. Hisab qualifies under the
documented exception **"SMS-based financial transaction tracking (money management)"**. When
submitting, complete the **Permissions Declaration Form** in Play Console with the text below.

**Core functionality:** Personal expense tracker. Reading bank transaction SMS is a core
feature: it is how the app discovers debits, credits and balances without manual typing.

**Declaration text (copy into the form):**

> Hisab is a personal finance / expense tracking app. With the user's explicit opt-in
> (Settings → Bank SMS → Allow), it reads SMS alerts sent by banks, card issuers and UPI
> apps to automatically record transactions and show account balances. Parsing happens
> entirely on the device; SMS content is never transmitted to any server. Only messages
> that parse as a financial transaction are stored, and only the parsed fields plus the
> originating alert for the user's reference. OTP, promotional and personal messages are
> discarded immediately. The feature is off by default and can be disabled at any time,
> after which the app continues to work with manual entry. This use falls under the
> "SMS-based financial transaction tracking" exception.

**Prominent disclosure (already implemented in-app, shown before the OS prompt):**

> Read bank SMS? Hisab reads SMS from your bank and UPI apps to log transactions and show
> account balances. Messages are processed on this device only and never uploaded. OTPs and
> promotional SMS are ignored. You can turn this off any time.

**Checklist for the Play submission**
- [ ] Privacy policy URL published; it must mention SMS reading, on-device processing and no sharing.
- [ ] Data safety form: "Messages → SMS" collected, processed ephemerally / stored on device, not shared, user can request deletion (uninstall or Settings → Bank SMS off).
- [ ] Record a short video showing the opt-in flow for the reviewer (Play often asks for it).
- [ ] Declaration form filled with the text above; category "Finance".
- [ ] Keep a build flavour without SMS permissions ready (`--dart-define=HISAB_NO_SMS=true` plus a manifest without the two lines) in case the review is refused; the app is fully usable without SMS.

**Fallback if SMS is refused:** replace SMS reading with a `NotificationListenerService`
(permission *Notification access*, not restricted by Play) that reads bank app notifications.
The parser is the same; only the input source changes.

## 3. Apple App Store

No restricted capabilities. Standard review notes:
- Category: Finance. Mention that the app does not read Messages; the user can optionally
  forward alerts through their own Shortcut.
- App Privacy: "Data not collected" for the current version (everything stays on device).
- When iCloud sync ships, declare "Financial Info" as *collected, linked to the user, not used
  for tracking*, stored in the user's private CloudKit database.

## 4. Reference apps and the permissions they ask for

Compiled from the public Play Store "App permissions" sections (October 2026). Treat it as a
comparison aid and re-check the live listing before quoting it in a submission; permissions
change between releases. Hisab does not reuse any code or assets from these apps.

| App (package) | SMS | Notification access | Contacts | Location | Camera / Storage | Network | Notes |
|---|---|---|---|---|---|---|---|
| FinArt (`com.finart`) | READ_SMS, RECEIVE_SMS | Yes (fallback) | No | No | Storage for export | Yes | 5-day trial then paid; SMS declared under money-management exception |
| Walnut / Axio (`com.daamitt.walnut.app`) | READ_SMS, RECEIVE_SMS | Yes | READ_CONTACTS (split) | Coarse (ATM finder) | Camera (bills) | Yes | Account required |
| Money Manager (`com.realbyteapps.moneymanagerfree`) | READ_SMS (optional) | Yes | No | No | Storage (backup) | Yes (ads) | Manual-first app |
| Splitwise (`com.Splitwise.SplitwiseMobile`) | No | No | READ_CONTACTS | No | Camera (receipts) | Yes | Groups need an account |
| Pennywise / similar SMS trackers | READ_SMS, RECEIVE_SMS | Yes | No | No | No | Yes | |
| Money View (`com.whizdm.moneyview.loans`) | READ_SMS, RECEIVE_SMS | Yes | READ_CONTACTS | Fine | Camera | Yes | Loan product; far broader |
| Wallet by BudgetBakers (`com.droid4you.application.wallet`) | No | No | No | No | Storage | Yes | Bank sync via Salt Edge API instead of SMS |
| Monefy (`com.monefy.app.lite`) | No | No | No | No | Storage (backup) | Yes | Manual only |

**Takeaway for reviewers:** Hisab requests the two SMS permissions that every SMS-based
Indian expense tracker on Play already holds, and nothing else. It is the smallest permission
footprint in this comparison set.

## 5. Where this lives in the code

- Opt-in dialog and OS prompt: `lib/features/sms/sms_screen.dart` (`_toggleSms`)
- Inbox read + live receiver (Android): `android/app/src/main/kotlin/com/ragedpanda/hisab/MainActivity.kt`
- Parser and discard rules: `lib/domain/sms/sms_parser.dart` (OTP / promo rejection list at the top)
- What is stored: `SmsLog` table in `lib/data/db/database.dart` (sender, body, parsed JSON, status)
- URL scheme: `ios/Runner/Info.plist` and the `hisab` intent filter in `AndroidManifest.xml`
- App lock: `lib/features/app_lock/` (gate, settings) and `lib/data/app_lock/device_authenticator.dart`
- Drive backup: consent and connected screens in `lib/features/settings/drive_backup_screen.dart`;
  scope and sign-in in `lib/data/backup/drive_account.dart`; Drive REST calls in
  `lib/data/backup/drive_rest_backup_store.dart`
