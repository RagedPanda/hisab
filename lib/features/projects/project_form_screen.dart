import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// Create or edit a project: name, icon, colour, optional budget and dates,
/// and notes. Creating opens the new project's detail screen.
class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({super.key, this.projectId});

  /// Null to create a new project.
  final String? projectId;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  String _icon = 'folder';
  int _color = kPaletteColors.first;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loaded = false;

  bool get _isEditing => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.projectId;
    if (id != null) {
      final project = await ref.read(projectsRepositoryProvider).byId(id);
      if (project != null) {
        _nameController.text = project.name;
        _budgetController.text = project.budgetMinor == null ? '' : amountInputText(project.budgetMinor!);
        _notesController.text = project.notes;
        _icon = project.icon;
        _color = project.color;
        _startDate = project.startDate;
        _endDate = project.endDate;
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final budgetError = amountErrorText(context, _budgetController.text);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.editProject : l10n.newProject)),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(onPressed: _loaded ? _save : null, child: Text(l10n.save)),
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : DismissKeyboardOnTap(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  TextField(
                    controller: _nameController,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l10n.projectName),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountInputFormatters,
                    decoration: InputDecoration(
                      labelText: l10n.budgetOptional,
                      prefixText: '${ref.watch(settingsProvider).currencySymbol} ',
                      errorText: budgetError,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  _DateTile(
                    label: l10n.startDate,
                    value: _startDate == null ? l10n.notSet : formatShortDate(_startDate!, locale: locale),
                    onPick: () => _pickDate(start: true),
                    onClear: _startDate == null ? null : () => setState(() => _startDate = null),
                  ),
                  _DateTile(
                    label: l10n.endDate,
                    value: _endDate == null ? l10n.notSet : formatShortDate(_endDate!, locale: locale),
                    onPick: () => _pickDate(start: false),
                    onClear: _endDate == null ? null : () => setState(() => _endDate = null),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.colour, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in kPaletteColors)
                        GestureDetector(
                          onTap: () => setState(() => _color = option),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(option),
                            child: _color == option ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.icon, style: theme.textTheme.labelLarge),
                  SizedBox(
                    height: 160,
                    child: GridView.count(
                      crossAxisCount: 8,
                      children: [
                        for (final name in pickableIconNames)
                          IconButton(
                            isSelected: _icon == name,
                            onPressed: () => setState(() => _icon = name),
                            icon: Icon(appIcons[name], color: _icon == name ? Color(_color) : null),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l10n.notes),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? (start ? null : _startDate) ?? DateTime.now(),
      firstDate: start ? DateTime(2000) : (_startDate ?? DateTime(2000)),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final budgetText = _budgetController.text.trim();
    final budgetMinor = budgetText.isEmpty ? null : parseAmountToMinor(budgetText);
    if (budgetText.isNotEmpty && (budgetMinor == null || budgetMinor <= 0)) return;
    final repo = ref.read(projectsRepositoryProvider);
    final notes = _notesController.text.trim();
    final id = widget.projectId;
    if (id == null) {
      final newId = await repo.create(name: name, icon: _icon, color: _color, budgetMinor: budgetMinor, startDate: _startDate, endDate: _endDate, notes: notes);
      if (mounted) context.pushReplacement('/projects/$newId');
    } else {
      await repo.update(
        id,
        ProjectsCompanion(
          name: Value(name),
          icon: Value(_icon),
          color: Value(_color),
          budgetMinor: Value(budgetMinor),
          startDate: Value(_startDate),
          endDate: Value(_endDate),
          notes: Value(notes),
        ),
      );
      if (mounted) context.pop();
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onPick, this.onClear});
  final String label;
  final String value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.event_outlined),
        title: Text(label),
        subtitle: Text(value),
        onTap: onPick,
        trailing: onClear == null ? null : IconButton(tooltip: context.l10n.remove, icon: const Icon(Icons.close), onPressed: onClear),
      );
}
