/// Runs flow 35 (credit card dues) on its own; it is also part of
/// app_flows_test.dart. Run with
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/card_dues_flow_test.dart -d `<device>`
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'card_dues_flow.dart';
import 'harness.dart';

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(kCardDuesFlowName, cardDuesFlow, timeout: const Timeout(Duration(minutes: 15)));
}
