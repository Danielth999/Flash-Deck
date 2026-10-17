import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flash_deck/algorithms/review_session.dart';
import 'package:flash_deck/app.dart';
import 'package:flash_deck/data/mock_data.dart';
import 'package:flash_deck/models/flashcard.dart';
import 'package:flash_deck/models/flashcard_category.dart';
import 'package:flash_deck/models/flashcard_deck.dart';
import 'package:flash_deck/screens/auth_screen.dart';
import 'package:flash_deck/screens/card_editor_screen.dart';
import 'package:flash_deck/screens/card_list_screen.dart';
import 'package:flash_deck/screens/deck_list_screen.dart';
import 'package:flash_deck/screens/review_screen.dart';
import 'package:flash_deck/screens/review_result_screen.dart';
import 'package:flash_deck/services/auth_service.dart';
import 'package:flash_deck/services/category_service.dart';
import 'package:flash_deck/services/deck_service.dart';

import 'dart:async';

void main() {
  testWidgets('shows the friendly deck loading state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeckListScreen(
          decks: const [],
          isLoading: true,
          onRetry: () {},
          onSaveDeck:
              ({
                FlashcardDeck? existingDeck,
                required String title,
                required String? categoryId,
                required String description,
              }) async => FlashcardDeck(
                id: 'new-deck',
                title: title,
                categoryId: categoryId,
                description: description,
              ),
          onDeleteDeck: (_) async {},
          onOpenDeck: (_, _) {},
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('กำลังเตรียมชุดบัตรของคุณ...'), findsOneWidget);
  });

  testWidgets('shows an inviting empty state and creates the first deck', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService(decks: [], categories: []);
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();

    expect(find.text('เริ่มชุดบัตรแรกของคุณ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('empty-create-deck-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'ชุดแรกของฉัน');
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('ชุดแรกของฉัน'), findsOneWidget);
    expect(find.text('1 ชุด'), findsOneWidget);
  });

  testWidgets('long deck copy wraps without layout exceptions', (tester) async {
    final authService = FakeAuthService.signedIn();
    final deck = FlashcardDeck(
      id: 'long-deck',
      title: 'ชุดทบทวนคำศัพท์และแนวคิดสำคัญสำหรับการเรียนในภาคการศึกษานี้',
      categoryId: mockCategoryLanguage,
      description: 'คำอธิบายสำหรับชุดบัตรที่ยาวขึ้น เพื่อให้ผู้เรียนเข้าใจเนื้อหาและจุดประสงค์ของชุดนี้ได้ชัดเจน',
      cardCount: 6,
    );
    final deckService = FakeDeckService(decks: [deck]);
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();

    expect(find.text(deck.title), findsOneWidget);
    expect(find.text(deck.description), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters decks and creates a deck without a category', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('คอมพิวเตอร์').first);
    await tester.pumpAndSettle();
    expect(find.text('โครงสร้างข้อมูล'), findsOneWidget);
    expect(find.text('ภาษาอังกฤษพื้นฐาน'), findsNothing);

    await tester.tap(find.text('ทั้งหมด'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-deck-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'ชุดทดสอบ');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'ชุดทดสอบ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('4 ชุด'), findsOneWidget);
    expect(deckService.decks.first.categoryId, isNull);
  });

  testWidgets('category names are trimmed and duplicate errors are readable', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService(decks: [], categories: []);
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-categories')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-category-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-field')),
      '  ภาษาใหม่  ',
    );
    await tester.tap(find.byKey(const ValueKey('save-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('ภาษาใหม่'), findsOneWidget);

    final renamedCategoryMenu = find.descendant(
      of: find.byKey(const ValueKey('category-category-0')),
      matching: find.byTooltip('จัดการหมวดหมู่'),
    );
    await tester.ensureVisible(renamedCategoryMenu);
    await tester.tap(renamedCategoryMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('เปลี่ยนชื่อ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-field')),
      'Flash',
    );
    await tester.tap(find.byKey(const ValueKey('save-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('Flash'), findsOneWidget);
    expect(find.text('ภาษาใหม่'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('add-category-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('category-name-field')),
      ' fLaSh ',
    );
    await tester.tap(find.byKey(const ValueKey('save-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('มีหมวดหมู่ชื่อนี้ในบัญชีแล้ว'), findsOneWidget);
  });

  testWidgets('deleting a category keeps its deck and cards uncategorized', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deck = FlashcardDeck(
      id: 'delete-category-deck',
      title: 'ชุดยังอยู่',
      categoryId: mockCategoryLanguage,
      description: '',
      cards: [
        Flashcard(id: 'kept-card', question: 'Q', answer: 'A'),
        Flashcard(id: 'kept-card-2', question: 'Q2', answer: 'A2'),
      ],
    );
    final deckService = FakeDeckService(
      decks: [deck],
      categories: const [
        FlashcardCategory(id: mockCategoryLanguage, name: 'ภาษา'),
      ],
    );
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษา').first);
    await tester.pumpAndSettle();
    expect(find.text('ชุดยังอยู่'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-categories')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('category-$mockCategoryLanguage')),
        matching: find.byTooltip('จัดการหมวดหมู่'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Deck ในหมวด “ภาษา” จะย้ายเป็น “ยังไม่จัดหมวด”'),
      findsOneWidget,
    );
    expect(find.textContaining('บัตรใน Deck จะไม่ถูกลบ'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'ลบหมวดหมู่'));
    await tester.pumpAndSettle();

    expect(deckService.decks.single.title, 'ชุดยังอยู่');
    expect(deckService.decks.single.totalCardCount, 2);
    expect(deckService.decks.single.categoryId, isNull);
    await tester.tap(find.byKey(const ValueKey('tab-decks')));
    await tester.pumpAndSettle();
    expect(find.text('ชุดยังอยู่'), findsOneWidget);
    expect(find.text('ยังไม่จัดหมวด'), findsWidgets);
  });

  testWidgets('null category id is shown as uncategorized', (tester) async {
    final deck = FlashcardDeck(
      id: 'uncategorized-deck',
      title: 'ชุดไม่มีหมวด',
      categoryId: null,
      description: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DeckListScreen(
          decks: [deck],
          categories: const [
            FlashcardCategory(id: 'legacy-category', name: 'เก่าจากฐานเดิม'),
          ],
          isLoading: false,
          onRetry: () {},
          onSaveDeck: ({
            FlashcardDeck? existingDeck,
            required String title,
            required String? categoryId,
            required String description,
          }) async {},
          onDeleteDeck: (_) async {},
          onOpenDeck: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่จัดหมวด'), findsWidgets);
    expect(find.text('เก่าจากฐานเดิม'), findsOneWidget);
  });

  testWidgets('main tabs retain deck state and detail uses system back', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    expect(deckService.getDeckCalls, 1);

    await tester.tap(find.byKey(const ValueKey('tab-categories')));
    await tester.pumpAndSettle();
    expect(find.text('จัดการหมวดหมู่ของคุณ'), findsOneWidget);
    expect(find.text('ภาษา'), findsOneWidget);
    expect(deckService.getDeckCalls, 1);

    await tester.tap(find.byKey(const ValueKey('tab-decks')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();
    expect(find.text('บัตรคำ (2)'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('ชุดบัตรของฉัน'), findsOneWidget);
    expect(find.text('ภาษาอังกฤษพื้นฐาน'), findsOneWidget);
    expect(deckService.getDeckCalls, 1);
  });

  testWidgets('opens a deck and validates the add-card form', (tester) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();

    expect(find.text('FlashDeck'), findsOneWidget);
    expect(find.text('ภาษาอังกฤษพื้นฐาน'), findsOneWidget);

    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();

    expect(find.text('บัตรคำ (2)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-card-button')));
    await tester.pumpAndSettle();

    expect(find.text('เพิ่มบัตรคำ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-card-button')));
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอกคำถาม'), findsOneWidget);
    expect(find.text('กรุณากรอกคำตอบ'), findsOneWidget);
  });

  testWidgets('saves a mock card and opens the review screen', (tester) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-card-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('question-field')),
      'What does “bright” mean?',
    );
    await tester.enterText(
      find.byKey(const ValueKey('answer-field')),
      'ฉลาด หรือ สว่าง',
    );
    await tester.tap(find.byKey(const ValueKey('save-card-button')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('What does “bright” mean?'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('What does “bright” mean?'), findsOneWidget);

    await tester.tap(find.text('เริ่มทบทวน'));
    await tester.pumpAndSettle();
    expect(find.text('ทบทวน'), findsOneWidget);
    expect(find.text('เปิดคำตอบ'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-answer')), findsNothing);

    for (var cardIndex = 0; cardIndex < 3; cardIndex++) {
      await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('review-answer')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('remembered-button')));
      await tester.pumpAndSettle();
    }

    expect(find.text('ผลการทบทวน'), findsOneWidget);
    expect(find.text('จำได้'), findsOneWidget);
    expect(find.text('จำนวนครั้งที่ตอบ'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('What does “bright” mean?'), findsOneWidget);
  });

  testWidgets('swiping before opening the answer does not submit', (
    tester,
  ) async {
    await _pumpReview(tester, [_reviewCard('a'), _reviewCard('b')]);
    final card = find.byKey(const ValueKey('review-card'));
    final width = tester.getSize(card).width;

    await tester.drag(card, Offset(width * 0.7, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('review-answer')), findsNothing);
    expect(find.text('Question a'), findsOneWidget);
    expect(find.text('จำได้ 0 / 2'), findsOneWidget);
    expect(find.textContaining('ตอบแล้ว 0 ครั้ง'), findsOneWidget);
  });

  testWidgets('a swipe below threshold returns to center without answering', (
    tester,
  ) async {
    await _pumpReview(tester, [_reviewCard('a'), _reviewCard('b')]);
    await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('review-card'));
    final width = tester.getSize(card).width;

    await tester.drag(card, Offset(width * 0.24, 0));
    await tester.pumpAndSettle();

    expect(find.text('Question a'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-answer')), findsOneWidget);
    expect(find.text('จำได้ 0 / 2'), findsOneWidget);
    expect(find.textContaining('ตอบแล้ว 0 ครั้ง'), findsOneWidget);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('review-card-transform')),
          )
          .transform
          .getTranslation()
          .x,
      closeTo(0, 0.01),
    );
  });

  testWidgets('swiping right remembers and resets the next card', (
    tester,
  ) async {
    await _pumpReview(tester, [_reviewCard('a'), _reviewCard('b')]);
    await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('review-card'));
    final width = tester.getSize(card).width;

    await tester.drag(card, Offset(width * 0.35, 0));
    await tester.pumpAndSettle();

    expect(find.text('Question b'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-answer')), findsNothing);
    expect(find.text('จำได้ 1 / 2'), findsOneWidget);
    expect(find.textContaining('ตอบแล้ว 1 ครั้ง'), findsOneWidget);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('review-card-transform')),
          )
          .transform
          .getTranslation()
          .x,
      closeTo(0, 0.01),
    );
  });

  testWidgets(
    'swiping left retries the card and buttons share the answer flow',
    (tester) async {
      await _pumpReview(tester, [_reviewCard('a'), _reviewCard('b')]);
      await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('review-card'));
      final width = tester.getSize(card).width;

      await tester.drag(card, Offset(-width * 0.35, 0));
      await tester.pumpAndSettle();

      expect(find.text('Question b'), findsOneWidget);
      expect(find.text('จำได้ 0 / 2'), findsOneWidget);
      expect(find.textContaining('ตอบแล้ว 1 ครั้ง'), findsOneWidget);
      expect(find.byKey(const ValueKey('review-answer')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('remembered-button')));
      await tester.pumpAndSettle();
      expect(find.text('Question a'), findsOneWidget);
      expect(find.text('จำได้ 1 / 2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
      await tester.pumpAndSettle();
      expect(find.text('ทบทวนอีก'), findsOneWidget);
      expect(find.textContaining('ตอบแล้ว 2 ครั้ง'), findsOneWidget);
    },
  );

  testWidgets('rapid repeated answer actions are accepted only once', (
    tester,
  ) async {
    await _pumpReview(tester, [_reviewCard('only')]);
    await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
    await tester.pumpAndSettle();
    final answerButton = find.byKey(const ValueKey('remembered-button'));

    await tester.tap(answerButton);
    await tester.tap(answerButton);
    await tester.pumpAndSettle();

    expect(find.text('ผลการทบทวน'), findsOneWidget);
    expect(find.text('จำนวนครั้งที่ตอบ'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'จำได้'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'จำนวนครั้งที่ตอบ'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('swiping the only card opens the result once', (tester) async {
    await _pumpReview(tester, [_reviewCard('only')]);
    await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('review-card'));
    final width = tester.getSize(card).width;

    await tester.drag(card, Offset(width * 0.35, 0));
    await tester.pumpAndSettle();

    expect(find.text('ผลการทบทวน'), findsOneWidget);
    expect(find.text('จำได้ 1 จาก 1 ใบ'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'จำนวนครั้งที่ตอบ'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an empty review round opens the result once', (tester) async {
    await _pumpReview(tester, []);
    await tester.pumpAndSettle();

    expect(find.text('ผลการทบทวน'), findsOneWidget);
    expect(find.text('จำได้ 0 จาก 0 ใบ'), findsOneWidget);
  });

  testWidgets('validates sign-up and reports when no session is returned', (
    tester,
  ) async {
    final authService = FakeAuthService();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );

    await tester.tap(find.text('ยังไม่มีบัญชี? สมัครสมาชิก'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
    expect(authService.signUpCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'student@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'safe-pass-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm-password')),
      'safe-pass-123',
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-info')), findsNothing);
    expect(find.byKey(const ValueKey('auth-error')), findsOneWidget);
    expect(find.textContaining('Confirm email'), findsOneWidget);
    expect(find.text('สมัครและลงชื่อเข้าใช้สำเร็จ'), findsNothing);
    expect(find.text('สร้างบัญชี FlashDeck'), findsOneWidget);
    expect(authService.signUpCalls, 1);
  });

  testWidgets('returns to login after sign-up with an active session', (
    tester,
  ) async {
    final authService = FakeAuthService()..signUpReturnsSession = true;
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.tap(find.text('ยังไม่มีบัญชี? สมัครสมาชิก'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'new-student@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'safe-pass-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm-password')),
      'safe-pass-123',
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.text('ยินดีต้อนรับ'), findsOneWidget);
    expect(find.text('สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-submit')), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(authService.currentSession, isNull);
    expect(authService.signOutCalls, 1);
    expect(authService.signUpCalls, 1);

    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('ชุดบัตรของฉัน'), findsOneWidget);
  });

  testWidgets('shows duplicate-email and weak-password sign-up errors', (
    tester,
  ) async {
    final authService = FakeAuthService()
      ..nextSignUpError = const AuthException(
        'User already registered',
        code: 'user_already_exists',
      );
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.tap(find.text('ยังไม่มีบัญชี? สมัครสมาชิก'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'existing@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'weak-pass-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm-password')),
      'weak-pass-123',
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('มีบัญชีอยู่แล้ว'), findsOneWidget);

    authService.nextSignUpError = AuthWeakPasswordException(
      message: 'Password does not meet requirements',
      statusCode: '422',
      reasons: const ['length'],
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('รหัสผ่านยังไม่ปลอดภัยพอ'), findsOneWidget);
    expect(
      find.textContaining('Password does not meet requirements'),
      findsNothing,
    );
    expect(authService.signUpCalls, 2);
  });

  testWidgets('shows a safe message for an auth callback stream error', (
    tester,
  ) async {
    final authService = FakeAuthService();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    authService.emitAuthError(StateError('code=private-auth-code'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-callback-error')), findsOneWidget);
    expect(find.textContaining('ลิงก์ยืนยันอีเมลไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('private-auth-code'), findsNothing);
    expect(find.text('ยินดีต้อนรับ'), findsOneWidget);
  });

  testWidgets('logout removes one account mock data before next login', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn(userId: 'first-user');
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-deck-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'ข้อมูลส่วนตัว');
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('4 ชุด'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sign-out-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ออกจากระบบ'));
    await tester.pumpAndSettle();
    expect(find.text('ยินดีต้อนรับ'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'another@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'safe-pass-123',
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    // A successful write belongs to the same account and remains in storage.
    expect(find.text('ชุดบัตรของฉัน'), findsOneWidget);
    expect(find.text('4 ชุด'), findsOneWidget);
  });

  testWidgets('keeps the deck dialog and input open when save fails', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService()..failNextSave = true;
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-deck-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'เก็บข้อความนี้');
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('บันทึกชุดบัตรไม่สำเร็จ โปรดลองอีกครั้ง'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'เก็บข้อความนี้',
    );
  });

  testWidgets('confirms cascade deletion and updates the deck list', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();
    expect(
      find.text('ชุดบัตร “ภาษาอังกฤษพื้นฐาน” และบัตรคำทั้งหมดในชุดจะถูกลบ'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'ลบ'));
    await tester.pumpAndSettle();
    expect(find.text('2 ชุด'), findsOneWidget);
    expect(find.text('ภาษาอังกฤษพื้นฐาน'), findsNothing);
  });

  testWidgets('shows deck loading error and retries', (tester) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService()..failNextLoad = true;
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดชุดบัตรไม่สำเร็จ โปรดลองอีกครั้ง'), findsOneWidget);
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();
    expect(find.text('ภาษาอังกฤษพื้นฐาน'), findsOneWidget);
  });

  testWidgets('searches cards by answer and shows both question and answer', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();
    expect(find.text('What does “curious” mean?'), findsOneWidget);
    expect(find.text('อยากรู้อยากเห็น'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('card-search-field')),
      'เชื่อถือได้',
    );
    await tester.pumpAndSettle();
    expect(find.text('What does “reliable” mean?'), findsOneWidget);
    expect(find.text('What does “curious” mean?'), findsNothing);
  });

  testWidgets('sorts the visible cards by question when selected', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    deckService.cardsByDeck['english'] = deckService
        .cardsByDeck['english']!
        .reversed
        .toList();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();

    final firstCard = find.byKey(const ValueKey('card-english-2'));
    final secondCard = find.byKey(const ValueKey('card-english-1'));
    expect(
      tester.getTopLeft(firstCard).dy,
      lessThan(tester.getTopLeft(secondCard).dy),
    );

    await tester.tap(find.byKey(const ValueKey('card-sort-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('คำถาม A–Z'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(secondCard).dy,
      lessThan(tester.getTopLeft(firstCard).dy),
    );
  });

  testWidgets('empty deck disables review until a card is added', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService(
      decks: [
        FlashcardDeck(
          id: 'science',
          title: 'วิทยาศาสตร์รอบตัว',
          categoryId: mockCategoryScience,
          description: 'คำถามสั้น ๆ สำหรับทบทวน',
        ),
      ],
    );
    deckService.cardsByDeck['science'] = [];
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('วิทยาศาสตร์รอบตัว'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('start-review-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('add-card-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('question-field')),
      'คำถาม',
    );
    await tester.enterText(find.byKey(const ValueKey('answer-field')), 'คำตอบ');
    await tester.tap(find.byKey(const ValueKey('save-card-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('start-review-button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('keeps card form open when saving fails', (tester) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService()..failNextCardSave = true;
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-card-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('question-field')),
      'keep question',
    );
    await tester.enterText(
      find.byKey(const ValueKey('answer-field')),
      'keep answer',
    );
    await tester.tap(find.byKey(const ValueKey('save-card-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('card-save-error')), findsOneWidget);
    expect(find.text('เพิ่มบัตรคำ'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('question-field')))
          .controller!
          .text,
      'keep question',
    );
  });

  testWidgets('shows card loading error and retries the active Deck', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService()..failNextCardLoad = true;
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();

    expect(find.text('โหลดบัตรคำไม่สำเร็จ โปรดลองอีกครั้ง'), findsOneWidget);
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();
    expect(find.text('What does “curious” mean?'), findsOneWidget);
  });

  testWidgets(
    'validates trimmed card content and the schema character limits',
    (tester) async {
      final authService = FakeAuthService.signedIn();
      final deckService = FakeDeckService();
      addTearDown(authService.dispose);
      await tester.pumpWidget(
        MyApp(authService: authService, deckService: deckService),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-card-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('question-field')),
        '  ',
      );
      await tester.enterText(find.byKey(const ValueKey('answer-field')), '  ');
      await tester.tap(find.byKey(const ValueKey('save-card-button')));
      await tester.pumpAndSettle();
      expect(find.text('กรุณากรอกคำถาม'), findsOneWidget);
      expect(find.text('กรุณากรอกคำตอบ'), findsOneWidget);
      expect(deckService.cardSaveCalls, 0);
    },
  );

  testWidgets('confirms card deletion and updates the Deck count', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ').last);
    await tester.pumpAndSettle();
    expect(find.text('บัตรคำนี้จะถูกลบถาวร'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'ลบ'));
    await tester.pumpAndSettle();
    expect(find.text('บัตรคำ (1)'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('deck-card-english')),
        matching: find.text('1 ใบ'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides answer after retry and confirms ending mid-round', (
    tester,
  ) async {
    final authService = FakeAuthService.signedIn();
    final deckService = FakeDeckService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MyApp(authService: authService, deckService: deckService),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาษาอังกฤษพื้นฐาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เริ่มทบทวน'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('not-remembered-button')));
    await tester.pumpAndSettle();
    expect(find.text('What does “reliable” mean?'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-answer')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('end-review-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ทำต่อ'));
    await tester.pumpAndSettle();
    expect(find.text('ทบทวน'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('end-review-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'จบรอบ'));
    await tester.pumpAndSettle();

    expect(find.text('ผลการทบทวน'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'บัตรทั้งหมด'),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'จำได้'),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'เหลือ'),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'จำนวนครั้งที่ตอบ'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'restarting review resets queue, remembered cards, and attempts',
    (tester) async {
      await _pumpReview(tester, [_reviewCard('restart-card')]);

      await tester.tap(find.byKey(const ValueKey('reveal-answer-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('remembered-button')));
      await tester.pumpAndSettle();
      expect(find.text('ผลการทบทวน'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('restart-review-button')),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('restart-review-button')));
      await tester.pumpAndSettle();

      expect(find.text('ทบทวน'), findsOneWidget);
      expect(find.byKey(const ValueKey('review-answer')), findsNothing);
      expect(find.text('จำได้ 0 / 1'), findsOneWidget);
      expect(find.text('เหลือในคิว 1 ใบ · ตอบแล้ว 0 ครั้ง'), findsOneWidget);
    },
  );

  testWidgets('login layout scrolls on a small screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final authService = FakeAuthService();
    addTearDown(authService.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.5),
          ),
          child: AuthScreen(authService: authService),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('auth-submit')), findsOneWidget);
  });

  testWidgets(
    'card form remains scrollable with larger text on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.5),
            ),
            child: CardEditorScreen(onSave: (card) async => card),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('save-card-form-button')),
        findsOneWidget,
      );
      tester.view.resetViewInsets();
    },
  );

  testWidgets('card list handles long Thai text on a small scaled screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final deck = FlashcardDeck(
      id: 'long-card-deck',
      title: 'ศัพท์',
      categoryId: mockCategoryLanguage,
      description: '',
      cards: [
        Flashcard(
          id: 'long-card',
          question: 'คำถามภาษาไทยที่ยาวมากสำหรับตรวจสอบการตัดบรรทัดบนหน้าจอมือถือขนาดเล็ก',
          answer: 'คำตอบภาษาไทยที่มีรายละเอียดหลายคำและควรเลื่อนอ่านได้โดยไม่ล้นออกนอกการ์ด',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.5),
          ),
          child: CardListScreen(
            deck: deck,
            deckService: FakeDeckService(decks: [deck]),
            onDeckChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deck dialog remains usable above the keyboard on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.5),
            ),
            child: DeckListScreen(
              decks: const [],
              isLoading: false,
              onRetry: () {},
              onSaveDeck: ({
                FlashcardDeck? existingDeck,
                required String title,
                required String? categoryId,
                required String description,
              }) async {},
              onDeleteDeck: (_) async {},
              onOpenDeck: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-deck-button')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('บันทึก'), findsOneWidget);
    },
  );

  testWidgets('review result scales and scrolls without losing its actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final deck = FlashcardDeck(
      id: 'long-result-deck',
      title: 'ชุดทบทวนเนื้อหาภาษาไทยสำหรับการสอบปลายภาค',
      categoryId: mockCategoryLanguage,
      description: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.5),
          ),
          child: ReviewResultScreen(
            deck: deck,
            result: const ReviewResult(
              totalCards: 23,
              rememberedCards: 14,
              remainingCards: 9,
              attempts: 41,
            ),
            onRestart: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('restart-review-button')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('back-to-cards-button')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('back-to-cards-button')), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
  });
}

Future<void> _pumpReview(WidgetTester tester, List<Flashcard> cards) async {
  final deck = FlashcardDeck(
    id: 'gesture-review',
    title: 'ชุดทดสอบทบทวน',
    categoryId: mockCategoryLanguage,
    description: '',
    cards: cards,
  );
  await tester.pumpWidget(MaterialApp(home: ReviewScreen(deck: deck)));
  await tester.pumpAndSettle();
}

Flashcard _reviewCard(String id) =>
    Flashcard(id: id, question: 'Question $id', answer: 'Answer $id');

class FakeAuthService implements AuthService {
  FakeAuthService({AuthSession? initialSession}) : _session = initialSession;

  AuthSession? _session;
  final _authChanges = StreamController<AuthSession?>.broadcast();
  int signUpCalls = 0;
  bool signUpReturnsSession = false;
  AuthException? nextSignUpError;
  int signOutCalls = 0;

  void emitAuthError(Object error) => _authChanges.addError(error);

  static FakeAuthService signedIn({String userId = 'test-user'}) =>
      FakeAuthService(initialSession: AuthSession(userId: userId));

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> get authStateChanges => _authChanges.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _session = AuthSession(userId: email);
    _authChanges.add(_session);
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    signUpCalls++;
    final error = nextSignUpError;
    nextSignUpError = null;
    if (error != null) throw error;
    if (signUpReturnsSession) {
      _session = AuthSession(userId: email);
      _authChanges.add(_session);
    }
    return signUpReturnsSession;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _session = null;
    _authChanges.add(null);
  }

  Future<void> dispose() => _authChanges.close();
}

class FakeDeckService implements DeckService, CategoryService {
  FakeDeckService({
    List<FlashcardDeck>? decks,
    List<FlashcardCategory>? categories,
  }) : _decks = decks ?? createMockDecks(),
       _categories = List.of(categories ?? createMockCategories()) {
    for (final deck in _decks) {
      cardsByDeck[deck.id] = List.of(deck.cards);
    }
  }

  final List<FlashcardDeck> _decks;
  final List<FlashcardCategory> _categories;
  final Map<String, List<Flashcard>> cardsByDeck = {};
  bool failNextSave = false;
  bool failNextLoad = false;
  bool failNextCardSave = false;
  bool failNextCardLoad = false;
  int cardSaveCalls = 0;
  int getDeckCalls = 0;
  List<FlashcardDeck> get decks => _decks;
  bool failNextCategoryMutation = false;

  @override
  Future<List<FlashcardCategory>> getCategories() async => List.of(_categories);

  @override
  Future<FlashcardCategory> createCategory(String name) async {
    if (failNextCategoryMutation) {
      failNextCategoryMutation = false;
      throw Exception('category create failure');
    }
    final cleanName = name.trim();
    if (_categories.any(
      (item) => item.name.toLowerCase() == cleanName.toLowerCase(),
    )) {
      throw const CategoryNameAlreadyExistsException();
    }
    final category = FlashcardCategory(
      id: 'category-${_categories.length}',
      name: cleanName,
    );
    _categories.add(category);
    return category;
  }

  @override
  Future<FlashcardCategory> renameCategory({
    required String id,
    required String name,
  }) async {
    if (failNextCategoryMutation) {
      failNextCategoryMutation = false;
      throw Exception('category rename failure');
    }
    final cleanName = name.trim();
    if (_categories.any(
      (item) =>
          item.id != id && item.name.toLowerCase() == cleanName.toLowerCase(),
    )) {
      throw const CategoryNameAlreadyExistsException();
    }
    final index = _categories.indexWhere((item) => item.id == id);
    final category = FlashcardCategory(id: id, name: cleanName);
    _categories[index] = category;
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (failNextCategoryMutation) {
      failNextCategoryMutation = false;
      throw Exception('category delete failure');
    }
    _categories.removeWhere((item) => item.id == id);
    for (final deck in _decks) {
      if (deck.categoryId == id) deck.categoryId = null;
    }
  }

  @override
  Future<List<FlashcardDeck>> getDecks() async {
    getDeckCalls++;
    if (failNextLoad) {
      failNextLoad = false;
      throw Exception('test load failure');
    }
    return List.of(_decks);
  }

  @override
  Future<FlashcardDeck> saveDeck({
    String? id,
    required String title,
    required String? categoryId,
    required String description,
  }) async {
    if (failNextSave) {
      failNextSave = false;
      throw Exception('test save failure');
    }
    if (id == null) {
      final deck = FlashcardDeck(
        id: 'created-${_decks.length}',
        title: title,
        categoryId: categoryId,
        description: description,
      );
      _decks.insert(0, deck);
      return deck;
    }

    final deck = _decks.singleWhere((item) => item.id == id)
      ..title = title
      ..categoryId = categoryId
      ..description = description;
    return deck;
  }

  @override
  Future<void> deleteDeck(String id) async {
    _decks.removeWhere((deck) => deck.id == id);
    cardsByDeck.remove(id);
  }

  @override
  Future<List<Flashcard>> getCards(String deckId) async {
    if (failNextCardLoad) {
      failNextCardLoad = false;
      throw Exception('test card load failure');
    }
    return List.of(cardsByDeck[deckId] ?? const []);
  }

  @override
  Future<Flashcard> saveCard({
    String? id,
    required String deckId,
    required String question,
    required String answer,
  }) async {
    cardSaveCalls++;
    if (failNextCardSave) {
      failNextCardSave = false;
      throw Exception('test card save failure');
    }
    final cards = cardsByDeck.putIfAbsent(deckId, () => []);
    final saved = Flashcard(
      id: id ?? 'card-${cards.length}',
      question: question,
      answer: answer,
    );
    final index = id == null ? -1 : cards.indexWhere((card) => card.id == id);
    if (index < 0) {
      cards.add(saved);
    } else {
      cards[index] = saved;
    }
    final deck = _decks.singleWhere((item) => item.id == deckId);
    deck.cardCount = cards.length;
    return saved;
  }

  @override
  Future<void> deleteCard({required String id, required String deckId}) async {
    final cards = cardsByDeck[deckId] ?? [];
    cards.removeWhere((card) => card.id == id);
    _decks.singleWhere((item) => item.id == deckId).cardCount = cards.length;
  }
}
