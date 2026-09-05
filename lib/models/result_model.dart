import 'answer_value_model.dart';

class ResultModel {
  final String sessionId;
  final String testTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int manualReviewQuestions;
  final double earnedPoints;
  final double maxPoints;
  final DateTime completedAt;
  final Duration timeTaken;
  final Map<String, AnswerValue> responses;
  final Map<String, double> categoryScores;
  final Map<String, int> categoryTotals;

  ResultModel({
    required this.sessionId,
    required this.testTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    this.manualReviewQuestions = 0,
    required this.earnedPoints,
    required this.maxPoints,
    required this.completedAt,
    required this.timeTaken,
    required this.responses,
    this.categoryScores = const {},
    this.categoryTotals = const {},
  });

  double get scorePercentage =>
      maxPoints == 0 ? 0 : (earnedPoints / maxPoints) * 100;

  List<MapEntry<String, double>> get weakestCategories {
    final entries =
        categoryTotals.entries
            .where((entry) => entry.value > 0)
            .map(
              (entry) => MapEntry(
                entry.key,
                ((categoryScores[entry.key] ?? 0) / entry.value)
                    .clamp(0.0, 1.0)
                    .toDouble(),
              ),
            )
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(3).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'testTitle': testTitle,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'manualReviewQuestions': manualReviewQuestions,
      'earnedPoints': earnedPoints,
      'maxPoints': maxPoints,
      'completedAt': completedAt.toIso8601String(),
      'timeTaken': timeTaken.inSeconds,
      'responses': responses.map((key, value) => MapEntry(key, value.toJson())),
      'categoryScores': categoryScores,
      'categoryTotals': categoryTotals,
    };
  }

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    final rawResponses = Map<String, dynamic>.from(json['responses'] ?? {});
    return ResultModel(
      sessionId: json['sessionId'] as String,
      testTitle: json['testTitle'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      manualReviewQuestions: json['manualReviewQuestions'] as int? ?? 0,
      earnedPoints:
          (json['earnedPoints'] as num?)?.toDouble() ??
          (json['correctAnswers'] as int).toDouble(),
      maxPoints:
          (json['maxPoints'] as num?)?.toDouble() ??
          (json['totalQuestions'] as int).toDouble(),
      completedAt: DateTime.parse(json['completedAt'] as String),
      timeTaken: Duration(seconds: json['timeTaken'] as int),
      responses: rawResponses.map(
        (key, value) => MapEntry(
          key,
          value is Map<String, dynamic>
              ? AnswerValue.fromJson(value)
              : AnswerValue.fromStorage(value?.toString()),
        ),
      ),
      categoryScores: _doubleMap(json['categoryScores']),
      categoryTotals: _intMap(json['categoryTotals']),
    );
  }
}

Map<String, double> _doubleMap(dynamic value) {
  if (value is! Map) return const {};
  return value.map(
    (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
  );
}

Map<String, int> _intMap(dynamic value) {
  if (value is! Map) return const {};
  return value.map(
    (key, value) => MapEntry(key.toString(), (value as num).toInt()),
  );
}
