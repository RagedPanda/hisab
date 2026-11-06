import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/backup/drive_failure.dart';
import 'package:hisab/domain/backup/scheduled_backup.dart';

String _driveError(String reason) => '{"error": {"code": 403, "errors": [{"domain": "usageLimits", "reason": "$reason"}], "message": "x"}}';

void main() {
  group('driveErrorReasons', () {
    test('reads every reason from Drive error JSON', () {
      expect(driveErrorReasons(_driveError('storageQuotaExceeded')), {'storageQuotaExceeded'});
    });

    test('is empty for a body that is not Drive error JSON', () {
      expect(driveErrorReasons(''), isEmpty);
      expect(driveErrorReasons('<html>Bad gateway</html>'), isEmpty);
      expect(driveErrorReasons('{"error": "nope"}'), isEmpty);
      expect(driveErrorReasons('[1, 2]'), isEmpty);
    });
  });

  group('driveStatusFailure', () {
    test('a full Drive is told apart from lost access', () {
      expect(driveStatusFailure(403, _driveError('storageQuotaExceeded')), DriveBackupFailure.driveFull);
      expect(driveStatusFailure(403, _driveError('quotaExceeded')), DriveBackupFailure.driveFull);
      expect(driveStatusFailure(403, _driveError('insufficientPermissions')), DriveBackupFailure.signedOut);
      expect(driveStatusFailure(403, ''), DriveBackupFailure.signedOut);
    });

    test('a rejected token after the refresh means the user is signed out', () {
      expect(driveStatusFailure(401, ''), DriveBackupFailure.signedOut);
    });

    test('rate limits and server trouble read as try again later', () {
      expect(driveStatusFailure(403, _driveError('userRateLimitExceeded')), DriveBackupFailure.offline);
      expect(driveStatusFailure(429, ''), DriveBackupFailure.offline);
      expect(driveStatusFailure(500, ''), DriveBackupFailure.offline);
      expect(driveStatusFailure(503, 'Service Unavailable'), DriveBackupFailure.offline);
    });

    test('a missing file is not found, anything else unknown', () {
      expect(driveStatusFailure(404, ''), DriveBackupFailure.notFound);
      expect(driveStatusFailure(400, '{"error": {"errors": [{"reason": "badRequest"}]}}'), DriveBackupFailure.unknown);
    });
  });

  test('scheduledFailureOfDrive keeps the stored scheduled failures', () {
    expect(scheduledFailureOfDrive(DriveBackupFailure.cancelled), ScheduledBackupFailure.signInNeeded);
    expect(scheduledFailureOfDrive(DriveBackupFailure.signedOut), ScheduledBackupFailure.signInNeeded);
    expect(scheduledFailureOfDrive(DriveBackupFailure.offline), ScheduledBackupFailure.offline);
    expect(scheduledFailureOfDrive(DriveBackupFailure.driveFull), ScheduledBackupFailure.driveFull);
    expect(scheduledFailureOfDrive(DriveBackupFailure.notFound), ScheduledBackupFailure.unknown);
    expect(scheduledFailureOfDrive(DriveBackupFailure.unknown), ScheduledBackupFailure.unknown);
  });
}
