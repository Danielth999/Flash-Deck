import '../models/flashcard_category.dart';

abstract interface class CategoryService {
  Future<List<FlashcardCategory>> getCategories();

  Future<FlashcardCategory> createCategory(String name);

  Future<FlashcardCategory> renameCategory({
    required String id,
    required String name,
  });

  Future<void> deleteCategory(String id);
}

class CategoryNameAlreadyExistsException implements Exception {
  const CategoryNameAlreadyExistsException();
}

class CategoryNameValidationException implements Exception {
  const CategoryNameValidationException();
}
