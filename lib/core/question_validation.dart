const int questionTextMaxLength = 100;

String? validateQuestionText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return '質問文を入力してください';
  }
  if (trimmed.runes.length > questionTextMaxLength) {
    return '質問文は$questionTextMaxLength文字以内で入力してください';
  }
  return null;
}
