import '../../core/api/estudai_api_client.dart';
import 'generated_question.dart';

abstract class QuestionsRepository {
  Future<List<GeneratedQuestion>> generateFromPdf({
    required List<int> bytes,
    required String filename,
    int numQuestions = 5,
    int numOptions = 4,
  });
}

class ApiQuestionsRepository implements QuestionsRepository {
  const ApiQuestionsRepository({EstudaiApiClient api = const EstudaiApiClient()}) : _api = api;

  final EstudaiApiClient _api;

  @override
  Future<List<GeneratedQuestion>> generateFromPdf({
    required List<int> bytes,
    required String filename,
    int numQuestions = 5,
    int numOptions = 4,
  }) async {
    final data = await _api.generateQuestions(
      pdfBytes: bytes,
      filename: filename,
      numQuestions: numQuestions,
      numOptions: numOptions,
    );
    final raw = data['questions'];
    if (raw is! List) {
      throw const EstudaiApiException('A API respondeu sem a lista de questões.');
    }
    return raw
        .map((item) => GeneratedQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
