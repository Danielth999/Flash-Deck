import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;

import '../models/flashcard.dart';
import '../theme/app_theme.dart';

class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({required this.onSave, this.card, super.key});

  final Flashcard? card;
  final Future<Flashcard> Function(Flashcard card) onSave;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.card?.question ?? '',
    );
    _answerController = TextEditingController(text: widget.card?.answer ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  bool _isSaving = false;
  String? _saveError;

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final savedCard = await widget.onSave(
        Flashcard(
          id: widget.card?.id ?? '',
          question: _questionController.text.trim(),
          answer: _answerController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, savedCard);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'บันทึกบัตรคำไม่สำเร็จ โปรดลองอีกครั้ง';
      });
    }
  }

  String? _validateText(
    String? value, {
    required String field,
    required int maxLength,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอก$field';
    if (text.runes.length > maxLength) {
      return '$fieldต้องมีไม่เกิน $maxLength ตัวอักษร';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'เพิ่มบัตรคำ' : 'แก้ไขบัตรคำ'),
        actions: [
          TextButton(
            key: const ValueKey('save-card-button'),
            onPressed: _isSaving ? null : _save,
            child: const Text('บันทึก'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Builder(
          builder: (context) => ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppTheme.space20,
              AppTheme.space16,
              AppTheme.space20,
              AppTheme.space24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Text(
                'ด้านหน้าของบัตร',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.space12),
            TextFormField(
              key: const ValueKey('question-field'),
              controller: _questionController,
              maxLength: 2000,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              enabled: !_isSaving,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'คำถาม',
                hintText: 'พิมพ์คำถามของบัตรคำ',
                alignLabelWithHint: true,
              ),
              validator: (value) => _validateText(
                value,
                field: 'คำถาม',
                maxLength: 2000,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'ด้านหลังของบัตร',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.space12),
            TextFormField(
              key: const ValueKey('answer-field'),
              controller: _answerController,
              maxLength: 5000,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              enabled: !_isSaving,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'คำตอบ',
                hintText: 'พิมพ์คำตอบของบัตรคำ',
                alignLabelWithHint: true,
              ),
              validator: (value) => _validateText(
                value,
                field: 'คำตอบ',
                maxLength: 5000,
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 8),
              Text(
                _saveError!,
                key: const ValueKey('card-save-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppTheme.space16),
            FilledButton(
              key: const ValueKey('save-card-form-button'),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('บันทึกบัตรคำ'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
