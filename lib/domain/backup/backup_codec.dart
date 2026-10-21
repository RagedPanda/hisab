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

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
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

Future<Map<String, dynamic>> decryptBackup({
  required List<int> bytes,
  required String passphrase,
}) async {
  final headerLength = backupMagic.length + _saltLength + _nonceLength;
  if (bytes.length < headerLength + 16) {
    throw const BackupFormatException('File is too small to be a Hisab backup');
  }
  final magic = ascii.decode(bytes.sublist(0, backupMagic.length), allowInvalid: true);
  if (magic != backupMagic) {
    throw const BackupFormatException('Not a Hisab backup file');
  }
  var offset = backupMagic.length;
  final salt = bytes.sublist(offset, offset += _saltLength);
  final nonce = bytes.sublist(offset, offset += _nonceLength);
  final cipherText = bytes.sublist(offset, bytes.length - 16);
  final mac = Mac(bytes.sublist(bytes.length - 16));
  final key = await deriveKey(passphrase, salt);
  try {
    final plain = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: key,
    );
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  } on SecretBoxAuthenticationError {
    throw const BackupFormatException('Wrong passphrase or corrupted file');
  }
}

List<int> _randomBytes(int length) {
  final random = SecretKeyData.random(length: length);
  return random.bytes;
}
