import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/flashcard_deck.dart';
import 'models/flashcard_category.dart';
import 'screens/auth_screen.dart';
import 'screens/card_list_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/deck_service.dart';
import 'services/supabase_category_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/supabase_deck_service.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.authService,
    this.deckService,
    this.categoryService,
  });

  // Tests can provide a fake, while the running app uses Supabase.
  final AuthService? authService;
  final DeckService? deckService;
  final CategoryService? categoryService;

  @override
  Widget build(BuildContext context) {
    final service = authService ?? SupabaseAuthService();
    final DeckService decks = deckService ?? SupabaseDeckService();
    final CategoryService categories =
        categoryService ??
        (decks is CategoryService
            ? decks as CategoryService
            : SupabaseCategoryService());

    return MaterialApp(
      title: 'FlashDeck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.deckListTheme(ThemeData(useMaterial3: true)),
      home: AuthGate(
        authService: service,
        deckService: decks,
        categoryService: categories,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.authService,
    required this.deckService,
    required this.categoryService,
    super.key,
  });

  final AuthService authService;
  final DeckService deckService;
  final CategoryService categoryService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _registrationInProgress = false;

  void _onRegistrationStarted() {
    if (!mounted) return;
    setState(() => _registrationInProgress = true);
  }

  void _onRegistrationFinished() {
    if (!mounted) return;
    setState(() => _registrationInProgress = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthSession?>(
      stream: widget.authService.authStateChanges,
      initialData: widget.authService.currentSession,
      builder: (context, snapshot) {
        // Supabase restores its saved session before runApp. A null initial
        // session means the login form can be shown immediately.
        final session = snapshot.data ?? widget.authService.currentSession;
        if (session == null || _registrationInProgress) {
          return AuthScreen(
            authService: widget.authService,
            onRegistrationStarted: _onRegistrationStarted,
            onRegistrationFinished: _onRegistrationFinished,
            callbackError: snapshot.hasError
                ? _authCallbackErrorMessage(snapshot.error)
                : null,
          );
        }

        // Changing users creates a fresh subtree and discards the previous
        // account's in-memory decks and navigation stack.
        return _SignedInHome(
          key: ValueKey(session.userId),
          authService: widget.authService,
          deckService: widget.deckService,
          categoryService: widget.categoryService,
        );
      },
    );
  }

  String _authCallbackErrorMessage(Object? error) {
    if (error is AuthException) {
      return 'ยืนยันอีเมลไม่สำเร็จ ลิงก์อาจหมดอายุหรือถูกใช้แล้ว '
          'โปรดขออีเมลยืนยันฉบับใหม่ แล้วเปิดลิงก์บนอุปกรณ์นี้';
    }
    return 'ตรวจสอบลิงก์ยืนยันอีเมลไม่สำเร็จ โปรดลองเปิดลิงก์อีกครั้ง '
        'หรือขออีเมลยืนยันฉบับใหม่';
  }
}

class _SignedInHome extends StatefulWidget {
  const _SignedInHome({
    required this.authService,
    required this.deckService,
    required this.categoryService,
    super.key,
  });

  final AuthService authService;
  final DeckService deckService;
  final CategoryService categoryService;

  @override
  State<_SignedInHome> createState() => _SignedInHomeState();
}

class _SignedInHomeState extends State<_SignedInHome> {
  List<FlashcardDeck> _decks = [];
  List<FlashcardCategory> _categories = [];
  bool _isLoadingDecks = true;
  bool _isLoadingCategories = true;
  String? _deckLoadError;
  String? _categoryLoadError;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadDecks();
    _loadCategories();
  }

  Future<void> _loadDecks() async {
    setState(() {
      _isLoadingDecks = true;
      _deckLoadError = null;
    });
    try {
      final decks = await widget.deckService.getDecks();
      if (!mounted) return;
      setState(() {
        _decks = decks;
        _isLoadingDecks = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _deckLoadError = 'โหลดชุดบัตรไม่สำเร็จ โปรดลองอีกครั้ง';
        _isLoadingDecks = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryLoadError = null;
    });
    try {
      final categories = await widget.categoryService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _categoryLoadError = 'โหลดหมวดหมู่ไม่สำเร็จ โปรดลองอีกครั้ง';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _saveDeck({
    FlashcardDeck? existingDeck,
    required String title,
    required String? categoryId,
    required String description,
  }) async {
    final savedDeck = await widget.deckService.saveDeck(
      id: existingDeck?.id,
      title: title,
      categoryId: categoryId,
      description: description,
    );
    if (!mounted) return;
    setState(() {
      if (existingDeck == null) {
        _decks.insert(0, savedDeck);
      } else {
        final index = _decks.indexWhere((deck) => deck.id == existingDeck.id);
        if (index != -1) _decks[index] = savedDeck;
      }
    });
  }

  Future<void> _createCategory(String name) async {
    final created = await widget.categoryService.createCategory(name);
    if (!mounted) return;
    setState(
      () => _categories = [..._categories, created]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }

  Future<void> _renameCategory({
    required String id,
    required String name,
  }) async {
    final renamed = await widget.categoryService.renameCategory(
      id: id,
      name: name,
    );
    if (!mounted) return;
    setState(() {
      final index = _categories.indexWhere((category) => category.id == id);
      if (index != -1) _categories[index] = renamed;
      _categories.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    });
  }

  Future<void> _deleteCategory(FlashcardCategory category) async {
    await widget.categoryService.deleteCategory(category.id);
    if (!mounted) return;
    setState(() {
      _categories.removeWhere((item) => item.id == category.id);
      for (final deck in _decks) {
        if (deck.categoryId == category.id) deck.categoryId = null;
      }
    });
  }

  Future<void> _deleteDeck(FlashcardDeck deck) async {
    await widget.deckService.deleteDeck(deck.id);
    if (!mounted) return;
    setState(() => _decks.removeWhere((item) => item.id == deck.id));
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ออกจากระบบไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      decks: _decks,
      isLoading: _isLoadingDecks,
      loadError: _deckLoadError,
      onRetry: _loadDecks,
      onSaveDeck: _saveDeck,
      onDeleteDeck: _deleteDeck,
      categories: _categories,
      isLoadingCategories: _isLoadingCategories,
      categoryLoadError: _categoryLoadError,
      onRetryCategories: _loadCategories,
      onCreateCategory: _createCategory,
      onRenameCategory: _renameCategory,
      onDeleteCategory: _deleteCategory,
      onOpenDeck: (deck) {
        // Pushing a route is similar to opening a new page in a web app.
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/cards'),
            builder: (_) => CardListScreen(
              deck: deck,
              categoryLabel: _categoryLabel(deck.categoryId),
              deckService: widget.deckService,
              onDeckChanged: () => setState(() {}),
            ),
          ),
        );
      },
      onSignOut: _signOut,
      isSigningOut: _isSigningOut,
    );
  }

  String _categoryLabel(String? categoryId) {
    if (categoryId == null) return 'ยังไม่จัดหมวด';
    for (final category in _categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'ยังไม่จัดหมวด';
  }
}
