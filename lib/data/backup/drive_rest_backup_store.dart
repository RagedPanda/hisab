import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'drive_backup_store.dart';

/// Name of Hisab's backup file inside the Drive `appDataFolder`.
const kDriveBackupFileName = 'hisab-backup.hisab';

const _driveFilesUrl = 'https://www.googleapis.com/drive/v3/files';
const _driveUploadUrl = 'https://www.googleapis.com/upload/drive/v3/files';
const _infoFields = 'id,modifiedTime,size';

/// A Drive request that came back with a non-success status.
class DriveRequestException implements Exception {
  const DriveRequestException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'Google Drive error $statusCode';
}

/// The Drive id of a file plus its details.
typedef DriveFileRecord = ({String id, DriveBackupInfo info});

/// Query for the backup file in the hidden app folder, newest first.
Uri driveBackupListUri() => Uri.parse(_driveFilesUrl).replace(queryParameters: {
      'spaces': 'appDataFolder',
      'q': "name = '$kDriveBackupFileName' and trashed = false",
      'orderBy': 'modifiedTime desc',
      'pageSize': '1',
      'fields': 'files($_infoFields)',
    });

/// Creates the backup in `appDataFolder` with its name and content in one request.
Uri driveCreateUri() => Uri.parse(_driveUploadUrl).replace(queryParameters: {'uploadType': 'multipart', 'fields': _infoFields});

/// Replaces the content of an existing file, keeping its name and folder.
Uri driveUpdateUri(String fileId) =>
    Uri.parse('$_driveUploadUrl/$fileId').replace(queryParameters: {'uploadType': 'media', 'fields': _infoFields});

Uri driveDownloadUri(String fileId) => Uri.parse('$_driveFilesUrl/$fileId').replace(queryParameters: {'alt': 'media'});

Uri driveDeleteUri(String fileId) => Uri.parse('$_driveFilesUrl/$fileId');

/// A Drive file resource (`id`, `modifiedTime`, `size`) as a record.
DriveFileRecord parseDriveFile(Map<String, dynamic> json) => (
      id: json['id'] as String,
      info: DriveBackupInfo(
        modifiedAt: DateTime.parse(json['modifiedTime'] as String),
        sizeBytes: int.tryParse('${json['size'] ?? 0}') ?? 0,
      ),
    );

/// The newest backup file in a files.list response, or null when empty.
DriveFileRecord? parseDriveFileList(Map<String, dynamic> json) {
  final files = (json['files'] as List?) ?? const [];
  return files.isEmpty ? null : parseDriveFile(Map<String, dynamic>.from(files.first as Map));
}

/// A `multipart/related` body: JSON metadata naming the file in
/// `appDataFolder`, then the encrypted bytes.
Uint8List driveCreateBody(Uint8List bytes, String boundary) {
  final metadata = jsonEncode({'name': kDriveBackupFileName, 'parents': ['appDataFolder']});
  return (BytesBuilder(copy: false)
        ..add(utf8.encode('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n$metadata\r\n'))
        ..add(utf8.encode('--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n'))
        ..add(bytes)
        ..add(utf8.encode('\r\n--$boundary--\r\n')))
      .toBytes();
}

/// [DriveBackupStore] over the Drive v3 REST API. [accessToken] yields a
/// `drive.appdata` token; [onTokenRejected] is told about a token Drive
/// refused (401) before the request is retried once with a fresh one.
class DriveRestBackupStore implements DriveBackupStore {
  DriveRestBackupStore({required this.client, required this.accessToken, this.onTokenRejected});

  final http.Client client;
  final Future<String> Function() accessToken;
  final Future<void> Function(String token)? onTokenRejected;

  static const _boundary = 'hisab-backup-boundary';

  Future<http.Response> _send(String method, Uri uri, {Map<String, String> headers = const {}, List<int>? body}) async {
    Future<http.Response> attempt(String token) async {
      final request = http.Request(method, uri)..headers.addAll({...headers, 'Authorization': 'Bearer $token'});
      if (body != null) request.bodyBytes = body;
      return http.Response.fromStream(await client.send(request));
    }

    final token = await accessToken();
    var response = await attempt(token);
    if (response.statusCode == 401 && onTokenRejected != null) {
      await onTokenRejected!(token);
      response = await attempt(await accessToken());
    }
    if (response.statusCode >= 300) throw DriveRequestException(response.statusCode, response.body);
    return response;
  }

  Future<DriveFileRecord?> _find() async {
    final response = await _send('GET', driveBackupListUri());
    return parseDriveFileList(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<DriveBackupInfo?> lastBackupInfo() async => (await _find())?.info;

  @override
  Future<DriveBackupInfo> upload(Uint8List bytes) async {
    final existing = await _find();
    final response = existing == null
        ? await _send('POST', driveCreateUri(),
            headers: {'Content-Type': 'multipart/related; boundary=$_boundary'}, body: driveCreateBody(bytes, _boundary))
        : await _send('PATCH', driveUpdateUri(existing.id), headers: {'Content-Type': 'application/octet-stream'}, body: bytes);
    return parseDriveFile(jsonDecode(response.body) as Map<String, dynamic>).info;
  }

  @override
  Future<Uint8List?> download() async {
    final existing = await _find();
    if (existing == null) return null;
    return (await _send('GET', driveDownloadUri(existing.id))).bodyBytes;
  }

  @override
  Future<bool> delete() async {
    final existing = await _find();
    if (existing == null) return false;
    await _send('DELETE', driveDeleteUri(existing.id));
    return true;
  }
}
