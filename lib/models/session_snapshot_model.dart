import 'answer_value_model.dart';
import 'test_model.dart';

enum SessionStatus { active, paused, completed }

class SessionSummary {
  final String id;
  final String testTitle;
  final String familyId;
  final String familyName;
  final TestMode mode;
  final int currentQuestionIndex;
  final int totalQuestions;
  final int answeredQuestions;
  final Duration elapsedTime;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime lastActiveAt;

  const SessionSummary({
    required this.id,
    required this.testTitle,
    this.familyId = 'family-uncategorized',
    this.familyName = 'Uncategorized',
    required this.mode,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.elapsedTime,
    required this.status,
    required this.startedAt,
    required this.lastActiveAt,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      id: json['id'].toString(),
      testTitle: json['testTitle']?.toString() ?? 'Untitled Exam',
      familyId: json['familyId']?.toString() ?? 'family-uncategorized',
      familyName: json['familyName']?.toString() ?? 'Uncategorized',
      mode: _parseMode(json['mode']),
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      answeredQuestions: json['answeredQuestions'] as int? ?? 0,
      elapsedTime: Duration(seconds: json['elapsedSeconds'] as int? ?? 0),
      status: _parseStatus(json['status']),
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      lastActiveAt:
          DateTime.tryParse(json['lastActiveAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SessionSnapshot {
  final String id;
  final TestModel test;
  final String familyId;
  final String familyName;
  final TestMode mode;
  final int currentQuestionIndex;
  final Map<String, AnswerValue> answers;
  final Set<String> flaggedQuestionIds;
  final Map<String, int> perQuestionSeconds;
  final Duration elapsedTime;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime lastActiveAt;

  const SessionSnapshot({
    required this.id,
    required this.test,
    this.familyId = 'family-uncategorized',
    this.familyName = 'Uncategorized',
    required this.mode,
    required this.currentQuestionIndex,
    required this.answers,
    required this.flaggedQuestionIds,
    required this.perQuestionSeconds,
    required this.elapsedTime,
    required this.status,
    required this.startedAt,
    required this.lastActiveAt,
  });

  SessionSummary toSummary() {
    return SessionSummary(
      id: id,
      testTitle: test.title,
      familyId: familyId,
      familyName: familyName,
      mode: mode,
      currentQuestionIndex: currentQuestionIndex,
      totalQuestions: test.questions.length,
      answeredQuestions: answers.values
          .where((answer) => answer.isAnswered)
          .length,
      elapsedTime: elapsedTime,
      status: status,
      startedAt: startedAt,
      lastActiveAt: lastActiveAt,
    );
  }
}

TestMode _parseMode(dynamic value) {
  switch (value?.toString()) {
    case 'exam':
      return TestMode.exam;
    case 'weaknessPractice':
      return TestMode.weaknessPractice;
    case 'practice':
    default:
      return TestMode.practice;
  }
}

SessionStatus _parseStatus(dynamic value) {
  switch (value?.toString()) {
    case 'completed':
      return SessionStatus.completed;
    case 'active':
      return SessionStatus.active;
    case 'paused':
    default:
      return SessionStatus.paused;
  }
}
