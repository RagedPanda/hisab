import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../domain/projects/project_templates.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'project_template_labels.dart';

/// First step of creating a project: a blank project or one of the templates.
class ProjectTemplatesScreen extends StatelessWidget {
  const ProjectTemplatesScreen({super.key});

  /// Path segment used for a project without a template.
  static const blankKey = 'blank';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void open(String key) => context.pushReplacement('/projects/new/$key');
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newProject)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _TemplateTile(
            icon: 'folder',
            color: kPaletteColors.first,
            title: l10n.blankProject,
            subtitle: l10n.blankProjectHint,
            onTap: () => open(blankKey),
          ),
          SectionHeader(l10n.startFromTemplate, padding: const EdgeInsets.fromLTRB(4, 16, 4, 8)),
          for (final template in projectTemplates)
            _TemplateTile(
              icon: template.icon,
              color: template.color,
              title: templateName(l10n, template),
              subtitle: templateHint(l10n, template),
              onTap: () => open(template.key),
            ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});
  final String icon;
  final int color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: IconBadge(icon: icon, color: color),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
