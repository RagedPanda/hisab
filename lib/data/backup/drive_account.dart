import 'package:google_sign_in/google_sign_in.dart';

/// The only Google scope Hisab asks for: its own hidden `appDataFolder`.
/// Never `drive` (full access); see docs/SYNC_SHARING.md.
const kDriveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

/// Web OAuth client of the Hisab Google Cloud project, passed as
/// `serverClientId` (Android needs one). An id, not a secret.
const kGoogleServerClientId = '369484047396-f9qjsh1kdrj02pihfdpdrk7kquer50df.apps.googleusercontent.com';

/// The user closed the Google sign-in or permission screen.
class DriveSignInCancelledException implements Exception {
  const DriveSignInCancelledException();
  @override
  String toString() => 'Google sign-in cancelled';
}

/// Google needs the user on screen (to sign in or grant access again), so
/// a scheduled backup cannot write Drive until they open Drive backup.
class DriveSignInNeededException implements Exception {
  const DriveSignInNeededException();
  @override
  String toString() => 'Google sign-in needed';
}

/// The Google account Drive backups run as. Every call is user-initiated;
/// nothing here runs at launch, so the app never needs a network to start.
abstract interface class DriveAccount {
  /// Signs in and grants Drive access interactively; returns the email.
  Future<String> connect();

  /// A `drive.appdata` access token, asking the user again only if needed.
  Future<String> accessToken();

  /// A `drive.appdata` access token without showing any Google screen, for
  /// scheduled backups. Throws [DriveSignInNeededException] when one is needed.
  Future<String> silentAccessToken();

  /// Forgets a token Drive rejected, so the next [accessToken] is fresh.
  Future<void> clearToken(String token);

  /// Signs out and revokes Hisab's access to the account.
  Future<void> disconnect();
}

/// [DriveAccount] backed by `google_sign_in` 7.
class GoogleDriveAccount implements DriveAccount {
  GoogleDriveAccount({GoogleSignIn? signIn}) : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  Future<void>? _initialized;
  GoogleSignInAccount? _account;

  static const _scopes = [kDriveAppDataScope];

  Future<void> _ensureInitialized() => _initialized ??= _signIn.initialize(serverClientId: kGoogleServerClientId);

  /// Runs [action], turning a cancelled Google screen into [DriveSignInCancelledException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) throw const DriveSignInCancelledException();
      rethrow;
    }
  }

  Future<GoogleSignInAccount> _signedIn() async {
    await _ensureInitialized();
    return _account ??= await _signIn.attemptLightweightAuthentication() ?? await _signIn.authenticate(scopeHint: _scopes);
  }

  Future<String> _token(GoogleSignInAccount account) async {
    final client = account.authorizationClient;
    final authorization = await client.authorizationForScopes(_scopes) ?? await client.authorizeScopes(_scopes);
    return authorization.accessToken;
  }

  @override
  Future<String> connect() => _guard(() async {
        await _ensureInitialized();
        final account = _account = await _signIn.authenticate(scopeHint: _scopes);
        await _token(account);
        return account.email;
      });

  @override
  Future<String> accessToken() => _guard(() async => _token(await _signedIn()));

  @override
  Future<String> silentAccessToken() async {
    await _ensureInitialized();
    final account = _account ??= await _signIn.attemptLightweightAuthentication(reportAllExceptions: false);
    if (account == null) throw const DriveSignInNeededException();
    final authorization = await account.authorizationClient.authorizationForScopes(_scopes);
    if (authorization == null) throw const DriveSignInNeededException();
    return authorization.accessToken;
  }

  @override
  Future<void> clearToken(String token) => _signIn.authorizationClient.clearAuthorizationToken(accessToken: token);

  @override
  Future<void> disconnect() async {
    await _ensureInitialized();
    _account = null;
    await _signIn.disconnect();
  }
}
