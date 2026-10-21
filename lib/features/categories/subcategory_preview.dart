import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../data/repositories/categories_repository.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';

const int kSubcategoryPreviewCount = 3;

/// "Groceries, Restaurants & Cafes, Milk & Dairy, +9" for a parent row.
String subcategoryPreview(BuildContext context, CategoryNode node) => joinWithOverflow(
      node.children.map((child) => child.displayName(context)),
      max: kSubcategoryPreviewCount,
      overflow: (remaining) => context.l10n.moreCount(remaining),
    );
