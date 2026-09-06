import '../models/exam_family_model.dart';
import '../models/imported_test_model.dart';
import '../models/test_attempt_model.dart';

class ExamStats {
  final int examCount;
  final int attemptedExamCount;
  final int attemptCount;
  final double averageScore;
  final double? bestScore;
  final double? latestScore;
  final Duration totalTime;
  final int answeredQuestions;
  final int totalQuestions;

  const ExamStats({
    required this.examCount,
    required this.attemptedExamCount,
    required this.attemptCount,
    required this.averageScore,
    required this.bestScore,
    required this.latestScore,
    required this.totalTime,
    required this.answeredQuestions,
    required this.totalQuestions,
  });

  double get accuracyPercentage =>
      totalQuestions == 0 ? 0 : (answeredQuestions / totalQuestions) * 100;

  bool get hasAttempts => attemptCount > 0;
}

class ExamStatisticsService {
  static ExamStats global({
    required List<ImportedTest> exams,
    required List<TestAttempt> attempts,
  }) {
    return _aggregate(exams: exams, attempts: attempts);
  }

  static ExamStats forFamily({
    required ExamFamily family,
    required List<ImportedTest> exams,
    required List<TestAttempt> attempts,
  }) {
    final familyExams = exams
        .where((exam) => exam.familyId == family.id)
        .toList();
    final familyAttempts = attempts
        .where((attempt) => attempt.familyId == family.id)
        .toList();
    return _aggregate(exams: familyExams, attempts: familyAttempts);
  }

  static ExamStats forExam({
    required ImportedTest exam,
    required List<TestAttempt> attempts,
  }) {
    final examAttempts = attempts
        .where((attempt) => attempt.testId == exam.id)
        .toList();
    return _aggregate(exams: [exam], attempts: examAttempts);
  }

  static ExamStats _aggregate({
    required List<ImportedTest> exams,
    required List<TestAttempt> attempts,
  }) {
    final sortedAttempts = [...attempts]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final attemptedExamIds = sortedAttempts.map((item) => item.testId).toSet();
    final attemptCount = sortedAttempts.length;
    final totalScore = sortedAttempts.fold<double>(
      0,
      (sum, attempt) => sum + attempt.scorePercentage,
    );
    final bestScore = sortedAttempts.isEmpty
        ? null
        : sortedAttempts
              .map((attempt) => attempt.scorePercentage)
              .reduce((a, b) => a > b ? a : b);

    return ExamStats(
      examCount: exams.length,
      attemptedExamCount: exams
          .where((exam) => attemptedExamIds.contains(exam.id))
          .length,
      attemptCount: attemptCount,
      averageScore: attemptCount == 0 ? 0 : totalScore / attemptCount,
      bestScore: bestScore,
      latestScore: sortedAttempts.isEmpty
          ? null
          : sortedAttempts.first.scorePercentage,
      totalTime: sortedAttempts.fold<Duration>(
        Duration.zero,
        (sum, attempt) => sum + attempt.elapsedTime,
      ),
      answeredQuestions: sortedAttempts.fold<int>(
        0,
        (sum, attempt) => sum + attempt.questionResults.length,
      ),
      totalQuestions: sortedAttempts.fold<int>(
        0,
        (sum, attempt) => sum + attempt.totalQuestions,
      ),
    );
  }
}
