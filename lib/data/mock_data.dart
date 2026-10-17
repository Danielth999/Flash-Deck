import '../models/flashcard.dart';
import '../models/flashcard_category.dart';
import '../models/flashcard_deck.dart';

const mockCategoryGeneral = 'mock-category-general';
const mockCategoryLanguage = 'mock-category-language';
const mockCategoryComputer = 'mock-category-computer';
const mockCategoryMath = 'mock-category-math';
const mockCategoryScience = 'mock-category-science';

List<FlashcardCategory> createMockCategories() => const [
  FlashcardCategory(id: mockCategoryGeneral, name: 'ทั่วไป'),
  FlashcardCategory(id: mockCategoryLanguage, name: 'ภาษา'),
  FlashcardCategory(id: mockCategoryComputer, name: 'คอมพิวเตอร์'),
  FlashcardCategory(id: mockCategoryMath, name: 'คณิตศาสตร์'),
  FlashcardCategory(id: mockCategoryScience, name: 'วิทยาศาสตร์'),
];

// Return fresh objects so edits in one app run do not alter the sample defaults.
List<FlashcardDeck> createMockDecks() {
  return [
    FlashcardDeck(
      id: 'english',
      title: 'ภาษาอังกฤษพื้นฐาน',
      categoryId: mockCategoryLanguage,
      description: 'คำศัพท์ที่ใช้บ่อยในชีวิตประจำวัน',
      cards: [
        Flashcard(
          id: 'english-1',
          question: 'What does “curious” mean?',
          answer: 'อยากรู้อยากเห็น',
        ),
        Flashcard(
          id: 'english-2',
          question: 'What does “reliable” mean?',
          answer: 'เชื่อถือได้',
        ),
      ],
    ),
    FlashcardDeck(
      id: 'computer-science',
      title: 'โครงสร้างข้อมูล',
      categoryId: mockCategoryComputer,
      description: 'แนวคิดพื้นฐานสำหรับทบทวน',
      cards: [
        Flashcard(
          id: 'computer-1',
          question: 'Queue ใช้หลักการใด?',
          answer: 'FIFO — เข้าก่อนออกก่อน',
        ),
      ],
    ),
    FlashcardDeck(
      id: 'science',
      title: 'วิทยาศาสตร์รอบตัว',
      categoryId: mockCategoryScience,
      description: 'คำถามสั้น ๆ สำหรับทบทวน',
    ),
  ];
}
