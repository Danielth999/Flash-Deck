import '../models/flashcard.dart';

List<Flashcard> insertionSortCardsByQuestion(List<Flashcard> cards) {
  final sorted = List<Flashcard>.of(cards);

  // Shift larger questions right; insertion sort is worst-case O(n²).
  for (var index = 1; index < sorted.length; index++) {
    final card = sorted[index];
    var position = index - 1;
    while (position >= 0 &&
        sorted[position].question.compareTo(card.question) > 0) {
      sorted[position + 1] = sorted[position];
      position--;
    }
    sorted[position + 1] = card;
  }

  return sorted;
}
