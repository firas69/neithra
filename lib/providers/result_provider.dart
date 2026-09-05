import 'package:flutter/material.dart';

import '../models/answer_value_model.dart';
import '../models/question_model.dart';
import '../models/result_model.dart';
import '../services/api/remote_history_service.dart';

class ResultProvider with ChangeNotifier {
  ResultModel? _currentResult;
  bool _isLoading = false;
  String? _error;

  ResultModel? get currentResult => _currentResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final RemoteHistoryService _remoteHistoryService = RemoteHistoryService();

  Future<void> calculateResult({
    required String sessionId,
    required String testTitle,
    required List<Question> questions,
    required Map<String, AnswerValue> responses,
    required Duration timeTaken,
  }) async {
    _setLoading(true);

    try {
      var correctAnswers = 0;
      var manualReviewQuestions = 0;
      var earnedPoints = 0.0;
      var maxPoints = 0.0;
      final categoryScores = <String, double>{};
      final categoryTotals = <String, int>{};

      for (final question in questions) {
        final answer = responses[question.id] ?? const AnswerValue.empty();
        final score = question.scoreAnswer(answer);
        final category = question.category ?? question.topic ?? 'General';

        if (score.isCorrect) correctAnswers++;
        if (score.needsManualReview) manualReviewQuestions++;

        earnedPoints += score.earnedPoints;
        maxPoints += score.maxPoints;
        categoryScores[category] =
            (categoryScores[category] ?? 0) + score.percentage;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + 1;
      }

      _currentResult = ResultModel(
        sessionId: sessionId,
        testTitle: testTitle,
        totalQuestions: questions.length,
        correctAnswers: correctAnswers,
        manualReviewQuestions: manualReviewQuestions,
        earnedPoints: earnedPoints,
        maxPoints: maxPoints,
        completedAt: DateTime.now(),
        timeTaken: timeTaken,
        responses: responses,
        categoryScores: categoryScores,
        categoryTotals: categoryTotals,
      );

      await _saveToRemoteHistory(_currentResult!);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  Future<void> _saveToRemoteHistory(ResultModel result) async {
    try {
      await _remoteHistoryService.saveTestHistory(result);
    } catch (e) {
      debugPrint('Failed to save to remote history: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearResult() {
    _currentResult = null;
    _error = null;
    notifyListeners();
  }
}
