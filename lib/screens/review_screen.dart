import 'package:flutter/material.dart';

import '../algorithms/review_session.dart';
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../theme/app_theme.dart';
import 'review_result_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({required this.deck, super.key});

  final FlashcardDeck deck;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late final ReviewSession _session;
  late final AnimationController _motionController;
  bool _resultOpened = false;
  bool _showResult = false;
  bool _isTransitioning = false;
  bool _isReturning = false;
  double _dragX = 0;
  double _motionStartX = 0;
  double _motionDirection = 0;

  @override
  void initState() {
    super.initState();
    _session = ReviewSession(widget.deck.cards);
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    );
    if (_session.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openResult(_session.finishRound());
      });
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  void _updateDrag(DragUpdateDetails details) {
    if (_isTransitioning || !_session.answerVisible) return;
    setState(() {
      _dragX = (_dragX + details.delta.dx).clamp(-10000, 10000).toDouble();
    });
  }

  void _endDrag(double cardWidth) {
    if (_isTransitioning || !_session.answerVisible) return;
    if (_dragX.abs() >= cardWidth * 0.25) {
      _submitAnswer(remembered: _dragX > 0, cardWidth: cardWidth);
    } else {
      _returnCardToCenter();
    }
  }

  Future<void> _returnCardToCenter() async {
    if (_dragX == 0 || _isTransitioning) return;
    final startX = _dragX;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _isTransitioning = true;
      _isReturning = true;
      _motionStartX = startX;
    });
    if (reduceMotion) {
      _motionController.value = 1;
    } else {
      await _motionController.forward(from: 0);
    }
    if (!mounted) return;
    _motionController.reset();
    setState(() {
      _dragX = 0;
      _motionStartX = 0;
      _motionDirection = 0;
      _isReturning = false;
      _isTransitioning = false;
    });
  }

  Future<void> _submitAnswer({
    required bool remembered,
    required double cardWidth,
  }) async {
    final Flashcard? submittedCard = _session.currentCard;
    if (submittedCard == null || !_session.answerVisible || _isTransitioning) {
      return;
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _isTransitioning = true;
      _isReturning = false;
      _motionStartX = _dragX;
      _motionDirection = remembered ? 1 : -1;
    });

    if (reduceMotion) {
      _motionController.value = 1;
    } else {
      await _motionController.forward(from: 0);
    }
    if (!mounted) return;

    // A stale animation callback must never submit against a different card.
    if (!identical(_session.currentCard, submittedCard)) {
      _motionController.reset();
      setState(() {
        _dragX = 0;
        _motionStartX = 0;
        _motionDirection = 0;
        _isReturning = false;
        _isTransitioning = false;
      });
      return;
    }

    final finished = _session.answerCurrent(remembered: remembered);
    _motionController.reset();
    setState(() {
      _dragX = 0;
      _motionStartX = 0;
      _motionDirection = 0;
      _isTransitioning = false;
    });
    if (finished) _openResult(true);
  }

  Future<void> _confirmEndRound() async {
    if (_session.isFinished || _isTransitioning) return;
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('จบรอบตอนนี้?'),
        content: const Text('ผลลัพธ์จะแสดงตามบัตรที่ตอบไปแล้วในรอบนี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ทำต่อ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('จบรอบ'),
          ),
        ],
      ),
    );
    if (shouldEnd != true || !mounted) return;
    _openResult(_session.finishRound());
  }

  void _openResult(bool justFinished) {
    if (!justFinished || _resultOpened || !mounted) return;
    _resultOpened = true;
    setState(() {
      _showResult = true;
      _isTransitioning = false;
      _dragX = 0;
      _motionStartX = 0;
      _motionDirection = 0;
    });
  }

  void _restartRound() {
    if (!mounted) return;
    _session.startNewRound();
    _motionController.reset();
    setState(() {
      _resultOpened = false;
      _showResult = false;
      _isTransitioning = false;
      _isReturning = false;
      _dragX = 0;
      _motionStartX = 0;
      _motionDirection = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return Theme(
        data: AppTheme.deckListTheme(Theme.of(context)),
        child: ReviewResultScreen(
          deck: widget.deck,
          result: _session.result,
          onRestart: _restartRound,
          onBackToCards: () => Navigator.of(context).pop(),
        ),
      );
    }
    final card = _session.currentCard;
    final totalCards = _session.totalCards;
    final progress = totalCards == 0
        ? 0.0
        : _session.rememberedCards / totalCards;

    return Theme(
      data: AppTheme.deckListTheme(Theme.of(context)),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('ทบทวน'),
            actions: [
              TextButton(
                key: const ValueKey('end-review-button'),
                onPressed: _session.isFinished || _isTransitioning
                    ? null
                    : _confirmEndRound,
                child: const Text('จบรอบตอนนี้'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: card == null
              ? const Center(child: Text('ไม่มีบัตรสำหรับทบทวน'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      widget.deck.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'จำได้ ${_session.rememberedCards} / $totalCards',
                      key: const ValueKey('review-progress'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radius24),
                      child: LinearProgressIndicator(
                        key: const ValueKey('review-progress-bar'),
                        value: progress,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'เหลือในคิว ${_session.queuedCards.length} ใบ · '
                      'ตอบแล้ว ${_session.attempts} ครั้ง',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth;
                        return GestureDetector(
                          key: const ValueKey('review-card'),
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: _isTransitioning
                              ? null
                              : _updateDrag,
                          onHorizontalDragEnd: _isTransitioning
                              ? null
                              : (_) => _endDrag(cardWidth),
                          child: AnimatedBuilder(
                            animation: _motionController,
                            builder: (context, child) {
                              final t = Curves.easeOutCubic.transform(
                                _motionController.value,
                              );
                              final offsetX = _isReturning
                                  ? _motionStartX * (1 - t)
                                  : _motionStartX +
                                        _motionDirection * (cardWidth + 48) * t;
                              final rotation = (offsetX / cardWidth * 0.08)
                                  .clamp(-0.08, 0.08)
                                  .toDouble();
                              return Transform.translate(
                                key: const ValueKey('review-card-transform'),
                                offset: Offset(offsetX, 0),
                                child: Transform.rotate(
                                  angle: rotation,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildReviewCard(context, card),
                          ),
                        );
                      },
                    ),
                    if (_session.answerVisible) ...[
                      const SizedBox(height: AppTheme.space16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('not-remembered-button'),
                              onPressed: _isTransitioning
                                  ? null
                                  : () => _submitAnswer(
                                      remembered: false,
                                      cardWidth:
                                          MediaQuery.sizeOf(context).width - 40,
                                    ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('ทบทวนอีก'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Expanded(
                            child: FilledButton.icon(
                              key: const ValueKey('remembered-button'),
                              onPressed: _isTransitioning
                                  ? null
                                  : () => _submitAnswer(
                                      remembered: true,
                                      cardWidth:
                                          MediaQuery.sizeOf(context).width - 40,
                                    ),
                              icon: const Icon(Icons.check),
                              label: const Text('จำได้'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Flashcard card) {
    final direction = _dragX == 0 ? 0 : _dragX.sign;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          children: [
            if (direction != 0 && _session.answerVisible)
              Align(
                alignment: direction > 0
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: _SwipeLabel(remembered: direction > 0),
              ),
            if (direction != 0 && _session.answerVisible)
              const SizedBox(height: AppTheme.space8),
            Text(
              'คำถาม',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              card.question,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700, height: 1.35),
            ),
            if (_session.answerVisible) ...[
              const Divider(height: AppTheme.space32),
              Text(
                'คำตอบ',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                card.answer,
                key: const ValueKey('review-answer'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(height: 1.4),
              ),
            ],
            const SizedBox(height: AppTheme.space16),
            OutlinedButton.icon(
              key: const ValueKey('reveal-answer-button'),
              onPressed: _session.answerVisible || _isTransitioning
                  ? null
                  : () => setState(_session.revealAnswer),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(
                _session.answerVisible ? 'คำตอบที่แสดง' : 'เปิดคำตอบ',
              ),
            ),
            if (!_session.answerVisible)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.space8),
                child: Text(
                  'เปิดคำตอบก่อน แล้วเลือกปุ่มหรือปัดการ์ด',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({required this.remembered});

  final bool remembered;

  @override
  Widget build(BuildContext context) {
    final color = remembered ? AppTheme.green : AppTheme.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: remembered ? AppTheme.greenSoft : AppTheme.orangeSoft,
        borderRadius: BorderRadius.circular(AppTheme.radius24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            remembered ? Icons.check_circle_outline : Icons.refresh,
            color: color,
            size: 18,
          ),
          const SizedBox(width: AppTheme.space8),
          Text(
            remembered ? 'จำได้' : 'ทบทวนอีก',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
