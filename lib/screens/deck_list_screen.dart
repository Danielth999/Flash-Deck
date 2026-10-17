import 'package:flutter/material.dart';

import '../models/flashcard_category.dart';
import '../models/flashcard_deck.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/deck_card.dart';
import '../widgets/primary_action_button.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({
    required this.decks,
    required this.isLoading,
    required this.onRetry,
    required this.onSaveDeck,
    required this.onDeleteDeck,
    required this.onOpenDeck,
    this.isCategoriesReady = true,
    this.categories = const [],
    this.loadError,
    super.key,
  });

  final List<FlashcardDeck> decks;
  final List<FlashcardCategory> categories;
  final bool isCategoriesReady;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;
  final Future<void> Function({
    FlashcardDeck? existingDeck,
    required String title,
    required String? categoryId,
    required String description,
  })
  onSaveDeck;
  final Future<void> Function(FlashcardDeck deck) onDeleteDeck;
  final void Function(BuildContext context, FlashcardDeck deck) onOpenDeck;

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  static const _allCategories = 'all';
  static const _uncategorized = 'uncategorized';
  String _selectedCategoryId = _allCategories;

  @override
  void didUpdateWidget(covariant DeckListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCategoryId != _allCategories &&
        _selectedCategoryId != _uncategorized &&
        !widget.categories.any(
          (category) => category.id == _selectedCategoryId,
        )) {
      _selectedCategoryId = _allCategories;
    }
  }

  Future<void> _showDeckDialog({FlashcardDeck? deck}) async {
    if (!widget.isCategoriesReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โหลดหมวดหมู่ให้เสร็จก่อน จึงจะแก้ไขชุดบัตรได้'),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _DeckEditorDialog(
        deck: deck,
        categories: widget.categories,
        onSave: (values) => widget.onSaveDeck(
          existingDeck: deck,
          title: values.title,
          categoryId: values.categoryId,
          description: values.description,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDeck(FlashcardDeck deck) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบชุดบัตร?'),
        content: Text('ชุดบัตร “${deck.title}” และบัตรคำทั้งหมดในชุดจะถูกลบ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;
    try {
      await widget.onDeleteDeck(deck);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบชุดบัตรไม่สำเร็จ โปรดลองอีกครั้ง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.categories
        .where((category) => category.id == _selectedCategoryId)
        .firstOrNull;
    final visibleDecks = switch (_selectedCategoryId) {
      _allCategories => widget.decks,
      _uncategorized =>
        widget.decks.where((deck) => deck.categoryId == null).toList(),
      _ when selectedCategory != null =>
        widget.decks
            .where((deck) => deck.categoryId == selectedCategory.id)
            .toList(),
      _ => widget.decks,
    };
    final filters = <({String id, String label})>[
      (id: _allCategories, label: 'ทั้งหมด'),
      ...widget.categories.map(
        (category) => (id: category.id, label: category.name),
      ),
      if (widget.decks.any((deck) => deck.categoryId == null))
        (id: _uncategorized, label: 'ยังไม่จัดหมวด'),
    ];

    return Theme(
      data: AppTheme.deckListTheme(Theme.of(context)),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'FlashDeck',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'ชุดบัตรของฉัน',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'เลือกชุดเพื่อทบทวน หรือสร้างชุดใหม่',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppTheme.space16),
              FilledButton.icon(
                key: const ValueKey('add-deck-button'),
                onPressed: widget.isLoading || !widget.isCategoriesReady
                    ? null
                    : _showDeckDialog,
                icon: const Icon(Icons.add),
                label: const Text('สร้างชุดบัตร'),
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                '${widget.decks.length} ชุด',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.space8),
                      child: CategoryChip(
                        label: filter.label,
                        selected: filter.id == _selectedCategoryId,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryId = filter.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              if (widget.isLoading)
                const _DeckLoadingState()
              else if (widget.loadError != null)
                _DeckErrorState(
                  message: widget.loadError!,
                  onRetry: widget.onRetry,
                )
              else if (visibleDecks.isEmpty)
                _DeckEmptyState(
                  hasAnyDecks: widget.decks.isNotEmpty,
                  onCreateDeck: () => _showDeckDialog(),
                )
              else
                ...visibleDecks.map(
                  (deck) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: DeckCard(
                      deck: deck,
                      categoryLabel: _categoryLabel(deck.categoryId),
                      onTap: () => widget.onOpenDeck(context, deck),
                      onEdit: () => _showDeckDialog(deck: deck),
                      onDelete: () => _confirmDeleteDeck(deck),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String? categoryId) {
    if (categoryId == null) return 'ยังไม่จัดหมวด';
    for (final category in widget.categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'ยังไม่จัดหมวด';
  }
}

class _DeckLoadingState extends StatelessWidget {
  const _DeckLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space32),
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'กำลังเตรียมชุดบัตรของคุณ...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DeckErrorState extends StatelessWidget {
  const _DeckErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36),
            const SizedBox(height: AppTheme.space8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space12),
            PrimaryActionButton(
              label: 'ลองอีกครั้ง',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckEmptyState extends StatelessWidget {
  const _DeckEmptyState({
    required this.hasAnyDecks,
    required this.onCreateDeck,
  });

  final bool hasAnyDecks;
  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.greenSoft,
                borderRadius: BorderRadius.circular(AppTheme.radius24),
              ),
              child: const Icon(
                Icons.style_outlined,
                size: 30,
                color: AppTheme.green,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              hasAnyDecks
                  ? 'ยังไม่มีชุดบัตรในหมวดนี้'
                  : 'เริ่มชุดบัตรแรกของคุณ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              hasAnyDecks
                  ? 'ลองเลือกหมวดอื่น หรือสร้างชุดบัตรใหม่'
                  : 'สร้างชุดบัตรสำหรับเรื่องที่อยากเรียนรู้',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.space16),
            PrimaryActionButton(
              buttonKey: const ValueKey('empty-create-deck-button'),
              label: 'สร้างชุดบัตร',
              icon: Icons.add,
              onPressed: onCreateDeck,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckEditorDialog extends StatefulWidget {
  const _DeckEditorDialog({
    required this.onSave,
    required this.categories,
    this.deck,
  });

  final FlashcardDeck? deck;
  final List<FlashcardCategory> categories;
  final Future<void> Function(
    ({String title, String? categoryId, String description}) values,
  )
  onSave;

  @override
  State<_DeckEditorDialog> createState() => _DeckEditorDialogState();
}

class _DeckEditorDialogState extends State<_DeckEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedCategoryId;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.deck?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.deck?.description ?? '',
    );
    final categoryId = widget.deck?.categoryId;
    _selectedCategoryId =
        categoryId != null &&
            widget.categories.any((category) => category.id == categoryId)
        ? categoryId
        : 'uncategorized';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave((
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId == 'uncategorized'
            ? null
            : _selectedCategoryId,
        description: _descriptionController.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'บันทึกชุดบัตรไม่สำเร็จ โปรดลองอีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(widget.deck == null ? 'สร้างชุดบัตร' : 'แก้ไขชุดบัตร'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'ชื่อชุดบัตร'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกชื่อชุดบัตร'
                  : null,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('deck-category-field'),
              isExpanded: true,
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'หมวดหมู่'),
              items: [
                const DropdownMenuItem(
                  value: 'uncategorized',
                  child: Text('ยังไม่จัดหมวด'),
                ),
                ...widget.categories.map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null && !_isSaving) {
                  setState(() => _selectedCategoryId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'คำอธิบาย'),
              enabled: !_isSaving,
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                key: const ValueKey('deck-save-error'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('บันทึก'),
        ),
      ],
    );
  }
}
