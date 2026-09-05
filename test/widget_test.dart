import 'package:flutter_test/flutter_test.dart';
import 'package:neithra/models/answer_value_model.dart';
import 'package:neithra/models/question_model.dart';
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
}
