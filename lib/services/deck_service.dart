import '../models/flashcard_deck.dart';
import '../models/flashcard.dart';

abstract interface class DeckService {
  Future<List<FlashcardDeck>> getDecks();

  Future<FlashcardDeck> saveDeck({
    String? id,
    required String title,
    required String? categoryId,
    required String description,
  });

  Future<void> deleteDeck(String id);

  Future<List<Flashcard>> getCards(String deckId);

  Future<Flashcard> saveCard({
    String? id,
    required String deckId,
    required String question,
    required String answer,
  });

  Future<void> deleteCard({required String id, required String deckId});
}
