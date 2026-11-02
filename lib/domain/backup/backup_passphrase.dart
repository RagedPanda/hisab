import 'backup_codec.dart';

/// Shortest passphrase a new backup may use.
const kMinBackupPassphraseLength = 8;

/// What is wrong with a new passphrase and its typed-again copy.
enum NewPassphraseProblem { tooShort, mismatch }

/// The first problem with [passphrase] and its [confirmation], or null when
/// it can be used. Length is checked first: no point matching a short one.
NewPassphraseProblem? newPassphraseProblem(String passphrase, String confirmation) {
  if (passphrase.length < kMinBackupPassphraseLength) return NewPassphraseProblem.tooShort;
  if (passphrase != confirmation) return NewPassphraseProblem.mismatch;
  return null;
}

/// Why a restore failed, for picking the message to show.
enum RestoreFailure { wrongPassphrase, notABackup, unknown }

/// Sorts an error thrown while opening a backup into a [RestoreFailure].
RestoreFailure restoreFailureOf(Object error) => switch (error) {
      BackupFormatException(problem: BackupFormatProblem.wrongPassphrase) => RestoreFailure.wrongPassphrase,
      BackupFormatException() => RestoreFailure.notABackup,
      _ => RestoreFailure.unknown,
    };
