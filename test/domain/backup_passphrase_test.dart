import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/backup/backup_codec.dart';
import 'package:hisab/domain/backup/backup_passphrase.dart';

void main() {
  group('newPassphraseProblem', () {
    test('a short passphrase is refused before the copies are compared', () {
      expect(newPassphraseProblem('short', 'other'), NewPassphraseProblem.tooShort);
      expect(newPassphraseProblem('1234567', '1234567'), NewPassphraseProblem.tooShort);
    });

    test('the typed-again copy must match exactly', () {
      expect(newPassphraseProblem('correct horse', 'correct hose'), NewPassphraseProblem.mismatch);
      expect(newPassphraseProblem('correct horse', 'Correct horse'), NewPassphraseProblem.mismatch);
    });

    test('a long enough matching pair is fine', () {
      expect(newPassphraseProblem('12345678', '12345678'), isNull);
    });
  });

  group('restoreFailureOf', () {
    test('tells a wrong passphrase from a file that is not a backup', () {
      expect(
        restoreFailureOf(const BackupFormatException('x', problem: BackupFormatProblem.wrongPassphrase)),
        RestoreFailure.wrongPassphrase,
      );
      expect(restoreFailureOf(const BackupFormatException('x')), RestoreFailure.notABackup);
      expect(restoreFailureOf(StateError('disk full')), RestoreFailure.unknown);
    });

    test('the codec reports a wrong passphrase and a foreign file apart', () async {
      final bytes = await encryptBackup(payload: {'app': 'hisab'}, passphrase: 'correct horse');
      Object? wrong;
      try {
        await decryptBackup(bytes: bytes, passphrase: 'wrong horse');
      } catch (error) {
        wrong = error;
      }
      expect(restoreFailureOf(wrong!), RestoreFailure.wrongPassphrase);

      Object? foreign;
      try {
        await decryptBackup(bytes: List.filled(64, 1), passphrase: 'correct horse');
      } catch (error) {
        foreign = error;
      }
      expect(restoreFailureOf(foreign!), RestoreFailure.notABackup);
    });
  });
}
