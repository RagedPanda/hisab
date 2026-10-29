import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/drive_rest_backup_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A tiny Drive v3 stand-in: at most one file in appDataFolder.
class _FakeDrive {
  String? fileId;
  List<int> content = const [];
  final requests = <http.Request>[];
  int rejectTokensLeft = 0;

  static final _modified = {'modifiedTime': '2026-10-28T09:00:00.000Z'};

  Map<String, Object?> _file() => {'id': fileId, ..._modified, 'size': '${content.length}'};

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    if (rejectTokensLeft > 0) {
      rejectTokensLeft--;
      return http.Response('', 401);
    }
    final path = request.url.path;
    switch (request.method) {
      case 'GET' when path == '/drive/v3/files':
        return http.Response(jsonEncode({'files': [if (fileId != null) _file()]}), 200);
      case 'POST' when path == '/upload/drive/v3/files':
        fileId = 'file-1';
        final body = latin1.decode(request.bodyBytes);
        content = latin1.encode(body.split('application/octet-stream\r\n\r\n').last.split('\r\n--').first);
        return http.Response(jsonEncode(_file()), 200);
      case 'PATCH' when path == '/upload/drive/v3/files/$fileId':
        content = request.bodyBytes;
        return http.Response(jsonEncode(_file()), 200);
      case 'GET' when path == '/drive/v3/files/$fileId' && request.url.queryParameters['alt'] == 'media':
        return http.Response.bytes(content, 200);
      case 'DELETE' when path == '/drive/v3/files/$fileId':
        fileId = null;
        return http.Response('', 204);
    }
    return http.Response('not found', 404);
  }
}

void main() {
  late _FakeDrive drive;
  late DriveRestBackupStore store;
  late List<String> rejectedTokens;
  var tokenCount = 0;

  setUp(() {
    drive = _FakeDrive();
    rejectedTokens = [];
    tokenCount = 0;
    store = DriveRestBackupStore(
      client: MockClient(drive.handle),
      accessToken: () async => 'token-${++tokenCount}',
      onTokenRejected: (token) async => rejectedTokens.add(token),
    );
  });

  final blob = Uint8List.fromList([72, 73, 83, 65, 66, 49, 0, 1, 2, 255]);

  test('lists only the appDataFolder space, by the backup name', () {
    final uri = driveBackupListUri();
    expect(uri.queryParameters['spaces'], 'appDataFolder');
    expect(uri.queryParameters['q'], contains(kDriveBackupFileName));
  });

  test('the first upload creates the file inside appDataFolder', () async {
    expect(await store.lastBackupInfo(), isNull);
    final info = await store.upload(blob);
    final create = drive.requests.singleWhere((request) => request.method == 'POST');
    expect(create.headers['Authorization'], startsWith('Bearer '));
    expect(create.headers['Content-Type'], startsWith('multipart/related'));
    expect(latin1.decode(create.bodyBytes), contains('"parents":["appDataFolder"]'));
    expect(drive.content, blob);
    expect(info.sizeBytes, blob.length);
    expect(info.modifiedAt, DateTime.utc(2026, 10, 28, 9));
  });

  test('a later upload replaces the same file instead of adding one', () async {
    await store.upload(blob);
    await store.upload(Uint8List.fromList([1, 2, 3]));
    expect(drive.requests.where((request) => request.method == 'POST'), hasLength(1));
    expect(drive.requests.where((request) => request.method == 'PATCH'), hasLength(1));
    expect(drive.content, [1, 2, 3]);
  });

  test('download returns the bytes, or null when there is no backup', () async {
    expect(await store.download(), isNull);
    await store.upload(blob);
    expect(await store.download(), blob);
  });

  test('delete removes the file and reports when there was none', () async {
    await store.upload(blob);
    expect(await store.delete(), isTrue);
    expect(await store.lastBackupInfo(), isNull);
    expect(await store.delete(), isFalse);
  });

  test('a rejected token is cleared and the request retried once', () async {
    drive.rejectTokensLeft = 1;
    expect(await store.lastBackupInfo(), isNull);
    expect(rejectedTokens, ['token-1']);
    expect(drive.requests.last.headers['Authorization'], 'Bearer token-2');
  });

  test('other failures surface as DriveRequestException', () async {
    drive.rejectTokensLeft = 2;
    await expectLater(store.lastBackupInfo(), throwsA(isA<DriveRequestException>().having((error) => error.statusCode, 'statusCode', 401)));
  });
}
