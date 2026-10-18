import 'package:flutter/material.dart';

import '../models/flashcard_category.dart';
import '../models/flashcard_deck.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import 'deck_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.decks,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.onSaveDeck,
    required this.onDeleteDeck,
    required this.categories,
    required this.isLoadingCategories,
    required this.categoryLoadError,
    required this.onRetryCategories,
    required this.onCreateCategory,
    required this.onRenameCategory,
    required this.onDeleteCategory,
    required this.onOpenDeck,
    required this.onSignOut,
    required this.isSigningOut,
    super.key,
  });

  final List<FlashcardDeck> decks;
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
  final List<FlashcardCategory> categories;
  final bool isLoadingCategories;
  final String? categoryLoadError;
  final VoidCallback onRetryCategories;
  final Future<void> Function(String name) onCreateCategory;
  final Future<void> Function({required String id, required String name})
  onRenameCategory;
  final Future<void> Function(FlashcardCategory category) onDeleteCategory;
  final ValueChanged<FlashcardDeck> onOpenDeck;
  final Future<void> Function() onSignOut;
  final bool isSigningOut;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  Future<void> _confirmSignOut() async {
    if (widget.isSigningOut) return;
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ?'),
        content: const Text('คุณสามารถเข้าสู่ระบบอีกครั้งได้ทุกเมื่อ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout),
            label: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true && mounted) await widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                DeckListScreen(
                  decks: widget.decks,
                  isLoading: widget.isLoading,
                  loadError: widget.loadError,
                  onRetry: widget.onRetry,
                  isCategoriesReady:
                      !widget.isLoadingCategories &&
                      widget.categoryLoadError == null,
                  onSaveDeck: widget.onSaveDeck,
                  onDeleteDeck: widget.onDeleteDeck,
                  categories: widget.categories,
                  onOpenDeck: (_, deck) => widget.onOpenDeck(deck),
                ),
                _CategoryScreen(
                  categories: widget.categories,
                  decks: widget.decks,
                  isLoading: widget.isLoadingCategories,
                  loadError: widget.categoryLoadError,
                  onRetry: widget.onRetryCategories,
                  onCreate: widget.onCreateCategory,
                  onRename: widget.onRenameCategory,
                  onDelete: widget.onDeleteCategory,
                ),
                _AccountScreen(
                  isSigningOut: widget.isSigningOut,
                  onSignOut: _confirmSignOut,
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                key: ValueKey('tab-decks'),
                icon: Icon(Icons.style_outlined),
                selectedIcon: Icon(Icons.style),
                label: 'ชุดบัตร',
              ),
              NavigationDestination(
                key: ValueKey('tab-categories'),
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'หมวดหมู่',
              ),
              NavigationDestination(
                key: ValueKey('tab-account'),
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'บัญชี',
              ),
            ],
          ),
        ),
        if (widget.isSigningOut)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _CategoryScreen extends StatelessWidget {
  const _CategoryScreen({
    required this.categories,
    required this.decks,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  final List<FlashcardCategory> categories;
  final List<FlashcardDeck> decks;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;
  final Future<void> Function(String name) onCreate;
  final Future<void> Function({required String id, required String name})
  onRename;
  final Future<void> Function(FlashcardCategory category) onDelete;

  Future<void> _editCategory(
    BuildContext context, {
    FlashcardCategory? category,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CategoryEditorDialog(
        category: category,
        onSave: (name) => category == null
            ? onCreate(name)
            : onRename(id: category.id, name: name),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FlashcardCategory category,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบหมวดหมู่?'),
        content: Text(
          'Deck ในหมวด “${category.name}” จะย้ายเป็น “ยังไม่จัดหมวด” '
          'บัตรใน Deck จะไม่ถูกลบ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบหมวดหมู่'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;
    try {
      await onDelete(category);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบหมวดหมู่ไม่สำเร็จ โปรดลองอีกครั้ง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryDeckCounts = <String, int>{};
    for (final deck in decks) {
      final id = deck.categoryId;
      if (id != null) {
        categoryDeckCounts.update(id, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('หมวดหมู่'),
        actions: [
          IconButton(
            key: const ValueKey('add-category-button'),
            tooltip: 'เพิ่มหมวดหมู่',
            onPressed: isLoading ? null : () => _editCategory(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        key: const PageStorageKey<String>('categories-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'จัดการหมวดหมู่ของคุณ',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTheme.space16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.space24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (loadError != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  children: [
                    Text(loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: AppTheme.space12),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            )
          else if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.space8),
              child: Text(
                'ยังไม่มีหมวดหมู่ กดปุ่ม + เพื่อเพิ่มหมวดแรก',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            for (final category in categories)
              Card(
                key: ValueKey('category-${category.id}'),
                margin: const EdgeInsets.only(bottom: AppTheme.space12),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.greenSoft,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radius16,
                          ),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Text(
                              '${categoryDeckCounts[category.id] ?? 0} ชุด',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'จัดการหมวดหมู่',
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editCategory(context, category: category);
                          } else if (value == 'delete') {
                            _confirmDelete(context, category);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('เปลี่ยนชื่อ'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('ลบ')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({required this.onSave, this.category});

  final FlashcardCategory? category;
  final Future<void> Function(String name) onSave;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(_nameController.text.trim());
      if (mounted) Navigator.pop(context);
    } on CategoryNameAlreadyExistsException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'มีหมวดหมู่ชื่อนี้ในบัญชีแล้ว';
      });
    } on CategoryNameValidationException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'ชื่อหมวดหมู่ต้องมีความยาว 1–50 ตัวอักษร';
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'บันทึกหมวดหมู่ไม่สำเร็จ โปรดลองอีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.category == null ? 'เพิ่มหมวดหมู่' : 'เปลี่ยนชื่อหมวดหมู่',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('category-name-field'),
              controller: _nameController,
              autofocus: true,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'ชื่อหมวดหมู่'),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'กรุณากรอกชื่อหมวดหมู่';
                if (name.runes.length > 50) {
                  return 'ชื่อหมวดหมู่ต้องไม่เกิน 50 ตัวอักษร';
                }
                return null;
              },
              enabled: !_isSaving,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTheme.space8),
              Text(
                _errorMessage!,
                key: const ValueKey('category-save-error'),
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
          key: const ValueKey('save-category-button'),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('บันทึก'),
        ),
      ],
    );
  }
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen({required this.isSigningOut, required this.onSignOut});

  final bool isSigningOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บัญชี')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                children: [
                  Text(
                    'โปรไฟล์ FlashDeck',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  const _ProfileTile(
                    key: ValueKey('profile-dan'),
                    imagePath: 'assets/profiles/dan.jpg',
                    name: 'นาย วีระชัย เฮืองฮุง',
                  ),
                  const SizedBox(height: AppTheme.space8),
                  const _ProfileTile(
                    key: ValueKey('profile-ket'),
                    imagePath: 'assets/profiles/ket.webp',
                    name: 'นายอรัณ ปิ่นอนงค์',
                  ),
                  const SizedBox(height: AppTheme.space24),
                  OutlinedButton.icon(
                    key: const ValueKey('sign-out-button'),
                    onPressed: isSigningOut ? null : onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('ออกจากระบบ'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.imagePath, required this.name, super.key});

  final String imagePath;
  final String name;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppTheme.greenSoft,
        backgroundImage: AssetImage(imagePath),
      ),
      title: Text(name),
    );
  }
}
