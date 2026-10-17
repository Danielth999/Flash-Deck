import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import 'deck_service.dart';

class SupabaseDeckService implements DeckService {
  SupabaseDeckService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _deckSelection =
      'id,title,category_id,description,cards(count)';

  @override
  Future<List<FlashcardDeck>> getDecks() async {
    final rows = await _client
        .from('decks')
        .select(_deckSelection)
        .order('created_at', ascending: false);
    return rows.map(_toDeck).toList();
  }

  @override
  Future<FlashcardDeck> saveDeck({
    String? id,
    required String title,
    required String? categoryId,
    required String description,
  }) async {
    final values = {
      'title': title.trim(),
      'category_id': categoryId,
      'description': description.trim(),
    };
    final row = id == null
        ? await _client.from('decks').insert(values).select(_deckSelection).single()
        : await _client
              .from('decks')
              .update(values)
              .eq('id', id)
              .select(_deckSelection)
              .single();
    return _toDeck(row);
  }

  @override
  Future<void> deleteDeck(String id) async {
    await _client.from('decks').delete().eq('id', id);
  }

  @override
  Future<List<Flashcard>> getCards(String deckId) async {
    final rows = await _client
        .from('cards')
        .select('id,question,answer')
        .eq('deck_id', deckId)
        .order('created_at', ascending: true);
    return rows
        .map(
          (row) => Flashcard(
            id: row['id'] as String,
            question: row['question'] as String,
            answer: row['answer'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<Flashcard> saveCard({
    String? id,
    required String deckId,
    required String question,
    required String answer,
  }) async {
    final values = {
      'deck_id': deckId,
      'question': question.trim(),
      'answer': answer.trim(),
    };
    final row = id == null
        ? await _client.from('cards').insert(values).select().single()
        : await _client
              .from('cards')
              .update({'question': values['question'], 'answer': values['answer']})
              .eq('id', id)
              .eq('deck_id', deckId)
              .select()
              .single();
    return Flashcard(
      id: row['id'] as String,
      question: row['question'] as String,
      answer: row['answer'] as String,
    );
  }

  @override
  Future<void> deleteCard({required String id, required String deckId}) async {
    await _client.from('cards').delete().eq('id', id).eq('deck_id', deckId);
  }

  FlashcardDeck _toDeck(Map<String, dynamic> row) {
    final relatedCards = row['cards'] as List<dynamic>? ?? const [];
    final cardCount = relatedCards.isEmpty
        ? 0
        : (relatedCards.first as Map<String, dynamic>)['count'] as int? ?? 0;

    return FlashcardDeck(
      id: row['id'] as String,
      title: row['title'] as String,
      categoryId: row['category_id'] as String?,
      description: row['description'] as String,
      cardCount: cardCount,
    );
  }
}
