import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neithra/core/utils/activity_streak.dart';
import 'package:neithra/models/answer_value_model.dart';
import 'package:neithra/models/exam_family_model.dart';
import 'package:neithra/models/imported_test_model.dart';
import 'package:neithra/models/question_model.dart';
import 'package:neithra/models/result_model.dart';
import 'package:neithra/models/test_attempt_model.dart';
import 'package:neithra/services/exam_fingerprint_service.dart';
import 'package:neithra/services/exam_statistics_service.dart';
import 'package:neithra/services/json_parser_service.dart';
import 'package:neithra/widgets/answer_input_widget.dart';

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

  test('exam fingerprint ignores JSON formatting', () {
    final sample = JsonParserService.getSampleJson();
    final minified = jsonEncode(jsonDecode(sample));

    expect(
      ExamFingerprintService.hashJsonString(sample),
      ExamFingerprintService.hashJsonString(minified),
    );
  });

  test('exam fingerprint changes when exam content changes', () {
    final sample = JsonParserService.getSampleJson();
    final changed = sample.replaceFirst('composer.json', 'pubspec.yaml');

    expect(
      ExamFingerprintService.hashJsonString(sample),
      isNot(ExamFingerprintService.hashJsonString(changed)),
    );
  });

  test('exam fingerprint ignores top-level display metadata', () {
    final decoded =
        jsonDecode(JsonParserService.getSampleJson()) as Map<String, dynamic>;
    final renamed = Map<String, dynamic>.from(decoded)
      ..['title'] = 'Renamed Local Display'
      ..['description'] = 'Different display description';

    expect(
      ExamFingerprintService.hashParsedJson(decoded),
      ExamFingerprintService.hashParsedJson(renamed),
    );
  });

  test('imported exam rename keeps stable identity and definition', () {
    final parsed = JsonParserService.parseJsonString(
      JsonParserService.getSampleJson(),
    )!;
    final hash = ExamFingerprintService.hashTest(parsed);
    final imported = ImportedTest.fromParsedTest(parsed, hash);
    final renamed = imported.copyWith(displayName: 'Symfony Review Pack');

    expect(renamed.id, imported.id);
    expect(renamed.test.id, imported.id);
    expect(renamed.displayName, 'Symfony Review Pack');
    expect(renamed.test.title, parsed.title);
    expect(renamed.contentHash, hash);
  });

  test(
    'family statistics aggregate attempts by historical family snapshot',
    () {
      final parsed = JsonParserService.parseJsonString(
        JsonParserService.getSampleJson(),
      )!;
      final familyA = ExamFamily(
        id: 'family-a',
        name: 'CCNA',
        createdAt: _fixedNow,
        updatedAt: _fixedNow,
      );
      final familyB = ExamFamily(
        id: 'family-b',
        name: 'Linux',
        createdAt: _fixedNow,
        updatedAt: _fixedNow,
      );
      final hash = ExamFingerprintService.hashTest(parsed);
      final exam = ImportedTest.fromParsedTest(
        parsed,
        hash,
        familyId: familyA.id,
      );
      final movedExam = exam.copyWith(familyId: familyB.id);
      final attempt = TestAttempt(
        id: 'attempt-1',
        testId: exam.id,
        testName: exam.displayName,
        familyId: familyA.id,
        familyName: familyA.name,
        startedAt: _fixedNow,
        completedAt: _fixedNow,
        elapsedTime: const Duration(minutes: 30),
        scorePercentage: 80,
        earnedPoints: 8,
        maxPoints: 10,
        correctAnswers: 8,
        totalQuestions: 10,
        questionResults: const [],
      );

      final oldFamilyStats = ExamStatisticsService.forFamily(
        family: familyA,
        exams: [movedExam],
        attempts: [attempt],
      );
      final newFamilyStats = ExamStatisticsService.forFamily(
        family: familyB,
        exams: [movedExam],
        attempts: [attempt],
      );

      expect(oldFamilyStats.attemptCount, 1);
      expect(oldFamilyStats.averageScore, 80);
      expect(newFamilyStats.examCount, 1);
      expect(newFamilyStats.attemptCount, 0);
      expect(movedExam.id, exam.id);
      expect(movedExam.contentHash, exam.contentHash);
    },
  );

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
      familyId: 'family-a',
      familyName: 'Family A',
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

  testWidgets('single choice exam question starts with no answer selected', (
    tester,
  ) async {
    final question = _singleChoiceQuestion();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerInputWidget(
            question: question,
            initialValue: const AnswerValue.empty(),
            onAnswerChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
  });

  testWidgets('selected answer is preserved when answer widget rebuilds', (
    tester,
  ) async {
    final question = _singleChoiceQuestion();
    var storedAnswer = const AnswerValue.empty();

    Widget buildWidget(AnswerValue answer) {
      return MaterialApp(
        home: Scaffold(
          body: AnswerInputWidget(
            question: question,
            initialValue: answer,
            onAnswerChanged: (answer) => storedAnswer = answer,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildWidget(storedAnswer));
    await tester.tap(find.text('Beta'));
    await tester.pump();

    expect(storedAnswer.selectedIndex, 1);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    await tester.pumpWidget(buildWidget(storedAnswer));
    await tester.pump();

    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(storedAnswer.selectedIndex, 1);
  });

  testWidgets('text answer controller preserves cursor across rebuilds', (
    tester,
  ) async {
    final question = Question(
      id: 'text-1',
      type: QuestionType.shortAnswer,
      prompt: 'Describe subnetting.',
    );
    var storedAnswer = const AnswerValue.empty();

    Widget buildWidget(AnswerValue answer) {
      return MaterialApp(
        home: Scaffold(
          body: AnswerInputWidget(
            question: question,
            initialValue: answer,
            onAnswerChanged: (answer) => storedAnswer = answer,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildWidget(storedAnswer));
    await tester.enterText(find.byType(TextField), 'Networking Fundamentals');
    await tester.pump();
    await tester.pumpWidget(buildWidget(storedAnswer));
    await tester.pump();

    final editableText = tester.state<EditableTextState>(
      find.byType(EditableText),
    );

    expect(editableText.textEditingValue.text, 'Networking Fundamentals');
    expect(
      editableText.textEditingValue.selection.extentOffset,
      'Networking Fundamentals'.length,
    );
  });

  testWidgets('ordering question does not auto-save a user answer', (
    tester,
  ) async {
    var emitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerInputWidget(
            question: Question(
              id: 'order-1',
              type: QuestionType.ordering,
              prompt: 'Order these steps.',
              correctOrder: const ['A', 'B', 'C'],
            ),
            initialValue: const AnswerValue.empty(),
            onAnswerChanged: (_) => emitted = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(emitted, isFalse);
  });
}

final _fixedNow = DateTime(2026, 9, 6, 12);

Question _singleChoiceQuestion() {
  return Question(
    id: 'q1',
    type: QuestionType.singleChoice,
    prompt: 'Pick one.',
    options: const ['Alpha', 'Beta', 'Gamma'],
    correctAnswer: 1,
  );
}
