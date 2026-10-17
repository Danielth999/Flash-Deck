import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    this.selected = false,
    this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = selected ? colors.primary : AppTheme.greenSoft;
    final foregroundColor = selected ? colors.onPrimary : colors.primary;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      constraints: BoxConstraints(minHeight: onSelected == null ? 32 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radius24),
        border: Border.all(
          color: selected ? colors.primary : AppTheme.border,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );

    if (onSelected == null) return chip;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius24),
        onTap: () => onSelected!(!selected),
        child: chip,
      ),
    );
  }
}
