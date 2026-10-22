import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/groups_repository.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// Archive, leave and delete, each behind a confirmation. Shared by the group
/// menu and the group settings page. Each returns whether the action ran.

Future<bool> confirmArchiveGroup(BuildContext context, WidgetRef ref, GroupDetail detail) async {
  final l10n = context.l10n;
  final confirmed = await confirmDialog(context, title: l10n.groupArchiveTitle(detail.group.name), message: l10n.groupArchiveBody, confirmLabel: l10n.groupArchiveConfirm);
  if (!confirmed) return false;
  await ref.read(groupsRepositoryProvider).archiveGroup(detail.group.id);
  return true;
}

/// Refuses with a snackbar while any debt involves me, as Splitwise does.
Future<bool> confirmLeaveGroup(BuildContext context, WidgetRef ref, GroupDetail detail) async {
  final l10n = context.l10n;
  if (!detail.canLeave) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupLeaveBlocked)));
    return false;
  }
  final confirmed = await confirmDialog(context, title: l10n.groupLeaveTitle(detail.group.name), message: l10n.groupLeaveBody, confirmLabel: l10n.groupLeaveConfirm);
  if (!confirmed) return false;
  return ref.read(groupsRepositoryProvider).leaveGroup(detail.group.id);
}

/// Warns harder when balances are still open, since deleting loses them.
Future<bool> confirmDeleteGroup(BuildContext context, WidgetRef ref, GroupDetail detail) async {
  final l10n = context.l10n;
  final unsettled = detail.balances.pairwise.isNotEmpty;
  final confirmed = await confirmDialog(
    context,
    title: l10n.deleteNamed(detail.group.name),
    message: unsettled ? l10n.groupDeleteUnsettledBody : l10n.deleteGroupBody,
    confirmLabel: l10n.delete,
  );
  if (!confirmed) return false;
  await ref.read(groupsRepositoryProvider).deleteGroup(detail.group.id);
  return true;
}
