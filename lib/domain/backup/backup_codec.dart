/// Passphrase-encrypted backup format. Pure Dart (package:cryptography).
///
/// Layout of the produced bytes:
///   magic "HISAB1" (6) | salt (16) | nonce (12) | AES-256-GCM ciphertext+tag
/// The key is PBKDF2-HMAC-SHA256(passphrase, salt, 200k iterations).
/// The same codec is used for local export files and for cloud sync blobs,
/// so cloud providers only ever see ciphertext.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const backupMagic = 'HISAB1';
const _saltLength = 16;
const _nonceLength = 12;
const _iterations = 200000;
const _macLength = 16;
const _headerLength = backupMagic.length + _saltLength + _nonceLength;

/// Why a backup could not be opened. AES-GCM cannot tell a wrong
/// passphrase from a damaged file, so [wrongPassphrase] covers both.
enum BackupFormatProblem { notABackup, wrongPassphrase }

class BackupFormatException implements Exception {
  const BackupFormatException(this.message, {this.problem = BackupFormatProblem.notABackup});
  final String message;
  final BackupFormatProblem problem;
  @override
  String toString() => message;
}

Future<SecretKey> deriveKey(String passphrase, List<int> salt) {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: 256,
  );
  return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
}

Future<Uint8List> encryptBackup({
  required Map<String, dynamic> payload,
  required String passphrase,
  List<int>? saltOverride,
  List<int>? nonceOverride,
}) async {
  final algorithm = AesGcm.with256bits();
  final salt = saltOverride ?? _randomBytes(_saltLength);
  final nonce = nonceOverride ?? algorithm.newNonce();
  final key = await deriveKey(passphrase, salt);
  final plain = utf8.encode(jsonEncode(payload));
  final box = await algorithm.encrypt(plain, secretKey: key, nonce: nonce);
  final builder = BytesBuilder(copy: false)
    ..add(ascii.encode(backupMagic))
    ..add(salt)
    ..add(nonce)
    ..add(box.cipherText)
    ..add(box.mac.bytes);
  return builder.toBytes();
}

/// Why [bytes] cannot be a Hisab backup (too short, or no "HISAB1" magic),
/// or null when they look like one. Needs no passphrase, so a restore can
/// turn away a wrong file before asking for one.
BackupFormatException? backupHeaderProblem(List<int> bytes) {
  if (bytes.length < _headerLength + _macLength) {
    return const BackupFormatException('File is too small to be a Hisab backup');
  }
  final magic = ascii.decode(bytes.sublist(0, backupMagic.length), allowInvalid: true);
  return magic == backupMagic ? null : const BackupFormatException('Not a Hisab backup file');
}

Future<Map<String, dynamic>> decryptBackup({
  required List<int> bytes,
  required String passphrase,
}) async {
  final headerProblem = backupHeaderProblem(bytes);
  if (headerProblem != null) throw headerProblem;
  var offset = backupMagic.length;
  final salt = bytes.sublist(offset, offset += _saltLength);
  final nonce = bytes.sublist(offset, offset += _nonceLength);
  final cipherText = bytes.sublist(offset, bytes.length - _macLength);
  final mac = Mac(bytes.sublist(bytes.length - _macLength));
  final key = await deriveKey(passphrase, salt);
  try {
    final plain = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: key,
    );
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  } on SecretBoxAuthenticationError {
    throw const BackupFormatException('Wrong passphrase or corrupted file', problem: BackupFormatProblem.wrongPassphrase);
  }
}

List<int> _randomBytes(int length) {
  final random = SecretKeyData.random(length: length);
  return random.bytes;
}
