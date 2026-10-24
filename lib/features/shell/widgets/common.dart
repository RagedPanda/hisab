import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_icons.dart';
import '../../../core/theme.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../data/repositories/entries_repository.dart';
import '../../../l10n/category_names.dart';
import '../../../l10n/l10n.dart';

/// Rounded tile with a coloured icon, used for categories, accounts and groups.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 40});
  final String? icon;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = Color(color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: base.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(iconFor(icon), color: base, size: size * 0.55),
    );
  }
}

/// Amount text coloured by direction.
class AmountText extends StatelessWidget {
  const AmountText(this.minor, {super.key, required this.kind, this.style, this.signed = true});
  final int minor;
  final String kind;
  final TextStyle? style;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final symbol = ProviderScope.containerOf(context).read(settingsProvider).currencySymbol;
    final color = switch (kind) {
      'income' => const Color(0xFF2E9E6B),
      'expense' => const Color(0xFFD9534F),
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final prefix = !signed ? '' : switch (kind) { 'income' => '+', 'expense' => '-', _ => '' };
    return Text(
      '$prefix${formatMinor(minor, symbol: symbol)}',
      style: (style ?? Theme.of(context).textTheme.bodyLarge)?.copyWith(color: color, fontWeight: FontWeight.w600).tabular,
    );
  }
}

/// One row in a transactions list.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.details, this.onTap, this.showDate = false});
  final EntryDetails details;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = details.entry;
    final category = details.category;
    final categoryName = category?.displayName(context);
    final title = entry.payee?.isNotEmpty == true
        ? entry.payee!
        : entry.note.isNotEmpty
            ? entry.note
            : categoryName ?? (entry.kind == 'transfer' ? l10n.kindTransfer : l10n.uncategorised);
    final locale = Localizations.localeOf(context).toString();
    final accountLabel = entry.kind == 'transfer' && details.toAccount != null
        ? l10n.transferArrow(details.account?.name ?? '', details.toAccount!.name)
        : details.account?.name;
    // Line 2 keeps the context; the date moves under the amount so it never gets truncated away (P2-5, P2-22).
    final subtitleParts = <String>[
      if (categoryName != null && title != categoryName) categoryName,
      if (details.items.isNotEmpty) l10n.itemCount(details.items.length),
      if (details.group != null) l10n.yourShareOf(details.group!.name),
      ?accountLabel,
    ];
    final theme = Theme.of(context);
    final mutedSmall = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ListTile(
      onTap: onTap,
      leading: IconBadge(
        icon: entry.kind == 'transfer' ? 'swap_horiz' : category?.icon,
        color: category?.color ?? 0xFF607D8B,
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitleParts.isEmpty && entry.source != 'sms'
          ? null
          : Row(children: [
              if (entry.source == 'sms') ...[
                Icon(Icons.sms_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant, semanticLabel: l10n.smsAddedMarker),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(subtitleParts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AmountText(details.myAmountMinor, kind: entry.kind),
          Text(
            showDate ? formatRowDate(entry.occurredAt, locale: locale) : formatTime(entry.occurredAt, locale: locale),
            style: mutedSmall?.tabular,
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8)});
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Trailing text action of a [SectionHeader] with a full 48dp tap target.
class SectionAction extends StatelessWidget {
  const SectionAction({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48), padding: const EdgeInsets.symmetric(horizontal: 8)),
        child: Text(label),
      );
}

/// Neutral block shown while a stream has not produced its first value, so
/// screens never flash an empty state on cold start (P2-23).
class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key, this.height = 96});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Month switcher used by dashboard and transactions.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key});

  static void _shift(WidgetRef ref, int months) {
    HapticFeedback.selectionClick();
    ref.read(selectedMonthProvider.notifier).shift(months);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(selectedRangeProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: () => _shift(ref, -1), icon: const Icon(Icons.chevron_left)),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(selectedMonthProvider.notifier).reset();
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              formatMonthLabel(range, locale: Localizations.localeOf(context).toString()),
              key: ValueKey(range.start),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        IconButton(onPressed: () => _shift(ref, 1), icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

Future<bool> confirmDialog(BuildContext context, {required String title, String? message, String? confirmLabel}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel ?? context.l10n.delete)),
      ],
    ),
  );
  return result ?? false;
}

/// Keeps amount fields to digits, a decimal point and thousands separators,
/// and short enough that [parseAmountToMinor] can never overflow.
final List<TextInputFormatter> amountInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  LengthLimitingTextInputFormatter(kMaxAmountWholeDigits + 6),
];

/// Inline error for an amount field, or null while the text parses.
String? amountErrorText(BuildContext context, String text) =>
    text.trim().isNotEmpty && parseAmountToMinor(text) == null ? context.l10n.invalidAmount : null;

Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) {
  final controller = TextEditingController(text: initial);
  controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(context.l10n.save)),
      ],
    ),
  );
}

/// Asks for a money amount; returns minor units, or null when cancelled.
/// Save stays disabled until the text is a valid amount above zero.
Future<int?> promptAmount(BuildContext context, {required String title, int? initialMinor, String? hint}) {
  final controller = TextEditingController(text: initialMinor == null ? '' : amountInputText(initialMinor));
  controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final parsed = parseAmountToMinor(controller.text);
        final valid = parsed != null && parsed > 0;
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: amountInputFormatters,
            decoration: InputDecoration(hintText: hint ?? '0', errorText: amountErrorText(context, controller.text)),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => valid ? Navigator.pop(context, parsed) : null,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: valid ? () => Navigator.pop(context, parsed) : null, child: Text(context.l10n.save)),
          ],
        );
      },
    ),
  );
}

/// Unfocuses any text field when the user taps outside it, so the keyboard
/// can always be dismissed on iOS (which has no system back gesture for it).
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}

/// Full-width primary action pinned above the keyboard and the home indicator.
/// Use as a Scaffold `bottomNavigationBar`; Scaffold does not move that slot
/// above the keyboard by itself.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(width: double.infinity, height: 52, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Width below which icon-and-label segmented buttons no longer fit three
/// segments without wrapping their labels mid-word (P1-5).
const double kCompactSegmentWidth = 380;

/// A [ButtonSegment] that never wraps its label: on narrow screens it falls
/// back to an icon with the label as tooltip.
ButtonSegment<T> compactSegment<T>(BuildContext context, {required T value, required String label, required IconData icon}) {
  final narrow = MediaQuery.sizeOf(context).width < kCompactSegmentWidth;
  return ButtonSegment(
    value: value,
    icon: Icon(icon),
    label: narrow ? null : Text(label, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
    tooltip: narrow ? label : null,
  );
}

/// Location of the first shell tab, used when Back has nowhere else to go.
const String kHomeLocation = '/home';

/// Pops the current route, or returns to Home when this is the only route
/// (e.g. a screen opened straight from a deep link).
void popOrGoHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(kHomeLocation);
  }
}

/// Replaces whatever snackbar is showing with [message] and one action
/// button. Since Flutter 3.29 a snackbar with an action stays up until it is
/// dismissed; this one times out like a plain snackbar instead (#47, #72), so
/// every snackbar with an action in the app goes through here.
void showActionSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
  Duration duration = const Duration(milliseconds: 4000),
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), persist: false, duration: duration, action: SnackBarAction(label: actionLabel, onPressed: onAction)));
}

/// [showActionSnackBar] with an Undo action, so a run of quick actions never
/// queues stale messages behind each other.
void showUndoSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
  Duration duration = const Duration(milliseconds: 4000),
}) =>
    showActionSnackBar(messenger, message: message, actionLabel: undoLabel, onAction: onUndo, duration: duration);

/// Replaces whatever snackbar is showing with [message]. It times out, so a
/// result never lingers or queues behind an older one.
void showTimedSnackBar(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), persist: false));
}

/// Makes the system Back gesture return to Home instead of leaving the app
/// when the wrapped screen is the only route on the stack (P2-3).
class HomeFallbackPop extends StatelessWidget {
  const HomeFallbackPop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(kHomeLocation);
      },
      child: child,
    );
  }
}

/// Current value shown at the trailing edge of a settings row.
class SettingValue extends StatelessWidget {
  const SettingValue(this.value, {super.key});
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(value, style: theme.textTheme.labelLarge!.copyWith(color: theme.colorScheme.primary));
  }
}

const double kChipRowHeight = 40;
const double kChipRowFadeWidth = 28;

/// Single-line horizontal chip strip. The right edge fades out while more
/// chips are hidden off-screen so the row never looks clipped (P2-10/P2-11).
class ChipRow extends StatefulWidget {
  const ChipRow({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 16)});
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  State<ChipRow> createState() => _ChipRowState();
}

class _ChipRowState extends State<ChipRow> {
  final ScrollController _controller = ScrollController();
  bool _moreToTheRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncFade);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFade());
  }

  @override
  void didUpdateWidget(covariant ChipRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFade());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncFade() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final more = position.maxScrollExtent > 0 && position.pixels < position.maxScrollExtent - 1;
    if (more != _moreToTheRight) setState(() => _moreToTheRight = more);
  }

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: widget.padding,
      itemCount: widget.children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, index) => widget.children[index],
    );
    // The mask stays in the tree either way: swapping it in and out would
    // rebuild the list and throw away the scroll position at the far end.
    return SizedBox(
      height: kChipRowHeight,
      child: ShaderMask(shaderCallback: (bounds) => _fadeShader(bounds, fade: _moreToTheRight), blendMode: BlendMode.dstIn, child: list),
    );
  }

  static Shader _fadeShader(Rect bounds, {required bool fade}) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.white, Colors.white, fade ? Colors.transparent : Colors.white],
        stops: [0, 1 - kChipRowFadeWidth / bounds.width, 1],
      ).createShader(bounds);
}
