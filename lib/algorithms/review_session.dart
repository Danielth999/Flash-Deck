import 'dart:collection';

import '../models/flashcard.dart';

class ReviewResult {
  const ReviewResult({
    required this.totalCards,
    required this.rememberedCards,
    required this.remainingCards,
    required this.attempts,
  });

  final int totalCards;
  final int rememberedCards;
  final int remainingCards;
  final int attempts;
}

class ReviewSession {
  ReviewSession(List<Flashcard> cards) : _sourceCards = List.of(cards) {
    _startRound();
  }

  final List<Flashcard> _sourceCards;
  late Queue<Flashcard> _queue;
  Set<String> _rememberedCardIds = {};
  int _attempts = 0;
  bool _answerVisible = false;
  bool _isFinished = false;

  int get totalCards => _sourceCards.length;
  int get rememberedCards => _rememberedCardIds.length;
  int get remainingCards => totalCards - rememberedCards;
  int get attempts => _attempts;
  bool get answerVisible => _answerVisible;
  bool get isFinished => _isFinished;
  bool get isEmpty => _queue.isEmpty;
  Flashcard? get currentCard => _queue.isEmpty ? null : _queue.first;

  List<Flashcard> get queuedCards => List.unmodifiable(_queue);
  Set<String> get rememberedCardIds => Set.unmodifiable(_rememberedCardIds);

  bool revealAnswer() {
    if (_isFinished || _queue.isEmpty || _answerVisible) return false;
    _answerVisible = true;
    return true;
  }

  /// Returns true only on the action that finishes the round.
  bool answerCurrent({required bool remembered}) {
    if (_isFinished || _queue.isEmpty || !_answerVisible) return false;

    final card = _queue.removeFirst();
    _attempts++;
    if (remembered) {
      _rememberedCardIds.add(card.id);
    } else {
      _queue.addLast(card);
    }
    _answerVisible = false;

    if (_queue.isEmpty) {
      _isFinished = true;
      return true;
    }
    return false;
  }

  /// Returns true only the first time the round is ended.
  bool finishRound() {
    if (_isFinished) return false;
    _isFinished = true;
    _answerVisible = false;
    return true;
  }

  ReviewResult get result => ReviewResult(
    totalCards: totalCards,
    rememberedCards: rememberedCards,
    remainingCards: remainingCards,
    attempts: attempts,
  );

  void startNewRound() => _startRound();

  void _startRound() {
    _queue = Queue<Flashcard>.from(_sourceCards);
    _rememberedCardIds = {};
    _attempts = 0;
    _answerVisible = false;
    _isFinished = false;
  }
}
