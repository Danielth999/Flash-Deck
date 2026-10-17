import 'flashcard.dart';

class FlashcardDeck {
  FlashcardDeck({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.description,
    List<Flashcard>? cards,
    this.cardCount,
  }) : cards = cards ?? [];

  final String id;
  String title;
  String? categoryId;
  String description;
  final List<Flashcard> cards;
  int? cardCount;

  int get totalCardCount => cardCount ?? cards.length;
}
