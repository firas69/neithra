import 'answer_value_model.dart';
import 'question_model.dart';
import 'result_model.dart';

class QuestionAttemptResult {
  final String questionId;
  final String questionText;
  final String questionType;
  final String userAnswerText;
  final String correctAnswerText;
  final bool isCorrect;
  final bool needsManualReview;
  final String? explanation;
  final String category;
  final double earnedPoints;
  final double maxPoints;

  const QuestionAttemptResult({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.userAnswerText,
    required this.correctAnswerText,
    required this.isCorrect,
    required this.needsManualReview,
    this.explanation,
    required this.category,
    required this.earnedPoints,
    required this.maxPoints,
  });

  factory QuestionAttemptResult.fromQuestion(
    Question question,
    AnswerValue answer,
  ) {
    final score = question.scoreAnswer(answer);
    return QuestionAttemptResult(
      questionId: question.id,
      questionText: question.displayText,
      questionType: question.typeLabel,
      userAnswerText: answer.asDisplayText(options: question.options),
      correctAnswerText: question.correctAnswerDisplay(),
      isCorrect: score.isCorrect,
      needsManualReview: score.needsManualReview,
      explanation: question.explanation,
      category: question.category ?? question.topic ?? 'General',
      earnedPoints: score.earnedPoints,
      maxPoints: score.maxPoints,
    );
  }

  factory QuestionAttemptResult.fromJson(Map<String, dynamic> json) {
    return QuestionAttemptResult(
      questionId: json['questionId']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? 'Missing question',
      questionType: json['questionType']?.toString() ?? 'Question',
      userAnswerText:
          json['userAnswerText']?.toString() ?? 'No answer provided',
      correctAnswerText:
          json['correctAnswerText']?.toString() ?? 'Not specified',
      isCorrect: json['isCorrect'] == true,
      needsManualReview: json['needsManualReview'] == true,
      explanation: json['explanation']?.toString(),
      category: json['category']?.toString() ?? 'General',
      earnedPoints: (json['earnedPoints'] as num?)?.toDouble() ?? 0,
      maxPoints: (json['maxPoints'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'questionType': questionType,
      'userAnswerText': userAnswerText,
      'correctAnswerText': correctAnswerText,
      'isCorrect': isCorrect,
      'needsManualReview': needsManualReview,
      if (explanation != null) 'explanation': explanation,
      'category': category,
      'earnedPoints': earnedPoints,
      'maxPoints': maxPoints,
    };
  }
}

class TestAttempt {
  final String id;
  final String testId;
  final String testName;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration elapsedTime;
  final double scorePercentage;
  final double earnedPoints;
  final double maxPoints;
  final int correctAnswers;
  final int totalQuestions;
  final List<QuestionAttemptResult> questionResults;

  const TestAttempt({
    required this.id,
    required this.testId,
    required this.testName,
    required this.startedAt,
    required this.completedAt,
    required this.elapsedTime,
    required this.scorePercentage,
    required this.earnedPoints,
    required this.maxPoints,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.questionResults,
  });

  factory TestAttempt.fromResult({
    required String testId,
    required ResultModel result,
    required List<Question> questions,
    required DateTime startedAt,
  }) {
    return TestAttempt(
      id: result.sessionId,
      testId: testId,
      testName: result.testTitle,
      startedAt: startedAt,
      completedAt: result.completedAt,
      elapsedTime: result.timeTaken,
      scorePercentage: result.scorePercentage,
      earnedPoints: result.earnedPoints,
      maxPoints: result.maxPoints,
      correctAnswers: result.correctAnswers,
      totalQuestions: result.totalQuestions,
      questionResults: questions
          .map(
            (question) => QuestionAttemptResult.fromQuestion(
              question,
              result.responses[question.id] ?? const AnswerValue.empty(),
            ),
          )
          .toList(),
    );
  }

  factory TestAttempt.fromJson(Map<String, dynamic> json) {
    final rawResults = json['questionResults'];
    return TestAttempt(
      id: json['id']?.toString() ?? '',
      testId: json['testId']?.toString() ?? '',
      testName: json['testName']?.toString() ?? 'Untitled Test',
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      completedAt:
          DateTime.tryParse(json['completedAt']?.toString() ?? '') ??
          DateTime.now(),
      elapsedTime: Duration(
        seconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      ),
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0,
      earnedPoints: (json['earnedPoints'] as num?)?.toDouble() ?? 0,
      maxPoints: (json['maxPoints'] as num?)?.toDouble() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      questionResults: rawResults is List
          ? rawResults
                .whereType<Map>()
                .map(
                  (item) => QuestionAttemptResult.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'testName': testName,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'elapsedSeconds': elapsedTime.inSeconds,
      'scorePercentage': scorePercentage,
      'earnedPoints': earnedPoints,
      'maxPoints': maxPoints,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'questionResults': questionResults.map((item) => item.toJson()).toList(),
    };
  }
}
