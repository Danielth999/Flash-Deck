import 'package:flutter_test/flutter_test.dart';
import 'package:flash_deck/algorithms/insertion_sort.dart';
import 'package:flash_deck/models/flashcard.dart';

void main() {
  group('insertionSortCardsByQuestion', () {
    test('returns an empty list for empty input', () {
      expect(insertionSortCardsByQuestion([]), isEmpty);
    });

    test('returns the single card unchanged', () {
      final card = _card('one', 'Only question');

      final sorted = insertionSortCardsByQuestion([card]);

      expect(sorted, [same(card)]);
    });

    test('keeps cards that are already sorted', () {
      final cards = [_card('a', 'Alpha'), _card('b', 'Bravo')];

      final sorted = insertionSortCardsByQuestion(cards);

      expect(sorted.map((card) => card.question), ['Alpha', 'Bravo']);
    });

    test('sorts cards that are in reverse order', () {
      final cards = [
        _card('c', 'Charlie'),
        _card('b', 'Bravo'),
        _card('a', 'Alpha'),
      ];

      final sorted = insertionSortCardsByQuestion(cards);

      expect(sorted.map((card) => card.question), [
        'Alpha',
        'Bravo',
        'Charlie',
      ]);
    });

    test('preserves original order for duplicate questions', () {
      final first = _card('first', 'Same');
      final middle = _card('middle', 'Other');
      final second = _card('second', 'Same');

      final sorted = insertionSortCardsByQuestion([first, middle, second]);

      expect(sorted.map((card) => card.id), ['middle', 'first', 'second']);
    });

    test('returns a new list without modifying its input', () {
      final first = _card('b', 'Bravo');
      final second = _card('a', 'Alpha');
      final input = [first, second];

      final sorted = insertionSortCardsByQuestion(input);

      expect(sorted, isNot(same(input)));
      expect(input, [same(first), same(second)]);
      expect(sorted, [same(second), same(first)]);
    });
  });
}

Flashcard _card(String id, String question) =>
    Flashcard(id: id, question: question, answer: 'Answer $id');
