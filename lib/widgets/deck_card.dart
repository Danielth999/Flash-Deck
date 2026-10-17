import 'package:flutter/material.dart';

import '../models/flashcard_deck.dart';
import '../theme/app_theme.dart';
import 'category_chip.dart';

class DeckCard extends StatelessWidget {
  const DeckCard({
    required this.deck,
    required this.categoryLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final FlashcardDeck deck;
  final String categoryLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      key: ValueKey('deck-card-${deck.id}'),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                ),
                child: Icon(Icons.style_outlined, color: colors.secondary),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        deck.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Wrap(
                      spacing: AppTheme.space8,
                      runSpacing: AppTheme.space8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CategoryChip(label: categoryLabel),
                        Text(
                          '${deck.totalCardCount} ใบ',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    if (deck.description.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space8),
                      Text(deck.description),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'จัดการชุดบัตร',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                  PopupMenuItem(value: 'delete', child: Text('ลบ')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
