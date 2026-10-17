import 'package:flutter/material.dart';

import '../algorithms/review_session.dart';
import '../models/flashcard_deck.dart';
import '../theme/app_theme.dart';
import '../widgets/flashdeck_mascot.dart';

class ReviewResultScreen extends StatelessWidget {
  const ReviewResultScreen({
    required this.deck,
    required this.result,
    required this.onRestart,
    this.onBackToCards,
    super.key,
  });

  final FlashcardDeck deck;
  final ReviewResult result;
  final VoidCallback onRestart;
  final VoidCallback? onBackToCards;

  @override
  Widget build(BuildContext context) {
    final progress = result.totalCards == 0
        ? 0.0
        : result.rememberedCards / result.totalCards;

    return Scaffold(
      appBar: AppBar(title: const Text('ผลการทบทวน')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .82, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const FlashDeckMascot(size: 104),
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            result.remainingCards == 0 ? 'ทบทวนครบแล้ว' : 'จบรอบก่อนกำหนด',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            deck.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTheme.space24),
          Text(
            'จำได้ ${result.rememberedCards} จาก ${result.totalCards} ใบ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius24),
            child: Semantics(
              label: 'ความคืบหน้าการจำได้',
              value: '${result.rememberedCards} จาก ${result.totalCards}',
              child: LinearProgressIndicator(value: progress, minHeight: 10),
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          _ResultRow(label: 'บัตรทั้งหมด', value: result.totalCards),
          const SizedBox(height: AppTheme.space8),
          _ResultRow(label: 'จำได้', value: result.rememberedCards),
          const SizedBox(height: AppTheme.space8),
          _ResultRow(label: 'เหลือ', value: result.remainingCards),
          const SizedBox(height: AppTheme.space8),
          _ResultRow(label: 'จำนวนครั้งที่ตอบ', value: result.attempts),
          const SizedBox(height: AppTheme.space24),
          FilledButton.icon(
            key: const ValueKey('restart-review-button'),
            onPressed: onRestart,
            icon: const Icon(Icons.refresh),
            label: const Text('ทบทวนใหม่'),
          ),
          const SizedBox(height: AppTheme.space8),
          OutlinedButton.icon(
            key: const ValueKey('back-to-cards-button'),
            onPressed:
                onBackToCards ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.style_outlined),
            label: const Text('กลับชุดบัตร'),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(label),
        trailing: Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
