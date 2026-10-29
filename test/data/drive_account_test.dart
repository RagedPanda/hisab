import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisab/data/backup/drive_account.dart';

/// Grants or withholds the Drive scope and records what was asked of it.
class FakeAuthorizationClient implements GoogleSignInAuthorizationClient {
  FakeAuthorizationClient({this.alreadyGranted = false});

  final bool alreadyGranted;
  final requestedScopes = <List<String>>[];
  final clearedTokens = <String>[];

  @override
  Future<GoogleSignInClientAuthorization?> authorizationForScopes(List<String> scopes) async =>
      alreadyGranted ? const GoogleSignInClientAuthorization(accessToken: 'silent-token') : null;

  @override
  Future<GoogleSignInClientAuthorization> authorizeScopes(List<String> scopes) async {
    requestedScopes.add(scopes);
    return const GoogleSignInClientAuthorization(accessToken: 'granted-token');
  }

  @override
  Future<void> clearAuthorizationToken({required String accessToken}) async => clearedTokens.add(accessToken);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccount implements GoogleSignInAccount {
  FakeAccount(this.authorizationClient);

  @override
  final GoogleSignInAuthorizationClient authorizationClient;

  @override
  String get email => 'asha@example.com';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for Google's sign-in so the account flow runs without a device.
class FakeGoogleSignIn implements GoogleSignIn {
  FakeGoogleSignIn({this.remembered, this.authenticateError});

  final GoogleSignInAccount? remembered;
  final GoogleSignInException? authenticateError;
  final appClient = FakeAuthorizationClient();
  final account = FakeAccount(FakeAuthorizationClient());
  final calls = <String>[];
  String? serverClientId;

  @override
  Future<void> initialize({String? clientId, String? serverClientId, String? nonce, String? hostedDomain}) async {
    calls.add('initialize');
    this.serverClientId = serverClientId;
  }

  @override
  Future<GoogleSignInAccount?>? attemptLightweightAuthentication({bool reportAllExceptions = false}) async {
    calls.add('lightweight');
    return remembered;
  }

  @override
  Future<GoogleSignInAccount> authenticate({List<String> scopeHint = const <String>[]}) async {
    calls.add('authenticate');
    if (authenticateError case final error?) throw error;
    return account;
  }

  @override
  GoogleSignInAuthorizationClient get authorizationClient => appClient;

  @override
  Future<void> disconnect() async => calls.add('disconnect');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('connecting signs in, grants the app-data scope and returns the email', () async {
    final signIn = FakeGoogleSignIn();
    final drive = GoogleDriveAccount(signIn: signIn);

    expect(await drive.connect(), 'asha@example.com');
    expect(signIn.serverClientId, kGoogleServerClientId);
    expect((signIn.account.authorizationClient as FakeAuthorizationClient).requestedScopes, [
      [kDriveAppDataScope],
    ]);
  });

  test('an access token reuses a remembered account and its existing grant', () async {
    final signIn = FakeGoogleSignIn(remembered: FakeAccount(FakeAuthorizationClient(alreadyGranted: true)));
    final drive = GoogleDriveAccount(signIn: signIn);

    expect(await drive.accessToken(), 'silent-token');
    expect(await drive.accessToken(), 'silent-token');
    expect(signIn.calls, ['initialize', 'lightweight'], reason: 'initialised and signed in once');
  });

  test('with no remembered account an access token signs in interactively', () async {
    final signIn = FakeGoogleSignIn();

    expect(await GoogleDriveAccount(signIn: signIn).accessToken(), 'granted-token');
    expect(signIn.calls, ['initialize', 'lightweight', 'authenticate']);
  });

  test('a closed Google screen reads as a cancelled sign-in', () async {
    final signIn = FakeGoogleSignIn(authenticateError: const GoogleSignInException(code: GoogleSignInExceptionCode.canceled));

    await expectLater(GoogleDriveAccount(signIn: signIn).connect(), throwsA(isA<DriveSignInCancelledException>()));
    expect(const DriveSignInCancelledException().toString(), 'Google sign-in cancelled');
  });

  test('any other sign-in failure is passed on unchanged', () async {
    final signIn = FakeGoogleSignIn(authenticateError: const GoogleSignInException(code: GoogleSignInExceptionCode.clientConfigurationError));

    await expectLater(
      GoogleDriveAccount(signIn: signIn).connect(),
      throwsA(isA<GoogleSignInException>().having((error) => error.code, 'code', GoogleSignInExceptionCode.clientConfigurationError)),
    );
  });

  test('a rejected token is cleared and disconnecting forgets the account', () async {
    final signIn = FakeGoogleSignIn(remembered: FakeAccount(FakeAuthorizationClient(alreadyGranted: true)));
    final drive = GoogleDriveAccount(signIn: signIn);
    await drive.accessToken();

    await drive.clearToken('stale-token');
    await drive.disconnect();
    await drive.accessToken();

    expect(signIn.appClient.clearedTokens, ['stale-token']);
    expect(signIn.calls, ['initialize', 'lightweight', 'disconnect', 'lightweight'], reason: 'the next token signs in again');
  });
}
