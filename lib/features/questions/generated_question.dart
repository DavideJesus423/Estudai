/// Questão de múltipla escolha devolvida pela API (`POST /questions/generate`).
class GeneratedQuestion {
  const GeneratedQuestion({
    required this.statement,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String statement;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  factory GeneratedQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestion(
      statement: json['statement'] as String,
      options: (json['options'] as List).cast<String>(),
      correctIndex: json['correct_index'] as int,
      explanation: json['explanation'] as String,
    );
  }
}
