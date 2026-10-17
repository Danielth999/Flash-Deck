import 'package:flutter_test/flutter_test.dart';
import 'package:flash_deck/algorithms/review_session.dart';
import 'package:flash_deck/models/flashcard.dart';

void main() {
  group('ReviewSession', () {
    test('remembered cards are removed from the queue', () {
      final cards = _cards();
      final session = ReviewSession(cards);

      expect(session.currentCard?.id, 'a');
      expect(session.revealAnswer(), isTrue);
      expect(session.answerCurrent(remembered: true), isFalse);
      expect(session.isFinished, isFalse);

      expect(session.queuedCards.map((card) => card.id), ['b']);
      expect(session.rememberedCardIds, {'a'});
      expect(session.attempts, 1);
      expect(cards.map((card) => card.id), ['a', 'b']);
    });

    test('not remembered cards move to the end of the queue', () {
      final session = ReviewSession(_cards());
      session.revealAnswer();

      expect(session.answerCurrent(remembered: false), isFalse);
      expect(session.queuedCards.map((card) => card.id), ['b', 'a']);
      expect(session.currentCard?.id, 'b');
      expect(session.answerVisible, isFalse);
      expect(session.rememberedCards, 0);
      expect(session.attempts, 1);
    });

    test('a retried card is counted once after it is remembered', () {
      final session = ReviewSession([_card('a')]);
      session
        ..revealAnswer()
        ..answerCurrent(remembered: false)
        ..revealAnswer();

      expect(session.answerCurrent(remembered: true), isTrue);
      expect(session.rememberedCards, 1);
      expect(session.rememberedCardIds, {'a'});
      expect(session.attempts, 2);
      expect(session.remainingCards, 0);
    });

    test('the round can end before the queue is empty', () {
      final session = ReviewSession(_cards());
      session
        ..revealAnswer()
        ..answerCurrent(remembered: true);

      expect(session.finishRound(), isTrue);
      expect(session.finishRound(), isFalse);
      expect(session.isFinished, isTrue);
      expect(session.queuedCards, hasLength(1));
      expect(session.result.totalCards, 2);
      expect(session.result.rememberedCards, 1);
      expect(session.result.remainingCards, 1);
      expect(session.result.attempts, 1);
    });

    test('empty and single-card queues behave safely', () {
      final empty = ReviewSession([]);
      expect(empty.currentCard, isNull);
      expect(empty.revealAnswer(), isFalse);
      expect(empty.answerCurrent(remembered: true), isFalse);
      expect(empty.finishRound(), isTrue);
      expect(empty.result.totalCards, 0);
      expect(empty.result.remainingCards, 0);

      final single = ReviewSession([_card('only')]);
      expect(single.answerCurrent(remembered: true), isFalse);
      expect(single.attempts, 0);
      single.revealAnswer();
      expect(single.answerCurrent(remembered: true), isTrue);
      expect(single.answerCurrent(remembered: true), isFalse);
      expect(single.result.totalCards, 1);
      expect(single.result.rememberedCards, 1);
      expect(single.result.remainingCards, 0);
      expect(single.result.attempts, 1);
    });

    test('starting a new round resets all state from the previous round', () {
      final source = _cards();
      final session = ReviewSession(source);
      session
        ..revealAnswer()
        ..answerCurrent(remembered: true)
        ..revealAnswer()
        ..finishRound();

      session.startNewRound();

      expect(session.queuedCards.map((card) => card.id), ['a', 'b']);
      expect(session.currentCard?.id, 'a');
      expect(session.rememberedCardIds, isEmpty);
      expect(session.attempts, 0);
      expect(session.answerVisible, isFalse);
      expect(session.isFinished, isFalse);
      expect(source.map((card) => card.id), ['a', 'b']);
    });
  });
}

List<Flashcard> _cards() => [_card('a'), _card('b')];

Flashcard _card(String id) =>
    Flashcard(id: id, question: 'Question $id', answer: 'Answer $id');
