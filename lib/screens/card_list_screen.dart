import 'package:flutter/material.dart';

import '../algorithms/insertion_sort.dart';
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state.dart';
import 'card_editor_screen.dart';
import 'review_screen.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({
    required this.deck,
    this.categoryLabel = 'ยังไม่จัดหมวด',
    required this.deckService,
    required this.onDeckChanged,
    super.key,
  });

  final FlashcardDeck deck;
  final String categoryLabel;
  final DeckService deckService;
  final VoidCallback onDeckChanged;

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  List<Flashcard> _cards = [];
  String _query = '';
  bool _sortByQuestion = false;
  bool _isLoading = true;
  String? _loadError;
  final Set<String> _deletingCardIds = {};

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final cards = await widget.deckService.getCards(widget.deck.id);
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _syncDeckCards();
        _isLoading = false;
      });
      widget.onDeckChanged();
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดบัตรคำไม่สำเร็จ โปรดลองอีกครั้ง';
        _isLoading = false;
      });
    }
  }

  void _syncDeckCards() {
    widget.deck.cards
      ..clear()
      ..addAll(_cards);
    widget.deck.cardCount = _cards.length;
  }

  Future<void> _openEditor({Flashcard? card}) async {
    final savedCard = await Navigator.of(context).push<Flashcard>(
      MaterialPageRoute<Flashcard>(
        builder: (_) => CardEditorScreen(
          card: card,
          onSave: (candidate) => widget.deckService.saveCard(
            id: card?.id,
            deckId: widget.deck.id,
            question: candidate.question,
            answer: candidate.answer,
          ),
        ),
      ),
    );
    if (!mounted || savedCard == null) return;

    setState(() {
      final index = _cards.indexWhere((item) => item.id == savedCard.id);
      if (index == -1) {
        _cards.add(savedCard);
      } else {
        _cards[index] = savedCard;
      }
      _syncDeckCards();
    });
    widget.onDeckChanged();
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/review'),
        builder: (_) => ReviewScreen(deck: widget.deck),
      ),
    );
  }

  Future<void> _confirmDeleteCard(Flashcard card) async {
    if (_deletingCardIds.contains(card.id)) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบบัตรคำ?'),
        content: const Text('บัตรคำนี้จะถูกลบถาวร'),
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

    setState(() => _deletingCardIds.add(card.id));
    try {
      await widget.deckService.deleteCard(id: card.id, deckId: widget.deck.id);
      if (!mounted) return;
      setState(() {
        _cards.removeWhere((item) => item.id == card.id);
        _deletingCardIds.remove(card.id);
        _syncDeckCards();
      });
      widget.onDeckChanged();
    } on Exception {
      if (!mounted) return;
      setState(() => _deletingCardIds.remove(card.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบบัตรคำไม่สำเร็จ โปรดลองอีกครั้ง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredCards = _cards.where((card) {
      return card.question.toLowerCase().contains(query) ||
          card.answer.toLowerCase().contains(query);
    }).toList();
    final visibleCards = _sortByQuestion
        ? insertionSortCardsByQuestion(filteredCards)
        : filteredCards;

    return Scaffold(
      appBar: AppBar(title: Text(widget.deck.title)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space8,
            AppTheme.space20,
            AppTheme.space12,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('add-card-button'),
                  onPressed: _isLoading || _loadError != null
                      ? null
                      : _openEditor,
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มบัตร'),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('start-review-button'),
                  onPressed:
                      _isLoading || _loadError != null || _cards.isEmpty
                      ? null
                      : _openReview,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('เริ่มทบทวน'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CategoryChip(label: widget.categoryLabel),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'บัตรคำ (${_cards.length})',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTheme.space16),
          TextField(
            key: const ValueKey('card-search-field'),
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'ค้นหาคำถามหรือคำตอบ',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              Text('เรียงบัตร', style: Theme.of(context).textTheme.labelLarge),
              DropdownButton<bool>(
                key: const ValueKey('card-sort-dropdown'),
                value: _sortByQuestion,
                onChanged: (value) {
                  if (value != null) setState(() => _sortByQuestion = value);
                },
                items: const [
                  DropdownMenuItem(value: false, child: Text('ลำดับเดิม')),
                  DropdownMenuItem(value: true, child: Text('คำถาม A–Z')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space20),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 36),
                    const SizedBox(height: AppTheme.space8),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: AppTheme.space12),
                    FilledButton.icon(
                      onPressed: _loadCards,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            )
          else if (visibleCards.isEmpty)
            EmptyState(
              icon: Icons.style_outlined,
              title: _cards.isEmpty ? 'ชุดนี้ยังไม่มีบัตรคำ' : 'ไม่พบบัตรคำ',
              message: _cards.isEmpty
                  ? 'เพิ่มบัตรคำเพื่อเริ่มต้น'
                  : 'ลองค้นหาด้วยคำอื่น',
              showMascot: _cards.isEmpty,
            )
          else
            ...visibleCards.map(
              (card) => Card(
                key: ValueKey('card-${card.id}'),
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'คำถาม',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Text(
                              card.question,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.space12),
                            Text(
                              'คำตอบ',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Text(card.answer),
                          ],
                        ),
                      ),
                      if (_deletingCardIds.contains(card.id))
                        const Padding(
                          padding: EdgeInsets.all(AppTheme.space12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        PopupMenuButton<String>(
                          tooltip: 'จัดการบัตรคำ',
                          onSelected: (value) {
                            if (value == 'edit') _openEditor(card: card);
                            if (value == 'delete') _confirmDeleteCard(card);
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
            ),
        ],
      ),
    );
  }
}
