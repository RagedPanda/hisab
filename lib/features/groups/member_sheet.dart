import 'package:flutter/material.dart';

import '../../data/db/database.dart';
import '../../domain/split/settle_up_links.dart';
import '../../l10n/l10n.dart';

/// What the member sheet returns: a trimmed name, and phone / UPI ID or null.
typedef MemberDetails = ({String name, String? phone, String? upiId});

/// Add (no [existing]) or edit a member: name, optional phone and UPI ID.
/// Returns null when cancelled.
Future<MemberDetails?> showMemberSheet(BuildContext context, {Member? existing}) => showModalBottomSheet<MemberDetails>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _MemberSheet(existing: existing),
    );

/// Null when [raw] is blank; otherwise the trimmed text.
String? _blankToNull(String raw) => raw.trim().isEmpty ? null : raw.trim();

class _MemberSheet extends StatefulWidget {
  const _MemberSheet({this.existing});
  final Member? existing;

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _upiId = TextEditingController(text: widget.existing?.upiId ?? '');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _upiId.dispose();
    super.dispose();
  }

  bool get _upiInvalid => _upiId.text.trim().isNotEmpty && normaliseUpiId(_upiId.text) == null;
  bool get _canSave => _name.text.trim().isNotEmpty && !_upiInvalid;

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop<MemberDetails>((
      name: _name.text.trim(),
      phone: _blankToNull(_phone.text),
      upiId: _blankToNull(_upiId.text) == null ? null : normaliseUpiId(_upiId.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    void refresh(String _) => setState(() {});
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? l10n.addMember : l10n.editMember, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.memberName),
              onChanged: refresh,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneOptional, prefixIcon: const Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upiId,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.upiIdOptional,
                hintText: l10n.upiIdHint,
                prefixIcon: const Icon(Icons.qr_code_2),
                errorText: _upiInvalid ? l10n.invalidUpiId : null,
              ),
              onChanged: refresh,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(l10n.memberContactLocal, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _canSave ? _save : null, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
