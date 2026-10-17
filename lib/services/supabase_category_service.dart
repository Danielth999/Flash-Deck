import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/flashcard_category.dart';
import 'category_service.dart';

class SupabaseCategoryService implements CategoryService {
  SupabaseCategoryService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<FlashcardCategory>> getCategories() async {
    final rows = await _client
        .from('categories')
        .select('id,name')
        .order('name', ascending: true);
    return rows
        .map(
          (row) => FlashcardCategory(
            id: row['id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<FlashcardCategory> createCategory(String name) async {
    final cleanName = _validatedName(name);
    try {
      final row = await _client
          .from('categories')
          .insert({'name': cleanName})
          .select('id,name')
          .single();
      return _toCategory(row);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const CategoryNameAlreadyExistsException();
      }
      rethrow;
    }
  }

  @override
  Future<FlashcardCategory> renameCategory({
    required String id,
    required String name,
  }) async {
    final cleanName = _validatedName(name);
    try {
      final row = await _client
          .from('categories')
          .update({'name': cleanName})
          .eq('id', id)
          .select('id,name')
          .single();
      return _toCategory(row);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const CategoryNameAlreadyExistsException();
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  String _validatedName(String value) {
    final name = value.trim();
    if (name.isEmpty || name.runes.length > 50) {
      throw const CategoryNameValidationException();
    }
    return name;
  }

  FlashcardCategory _toCategory(Map<String, dynamic> row) =>
      FlashcardCategory(id: row['id'] as String, name: row['name'] as String);
}
