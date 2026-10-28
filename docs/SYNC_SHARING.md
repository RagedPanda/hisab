# Hisab — Sync & Sharing Design (no backend)

How Hisab backs up and syncs data, and how Splitwise-style shared groups work, **without
running any server of our own**. Hisab has no backend, holds no user accounts, and stores no
user data. Everything below uses the *user's own* cloud storage; Hisab's developer operates nothing
and can see nothing.

Last reviewed: 2026-10-28.

## Principles

1. **Offline first, always optional.** The app is fully usable with no account and no network.
   Sync and sharing are opt-in features the user turns on deliberately, never a gate at launch.
2. **No Hisab backend, ever.** Personal data lives in the user's own Google Drive; a shared
   group lives in a file the group owner shares from *their* Drive. Hisab runs no server and
   pays for no hosting.
3. **End-to-end encrypted.** Everything written to Drive is ciphertext (reuse `backup_codec`:
   AES-256-GCM, key via PBKDF2). Google cannot read it, and neither can we — there is nothing
   for us to read.
4. **Narrowest possible access.** We request only app-created-file scopes, never full Drive
   access, so Hisab can touch only its own files.
5. **Tell the user why, in plain words.** Before any Google/Drive permission, show a screen
   that explains what the access is for, that it is optional, and how to skip it (see
   [Consent screen](#consent-screen-mandatory)).

## Personal sync (your data, your Drive)

Scope: entries, accounts, budgets, categories, projects, recurring rules, settings, and the
[People list](#people-list-whom-you-have-invited).

- **Storage:** Google Drive **`appDataFolder`** (`drive.appdata` scope). This is a hidden,
  per-app folder in the user's own Drive — invisible in their Drive UI, not shareable, removed
  if they uninstall or disconnect. It never mixes with the user's own files.
- **Sign-in:** `google_sign_in`. On iOS the equivalent is the CloudKit private database
  (`icloud_storage`), which needs no sign-in UI; cross-platform Android↔iOS personal bridging
  is out of scope (move via an encrypted backup file).
- **Format:** reuse the existing encrypted backup. Every table already carries `updatedAt` and
  `deletedAt`. Push a change log of rows where `updatedAt > lastSync`; merge with
  **last-writer-wins by `updatedAt`**, deletions as `deletedAt` tombstones. This is exactly
  what `BackupService.importSnapshot` already does.
- **Not a Hisab server:** the "remote" is the user's own Drive container. We never see it.

## Shared groups (the Splitwise part, still no backend)

A shared group needs a single copy both members can reach. We use a **shared Google Drive
file**, not a relay we host.

### The model: one shared file per group, holding an append-only event log

- Each shared group is **one file in the group owner's normal Drive** (scope `drive.file`, so
  Hisab sees only files it created — it is *not* in `appDataFolder`, because that folder cannot
  be shared). Keep it under a dedicated `Hisab/Groups/` folder.
- The file is an **append-only log of events**, not a snapshot: `addExpense`, `editExpense`,
  `deleteExpense` (a tombstone), `addMember`, `settle`, … Each event has a UUID, an author, and
  a logical clock / `updatedAt`. **Balances are derived by replaying the log**, never stored as
  a mutable total.
- **Merging is the union of all events by id**, with last-writer-wins on edits by clock. Two
  people editing offline therefore never truly conflict — they just contribute events that
  merge cleanly. An expense travels as **one unit** (the entry event plus its payers, and for a
  by-item split its item rows and member assignments), so a client never applies one version's
  payers against another version's total.
- **Safe writes:** Drive gives each file a revision id. Write with read-modify-write: if the
  revision changed since we pulled, re-pull, re-merge (union — nothing is lost), re-push.
- **Sync cadence:** poll on app open and on pull-to-refresh. Near-real-time, not instant; this
  is the main UX difference from Splitwise and is acceptable for shared-expense tracking.
- **Cross-platform:** groups always use Google Drive, even for an iOS member, so Android and iOS
  users can share the same group.

### Invite flow (no server, no "pending member")

1. Owner creates the group → the app creates the Drive file.
2. The app shares the file — preferably with the **invitee's Google email** (so access can be
   revoked later), or "anyone with the link" for the simple case.
3. The app generates a Hisab invite link carrying the **file id + the group's decryption key**
   in the URL fragment: `hisab:///join?g=<fileId>#k=<key>`. The key is in the fragment, which
   is never sent to any server — it stays end-to-end.
4. The invitee opens the link in Hisab, signs in with Google, the app pulls and decrypts the
   file, and they are a member. Each app then polls/pushes.

### Honest trade-offs vs Splitwise

- Every member needs a **Google account** and must grant Drive access (no phone-number or
  email-only invites).
- The invitee **must install Hisab** first — there is no server to hold a pending membership.
- **Near-real-time**, not instant — changes appear on the next sync.
- The **owner's Drive hosts the file**; if they delete it or revoke access, others lose the
  shared copy, though each member keeps a local cache of history. Clean per-member revoke needs
  email-based sharing (not "anyone with link").
- The **append-only log is load-bearing** — a naive "overwrite the whole file" design would
  lose data under concurrent edits. The log + union merge is what makes zero-backend safe.

## People list (whom you have invited)

Everyone you add to a group with an email goes on **your own People list**, so the next group
can suggest them instead of making you type them again. It is deliberately simple:

- **A person is a name + an email.** The email, trimmed and lowercased, is the row id
  (`people` table, schema v19). Adding `Amit · amit@gmail.com` to a second group, or on a
  second device, updates the same row (latest name wins) instead of creating a duplicate.
- **Filled automatically.** Adding or editing a member with an email saves them; there is no
  separate "contacts" screen to maintain. Members without an email stay group-only.
- **Suggested while typing.** In the add-member sheet, typing a name or an email lists up to
  three matching people (a match at the start ranks first); people already in the group are
  skipped. Tapping one fills the name and email.
- **Yours, not the group's.** The list syncs with your personal data (backup today, your Drive
  `appDataFolder` once personal sync ships), never into a shared group file, so other members
  never see whom else you know. Restoring on a new device brings it back.
- **Feeds invites.** The email is what step 2 of the [invite flow](#invite-flow-no-server-no-pending-member)
  shares the group file with.
- **Not in scope:** phone-contact import, phone-number matching, Google account ids.

## Consent screen (mandatory)

Shown **only** when the user taps "Set up sync / backup" themselves — never unprompted at first
launch. "Skip" is a first-class choice shown as prominently as "Connect", never a greyed-out
link. The same short "why" line is repeated in Settings next to the sync toggle. A Hindi
translation ships with it.

> ### Back up & sync with Google Drive — *optional*
>
> Hisab works fully offline. Your data stays on this phone and nothing is ever sent anywhere —
> unless you turn this on.
>
> Turn on Drive sync and Hisab keeps an **encrypted** copy of your data in **your own** Google
> Drive, so you can restore everything if you lose or change your phone, and share a group with
> friends and family.
>
> **Why Hisab asks for Drive access:** only to read and write **its own** files in your Drive.
> - It **cannot** see your photos, documents, or anything else in your Drive.
> - The data is **encrypted** — Google can't read it, and neither can we. There is no Hisab server.
> - You can **turn this off and disconnect** any time, and delete the Drive copy with one tap.
>
> Don't want it? **Just skip this** — Hisab works exactly the same without it.
>
> `Skip for now`   ·   `Connect Google Drive`

**Scopes & wording rules**
- Personal sync requests `drive.appdata` (app's own hidden folder). Shared groups request
  `drive.file` (only files Hisab created). Never `drive` (full access).
- The copy must state the data is encrypted and that there is no Hisab server, because both are
  literally true and are Hisab's differentiator.
- Update `docs/PERMISSIONS.md` with these scopes and the exact wording when this ships.

## Order of work

0. **People list:** email on group members, the `people` table and add-member suggestions.
   Works offline and in today's backups; no Google setup needed. *(Shipped.)*
1. **Personal backup:** Settings → "Back up to Google Drive" → consent screen → upload one
   encrypted blob to `appDataFolder`; restore on a new device. Manual "Back up now" and
   "Restore from Drive" (merging last-writer-wins), plus "Disconnect" and "Delete Drive
   copy". *(Shipped.)*
2. **Personal incremental sync:** row-level change log with LWW merge.
3. **Shared groups:** the per-group shared Drive file, append-only log, invite links, and
   near-real-time poll/push.

Steps 1–3 need the one-time Google Cloud setup in [GOOGLE_CLOUD_SETUP.md](GOOGLE_CLOUD_SETUP.md).

Each step ships as its own PR, smallest first, and only after the current simplicity pass.
