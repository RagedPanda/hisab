import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/backup/backup_codec.dart';

void main() {
  test('round trip and tamper detection', () async {
    final payload = {'version': 1, 'entries': [{'id': 'x', 'amount': 7000}]};
    final bytes = await encryptBackup(payload: payload, passphrase: 'correct horse');
    expect(String.fromCharCodes(bytes.sublist(0, 6)), backupMagic);
    final back = await decryptBackup(bytes: bytes, passphrase: 'correct horse');
    expect(back, payload);

    expect(
      () => decryptBackup(bytes: bytes, passphrase: 'wrong'),
      throwsA(isA<BackupFormatException>()),
    );
    final tampered = List<int>.from(bytes)..[40] ^= 0xFF;
    expect(
      () => decryptBackup(bytes: tampered, passphrase: 'correct horse'),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => decryptBackup(bytes: [1, 2, 3], passphrase: 'x'),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('backupHeaderProblem turns away a file that is not a backup without a passphrase', () async {
    final bytes = await encryptBackup(payload: {'app': 'hisab'}, passphrase: 'correct horse');
    expect(backupHeaderProblem(bytes), isNull);
    expect(backupHeaderProblem('{"app": "hisab"}'.codeUnits)?.problem, BackupFormatProblem.notABackup);
    expect(backupHeaderProblem(List<int>.filled(200, 0x41))?.problem, BackupFormatProblem.notABackup);
    expect(backupHeaderProblem(bytes.sublist(0, 20))?.problem, BackupFormatProblem.notABackup);
    expect(backupHeaderProblem(const []), isNotNull);
  });
}
