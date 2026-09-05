import 'package:flutter_test/flutter_test.dart';
import 'package:neithra/core/utils/activity_streak.dart';
import 'package:neithra/models/answer_value_model.dart';
import 'package:neithra/models/imported_test_model.dart';
import 'package:neithra/models/question_model.dart';
import 'package:neithra/models/result_model.dart';
import 'package:neithra/models/test_attempt_model.dart';
import 'package:neithra/services/json_parser_service.dart';

void main() {
  test('sample JSON parses into rich question types', () {
    final test = JsonParserService.parseJsonString(
      JsonParserService.getSampleJson(),
    )!;

    expect(test.questionCount, 10);
    expect(
      test.questions.map((question) => question.type),
      contains(QuestionType.matching),
    );
    expect(
      test.questions.map((question) => question.type),
      contains(QuestionType.ordering),
    );
    expect(
      test.questions.map((question) => question.type),
      contains(QuestionType.numerical),
    );
  });

  test('single choice scoring uses the question contract', () {
    final test = JsonParserService.parseJsonString(
      JsonParserService.getSampleJson(),
    )!;
    final question = test.questions.first;

    final correct = question.scoreAnswer(AnswerValue.singleChoice(1));
    final incorrect = question.scoreAnswer(AnswerValue.singleChoice(0));

    expect(correct.isCorrect, isTrue);
    expect(correct.earnedPoints, question.points);
    expect(incorrect.isCorrect, isFalse);
  });

  test('multiple choice scoring requires the complete selected set', () {
    final test = JsonParserService.parseJsonString(
      JsonParserService.getSampleJson(),
    )!;
    final question = test.questions.firstWhere(
      (question) => question.type == QuestionType.multipleChoice,
    );

    expect(
      question.scoreAnswer(AnswerValue.multipleChoice([0, 2, 3])).isCorrect,
      isTrue,
    );
    expect(
      question.scoreAnswer(AnswerValue.multipleChoice([0, 2])).isCorrect,
      isFalse,
    );
  });

  test('imported test rename keeps stable identity', () {
    final parsed = JsonParserService.parseJsonString(
      JsonParserService.getSampleJson(),
    )!;
    final imported = ImportedTest.fromParsedTest(parsed);
    final renamed = imported.copyWith(displayName: 'Symfony Review Pack');

    expect(renamed.id, imported.id);
    expect(renamed.test.id, imported.id);
    expect(renamed.displayName, 'Symfony Review Pack');
    expect(renamed.test.title, 'Symfony Review Pack');
  });

  test('test attempt stores immutable question result snapshots', () {
    final parsed = JsonParserService.parseJsonString(
      JsonParserService.getSampleJson(),
    )!;
    final result = ResultModel(
      sessionId: 'session-1',
      testTitle: 'Original Test Name',
      totalQuestions: 1,
      correctAnswers: 1,
      earnedPoints: 1,
      maxPoints: 1,
      completedAt: DateTime(2026, 9, 5, 10),
      timeTaken: const Duration(minutes: 2),
      responses: {'S001': AnswerValue.singleChoice(1)},
    );

    final attempt = TestAttempt.fromResult(
      testId: 'test-1',
      result: result,
      questions: [parsed.questions.first],
      startedAt: DateTime(2026, 9, 5, 9, 58),
    );

    expect(attempt.id, 'session-1');
    expect(attempt.testName, 'Original Test Name');
    expect(attempt.questionResults.single.userAnswerText, 'composer.json');
    expect(attempt.questionResults.single.isCorrect, isTrue);
  });

  test('activity streak is based on completed local calendar days', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    final streak = ActivityStreak.currentStreak([
      today,
      today.add(const Duration(hours: 2)),
      yesterday,
      twoDaysAgo,
    ]);

    expect(streak, 3);
  });
}
