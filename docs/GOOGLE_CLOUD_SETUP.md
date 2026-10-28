# Hisab — Google Cloud setup for Drive sign-in

The one-time setup in Google Cloud Console that steps 1–3 of
[SYNC_SHARING.md](SYNC_SHARING.md#order-of-work) need: Google sign-in on Android, the Drive
API, and the two narrow Drive scopes. Only the owner of the Google account can do this; the
app code needs just the client IDs it produces.

Last reviewed: 2026-10-27.

## What you end up with

| Item | Used for | Secret? |
|---|---|---|
| Google Cloud project `hisab` | Holds everything below | No |
| Google Drive API, enabled | Reading and writing Hisab's own Drive files | No |
| OAuth consent screen (Google Auth Platform) | The "Hisab wants to access…" screen | No |
| Android OAuth client, **debug** key | Sign-in from `flutter run` builds | No |
| Android OAuth client, **release / upload** key | Sign-in from builds you sideload or upload | No |
| Android OAuth client, **Play app signing** key | Sign-in from builds installed from Google Play | No |
| Web OAuth client | Passed to `google_sign_in` as `serverClientId`; Android needs one | The ID is not secret; never put its client **secret** in the app |

Hisab talks to Drive directly from the phone. There is no server, so there is no client secret,
no service account and no `google-services.json` (no Firebase).

## 0. Before you start: a real release signing key

`android/app/build.gradle.kts` still signs **release builds with the debug key** (the Flutter
template's TODO). An Android OAuth client is tied to a signing key's SHA-1, so pick the
release key first; changing it later means another OAuth client.

```sh
keytool -genkeypair -v -keystore ~/keys/hisab-upload.jks -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Keep the `.jks` and its passwords outside the repo (they are already in `.gitignore`), backed
up somewhere safe. Wiring it into `build.gradle.kts` through `android/key.properties` is a
small code change, separate from this setup.

## 1. Collect the SHA-1 fingerprints

```sh
# Debug key (one per machine; each developer machine needs its own client)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
  -storepass android -keypass android | grep SHA1

# Release / upload key
keytool -list -v -keystore ~/keys/hisab-upload.jks -alias upload | grep SHA1
```

If the app ships on Google Play with Play App Signing, Play re-signs it with its own key: copy
that SHA-1 from **Play Console → Test and release → App integrity → App signing**.

## 2. Create the project and enable the Drive API

1. Open <https://console.cloud.google.com/>, signed in as the account that should own the app.
2. Project picker → **New project** → name `hisab` → **Create**, then select it.
3. **APIs & Services → Library** → search **Google Drive API** → **Enable**.

## 3. Configure the consent screen (Google Auth Platform)

1. **Google Auth Platform → Branding** (on first visit, **Get started**):
   - App name: `Hisab`
   - User support email and developer contact email: your address
   - App logo, home page, privacy policy and terms URLs: optional while testing, **required to
     publish**. The privacy policy should say what SYNC_SHARING.md promises: data is encrypted,
     lives only in the user's own Drive, and there is no Hisab server.
   - Authorized domain: the domain hosting those pages
2. **Audience**:
   - User type **External**.
   - While testing, add your own Google account(s) as **test users** (up to 100). In
     *Testing* status, sign-ins expire after 7 days.
3. **Data Access → Add or remove scopes** → add exactly these two (paste them under
   *Manually add scopes* if they are not listed):
   - `https://www.googleapis.com/auth/drive.appdata` — personal sync (hidden app folder)
   - `https://www.googleapis.com/auth/drive.file` — shared group files Hisab created

   Never add `https://www.googleapis.com/auth/drive` (full Drive access). That is a restricted
   scope that needs a paid security assessment, and Hisab must not ask for it. The two scopes
   above are non-sensitive, so publishing needs only brand verification.

## 4. Create the OAuth clients

**Google Auth Platform → Clients → Create client**, once per row:

| Application type | Name | Package name | SHA-1 |
|---|---|---|---|
| Android | `Hisab debug (<machine>)` | `com.ragedpanda.hisab` | debug key, step 1 |
| Android | `Hisab release` | `com.ragedpanda.hisab` | upload key, step 1 |
| Android | `Hisab Play` | `com.ragedpanda.hisab` | Play app signing key, step 1 (only once on Play) |
| Web application | `Hisab server client` | — | — (no redirect URIs, no origins) |

Copy the **Web client ID** (`…apps.googleusercontent.com`). It is the only value the app
needs. The Android clients need nothing copied: Google matches them by package name + SHA-1.

## 5. Hand over to the code

Share only the **Web client ID**. It goes into the app as `serverClientId`; it is not a secret.
Do **not** share or commit the Web client's secret, the keystore or its passwords.

## 6. Publishing later

Before real users: **Audience → Publish app**, then submit brand verification (logo, home
page, privacy policy, and a domain verified in Search Console). With only non-sensitive scopes
this usually takes a few business days. Then update `docs/PERMISSIONS.md` with the scopes and
the consent wording, as SYNC_SHARING.md requires.

## Troubleshooting

- **Sign-in fails with `DEVELOPER_ERROR` / error 10:** the installed build's signing SHA-1 or
  package name has no matching Android client. Check with
  `keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk`.
- **"Access blocked: app has not completed verification":** the account is not a test user
  while the app is in *Testing*.
- **Works from `flutter run` but not from Play:** the Play app signing SHA-1 client is missing.
