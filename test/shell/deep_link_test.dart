import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/shell/deep_link.dart';

void main() {
  group('deep links (P1-3)', () {
    test('host-only link maps to the matching route', () {
      expect(deepLinkLocation(Uri.parse('hisab://sms?text=Rs%20500%20debited')), '/sms?text=Rs+500+debited');
    });
    test('launcher adding a trailing slash still maps', () {
      expect(deepLinkLocation(Uri.parse('hisab://sms/?text=hello')), '/sms?text=hello');
    });
    test('launcher shortcut links open the editor with a kind', () {
      expect(deepLinkLocation(Uri.parse('hisab://entry?kind=expense')), '/entry?kind=expense');
      expect(deepLinkLocation(Uri.parse('hisab://entry?kind=income')), '/entry?kind=income');
    });
    test('in-app locations are left alone', () {
      expect(deepLinkLocation(Uri.parse('/home')), isNull);
      expect(deepLinkLocation(Uri.parse('/groups/abc')), isNull);
      expect(deepLinkLocation(Uri.parse('hisab://sms/extra')), isNull);
    });
  });
}
