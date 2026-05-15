import 'package:flutter_test/flutter_test.dart';
import 'package:panda_talk/core/question_validation.dart';

void main() {
  group('validateQuestionText', () {
    test('rejects blank question text', () {
      expect(validateQuestionText('   '), '質問文を入力してください');
    });

    test('allows question text with exactly 100 characters', () {
      final text = 'あ' * questionTextMaxLength;

      expect(validateQuestionText(text), isNull);
    });

    test('rejects question text over 100 characters', () {
      final text = 'あ' * (questionTextMaxLength + 1);

      expect(validateQuestionText(text), '質問文は100文字以内で入力してください');
    });
  });
}
