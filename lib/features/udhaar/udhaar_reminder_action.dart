import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/split/settle_up_links.dart';
import '../../domain/udhaar/udhaar_reminder.dart';
import '../../l10n/l10n.dart';
import '../groups/settle_up_sheet.dart' show linkLauncherProvider, textSharerProvider;
import 'udhaar_providers.dart';

/// Asks for the user's own UPI ID, suggesting [initial]; returns the
/// normalised ID, '' to leave it out, or null when cancelled.
Future<String?> promptMyUpiId(BuildContext context, {String? initial}) {
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = context.l10n;
        final typed = controller.text.trim();
        final normalised = normaliseUpiId(typed);
        final invalid = typed.isNotEmpty && normalised == null;
        void save() {
          if (!invalid) Navigator.pop(context, normalised ?? '');
        }

        return AlertDialog(
          title: Text(l10n.udhaarMyUpiId),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.udhaarMyUpiIdHelp),
            const SizedBox(height: 12),
            TextField(
              key: const Key('udhaar.myUpiId'),
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: l10n.upiIdHint, errorText: invalid ? l10n.invalidUpiId : null),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => save(),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            FilledButton(key: const Key('udhaar.myUpiIdSave'), onPressed: invalid ? null : save, child: Text(l10n.save)),
          ],
        );
      },
    ),
  );
}

/// Asks for the user's UPI ID (suggesting the one from their groups) and
/// stores it; false when cancelled.
Future<bool> editMyUpiId(BuildContext context, WidgetRef ref) async {
  final current = ref.read(myUpiIdProvider);
  final suggested = current == null || current.isEmpty ? await ref.read(udhaarRepositoryProvider).myGroupUpiId() : current;
  if (!context.mounted) return false;
  final upiId = await promptMyUpiId(context, initial: suggested);
  if (upiId == null) return false;
  await ref.read(myUpiIdProvider.notifier).set(upiId);
  return true;
}

/// Reminds [person] about the [balance] they owe me since [since]: on
/// WhatsApp when their phone is known, else through the share sheet. The
/// message carries a UPI link to pay me when I have a UPI ID and amounts
/// are in rupees. The first reminder asks for the UPI ID once.
Future<void> sendUdhaarReminder(BuildContext context, WidgetRef ref, {required Person person, required int balance, required DateTime since}) async {
  if (ref.read(myUpiIdProvider) == null && !await editMyUpiId(context, ref)) return;
  if (!context.mounted) return;
  final l10n = context.l10n;
  final settings = ref.read(settingsProvider);
  final upiId = ref.read(myUpiIdProvider) ?? '';
  final locale = Localizations.localeOf(context).toString();
  final greeting = l10n.udhaarReminderGreeting(
    person.name,
    formatMinor(balance, format: ref.read(homeMoneyFormatProvider)),
    formatDayMonth(since, locale: locale),
  );
  final payLine = upiId.isEmpty || settings.currencyCode != 'INR'
      ? null
      : l10n.udhaarReminderPay(upiPayLink(upiId: upiId, payeeName: settings.myName, amountMinor: balance));
  final text = udhaarReminderText(greeting: greeting, payLine: payLine);
  final chat = person.phone == null ? null : whatsAppUri(person.phone!, text);
  if (chat != null && await ref.read(linkLauncherProvider)(chat)) return;
  await ref.read(textSharerProvider)(text);
}
