import 'answer_value_model.dart';

enum QuestionType {
  singleChoice,
  multipleChoice,
  trueFalse,
  shortAnswer,
  fillBlank,
  matching,
  ordering,
  numerical,
  scenario,
  code,
  openEnded,
}

enum QuestionDifficulty { foundation, intermediate, advanced, mixed }

class QuestionScore {
  final double earnedPoints;
  final double maxPoints;
  final bool isCorrect;
  final bool needsManualReview;

  const QuestionScore({
    required this.earnedPoints,
    required this.maxPoints,
    required this.isCorrect,
    this.needsManualReview = false,
  });

  double get percentage => maxPoints == 0 ? 0 : earnedPoints / maxPoints;
}

class Question {
  final String id;
  final QuestionType type;
  final String prompt;
  final String? question;
  final List<String> options;
  final dynamic correctAnswer;
  final List<dynamic> correctAnswers;
  final List<String> acceptedAnswers;
  final String? explanation;
  final QuestionDifficulty difficulty;
  final String? category;
  final String? subcategory;
  final String? topic;
  final List<String> tags;
  final List<String> skills;
  final Duration? estimatedTime;
  final double points;
  final double negativeMarking;
  final String? hint;
  final String? source;
  final String? questionGroup;
  final String? scenarioContext;
  final String? codeSnippet;
  final List<String> media;
  final bool shuffleOptions;
  final String? learningObjective;
  final String? referenceSolution;
  final String? modelAnswer;
  final Map<String, dynamic>? rubric;
  final List<Map<String, dynamic>> keywords;
  final Map<String, String> matchingPairs;
  final List<String> correctOrder;
  final double? tolerance;

  Question({
    required this.id,
    required this.type,
    required this.prompt,
    this.question,
    this.options = const [],
    this.correctAnswer,
    this.correctAnswers = const [],
    this.acceptedAnswers = const [],
    this.explanation,
    this.difficulty = QuestionDifficulty.mixed,
    this.category,
    this.subcategory,
    this.topic,
    this.tags = const [],
    this.skills = const [],
    this.estimatedTime,
    this.points = 1,
    this.negativeMarking = 0,
    this.hint,
    this.source,
    this.questionGroup,
    this.scenarioContext,
    this.codeSnippet,
    this.media = const [],
    this.shuffleOptions = false,
    this.learningObjective,
    this.referenceSolution,
    this.modelAnswer,
    this.rubric,
    this.keywords = const [],
    this.matchingPairs = const {},
    this.correctOrder = const [],
    this.tolerance,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final type = _parseQuestionType(json['type']?.toString());
    final correctAnswer = json['correct_answer'] ?? json['correctAnswer'];
    final correctAnswers =
        json['correct_answers'] ?? json['correctAnswers'] ?? const [];

    return Question(
      id: json['id']?.toString() ?? '',
      type: type,
      prompt: (json['prompt'] ?? json['question'] ?? '').toString(),
      question: json['question']?.toString(),
      options: _stringList(json['options']),
      correctAnswer: correctAnswer,
      correctAnswers: correctAnswers is List
          ? List<dynamic>.from(correctAnswers)
          : [],
      acceptedAnswers: _stringList(
        json['accepted_answers'] ?? json['acceptedAnswers'],
      ),
      explanation: json['explanation']?.toString(),
      difficulty: _parseDifficulty(json['difficulty']?.toString()),
      category: json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      topic: json['topic']?.toString(),
      tags: _stringList(json['tags']),
      skills: _stringList(json['skills']),
      estimatedTime: _durationFromSeconds(
        json['estimated_time'] ?? json['estimatedTime'],
      ),
      points: _doubleValue(json['points'], fallback: 1),
      negativeMarking: _doubleValue(
        json['negative_marking'] ?? json['negativeMarking'],
      ),
      hint: json['hint']?.toString(),
      source: (json['source'] ?? json['reference'])?.toString(),
      questionGroup: (json['question_group'] ?? json['questionGroup'])
          ?.toString(),
      scenarioContext:
          (json['scenario_context'] ?? json['scenario'] ?? json['context'])
              ?.toString(),
      codeSnippet: (json['code_snippet'] ?? json['codeSnippet'])?.toString(),
      media: _stringList(json['media']),
      shuffleOptions:
          json['shuffle_options'] == true || json['shuffleOptions'] == true,
      learningObjective:
          (json['learning_objective'] ?? json['learningObjective'])?.toString(),
      referenceSolution:
          (json['reference_solution'] ?? json['referenceSolution'])?.toString(),
      modelAnswer: (json['model_answer'] ?? json['modelAnswer'])?.toString(),
      rubric: json['rubric'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['rubric'])
          : null,
      keywords: _mapList(json['keywords']),
      matchingPairs: _stringMap(
        json['matching_pairs'] ??
            json['matchingPairs'] ??
            json['correct_pairs'],
      ),
      correctOrder: _stringList(
        json['correct_order'] ?? json['correctOrder'] ?? json['order'],
      ),
      tolerance: (json['tolerance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'prompt': prompt,
      if (question != null) 'question': question,
      if (options.isNotEmpty) 'options': options,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (correctAnswers.isNotEmpty) 'correct_answers': correctAnswers,
      if (acceptedAnswers.isNotEmpty) 'accepted_answers': acceptedAnswers,
      if (explanation != null) 'explanation': explanation,
      'difficulty': difficulty.name,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (topic != null) 'topic': topic,
      if (tags.isNotEmpty) 'tags': tags,
      if (skills.isNotEmpty) 'skills': skills,
      if (estimatedTime != null) 'estimated_time': estimatedTime!.inSeconds,
      'points': points,
      if (negativeMarking > 0) 'negative_marking': negativeMarking,
      if (hint != null) 'hint': hint,
      if (source != null) 'source': source,
      if (questionGroup != null) 'question_group': questionGroup,
      if (scenarioContext != null) 'scenario_context': scenarioContext,
      if (codeSnippet != null) 'code_snippet': codeSnippet,
      if (media.isNotEmpty) 'media': media,
      'shuffle_options': shuffleOptions,
      if (learningObjective != null) 'learning_objective': learningObjective,
      if (referenceSolution != null) 'reference_solution': referenceSolution,
      if (modelAnswer != null) 'model_answer': modelAnswer,
      if (rubric != null) 'rubric': rubric,
      if (keywords.isNotEmpty) 'keywords': keywords,
      if (matchingPairs.isNotEmpty) 'matching_pairs': matchingPairs,
      if (correctOrder.isNotEmpty) 'correct_order': correctOrder,
      if (tolerance != null) 'tolerance': tolerance,
    };
  }

  String get displayText => question ?? prompt;

  String get typeLabel {
    switch (type) {
      case QuestionType.singleChoice:
        return 'Single choice';
      case QuestionType.multipleChoice:
        return 'Multiple answer';
      case QuestionType.trueFalse:
        return 'True / false';
      case QuestionType.shortAnswer:
        return 'Short answer';
      case QuestionType.fillBlank:
        return 'Fill in the blank';
      case QuestionType.matching:
        return 'Matching';
      case QuestionType.ordering:
        return 'Ordering';
      case QuestionType.numerical:
        return 'Numerical';
      case QuestionType.scenario:
        return 'Scenario';
      case QuestionType.code:
        return 'Code';
      case QuestionType.openEnded:
        return 'Self evaluated';
    }
  }

  QuestionScore scoreAnswer(AnswerValue answer) {
    if (!answer.isAnswered) {
      return QuestionScore(
        earnedPoints: 0,
        maxPoints: points,
        isCorrect: false,
        needsManualReview: type == QuestionType.openEnded,
      );
    }

    final correct = _isCorrect(answer);
    if (correct == null) {
      return QuestionScore(
        earnedPoints: 0,
        maxPoints: points,
        isCorrect: false,
        needsManualReview: true,
      );
    }

    return QuestionScore(
      earnedPoints: correct ? points : -negativeMarking,
      maxPoints: points,
      isCorrect: correct,
    );
  }

  String correctAnswerDisplay() {
    switch (type) {
      case QuestionType.singleChoice:
        final index = _intValue(correctAnswer);
        if (index != null && index >= 0 && index < options.length) {
          return options[index];
        }
        return correctAnswer?.toString() ?? 'Not specified';
      case QuestionType.multipleChoice:
        final indexes = _correctIndexes();
        if (indexes.isEmpty) return 'Not specified';
        return indexes
            .where((index) => index >= 0 && index < options.length)
            .map((index) => options[index])
            .join(', ');
      case QuestionType.trueFalse:
        final value = _boolValue(correctAnswer);
        return value == null
            ? 'Not specified'
            : value
            ? 'True'
            : 'False';
      case QuestionType.matching:
        if (matchingPairs.isEmpty) return 'Not specified';
        return matchingPairs.entries
            .map((entry) => '${entry.key} -> ${entry.value}')
            .join('\n');
      case QuestionType.ordering:
        if (correctOrder.isEmpty) return 'Not specified';
        return correctOrder
            .asMap()
            .entries
            .map((entry) => '${entry.key + 1}. ${entry.value}')
            .join('\n');
      case QuestionType.numerical:
        return correctAnswer?.toString() ??
            (acceptedAnswers.isEmpty
                ? 'Not specified'
                : acceptedAnswers.join(', '));
      case QuestionType.shortAnswer:
      case QuestionType.fillBlank:
      case QuestionType.scenario:
      case QuestionType.code:
      case QuestionType.openEnded:
        return modelAnswer ??
            referenceSolution ??
            (acceptedAnswers.isEmpty ? null : acceptedAnswers.join(', ')) ??
            'Review explanation or rubric';
    }
  }

  bool? _isCorrect(AnswerValue answer) {
    switch (type) {
      case QuestionType.singleChoice:
        return answer.selectedIndex == _intValue(correctAnswer);
      case QuestionType.multipleChoice:
        final selected = [...answer.selectedIndexes]..sort();
        final correct = _correctIndexes()..sort();
        if (correct.isEmpty) return false;
        return _sameList(selected, correct);
      case QuestionType.trueFalse:
        return answer.booleanValue == _boolValue(correctAnswer);
      case QuestionType.shortAnswer:
      case QuestionType.fillBlank:
      case QuestionType.scenario:
        return _matchesText(answer.text ?? '');
      case QuestionType.code:
        return _matchesRubric(answer.text ?? '');
      case QuestionType.matching:
        if (matchingPairs.isEmpty) return false;
        return matchingPairs.entries.every(
          (entry) => answer.pairs[entry.key] == entry.value,
        );
      case QuestionType.ordering:
        if (correctOrder.isEmpty) return false;
        return _sameList(answer.orderedItems, correctOrder);
      case QuestionType.numerical:
        final expected = _doubleValue(correctAnswer, fallback: double.nan);
        final actual = answer.numberValue;
        if (actual == null || expected.isNaN) return false;
        return (actual - expected).abs() <= (tolerance ?? 0);
      case QuestionType.openEnded:
        return answer.selfEvaluatedCorrect;
    }
  }

  bool _matchesText(String userResponse) {
    final normalized = userResponse.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final accepted = [
      ...acceptedAnswers,
      if (correctAnswer != null) correctAnswer.toString(),
    ].where((value) => value.trim().isNotEmpty).toList();

    if (accepted.isNotEmpty) {
      return accepted.any(
        (answer) => answer.trim().toLowerCase() == normalized,
      );
    }

    if (keywords.isEmpty) return false;

    double score = 0;
    double totalWeight = 0;
    for (final keyword in keywords) {
      final keywordText = keyword['text']?.toString().toLowerCase() ?? '';
      final weight = _doubleValue(keyword['weight'], fallback: 1);
      totalWeight += weight;
      if (keywordText.isNotEmpty && normalized.contains(keywordText)) {
        score += weight;
      }
    }

    return totalWeight > 0 && (score / totalWeight) >= 0.6;
  }

  bool _matchesRubric(String userResponse) {
    if (rubric?['checklist'] is! List) return _matchesText(userResponse);
    final checklist = List<String>.from(rubric!['checklist']);
    if (checklist.isEmpty) return false;

    final normalized = userResponse.toLowerCase();
    var matches = 0;
    for (final item in checklist) {
      final words = item
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((word) => word.length > 2);
      if (words.any((word) => normalized.contains(word))) matches++;
    }

    return matches / checklist.length >= 0.5;
  }

  List<int> _correctIndexes() {
    if (correctAnswers.isNotEmpty) {
      return correctAnswers.map(_intValue).whereType<int>().toList();
    }
    if (correctAnswer is List) {
      return (correctAnswer as List).map(_intValue).whereType<int>().toList();
    }
    final single = _intValue(correctAnswer);
    return single == null ? [] : [single];
  }
}

QuestionType _parseQuestionType(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'single_choice':
    case 'singlechoice':
    case 'mcq':
      return QuestionType.singleChoice;
    case 'multiple_choice':
    case 'multiple_answer':
    case 'multiplechoice':
    case 'multi_select':
      return QuestionType.multipleChoice;
    case 'true_false':
    case 'truefalse':
    case 'boolean':
      return QuestionType.trueFalse;
    case 'fill_blank':
    case 'fill_in_the_blank':
    case 'fillblank':
      return QuestionType.fillBlank;
    case 'matching':
      return QuestionType.matching;
    case 'ordering':
    case 'sequencing':
      return QuestionType.ordering;
    case 'numerical':
    case 'number':
      return QuestionType.numerical;
    case 'scenario':
    case 'case':
    case 'case_based':
      return QuestionType.scenario;
    case 'code':
    case 'practical':
      return QuestionType.code;
    case 'open_ended':
    case 'openended':
    case 'self_evaluated':
      return QuestionType.openEnded;
    case 'short_answer':
    default:
      return QuestionType.shortAnswer;
  }
}

QuestionDifficulty _parseDifficulty(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'foundation':
    case 'easy':
    case 'beginner':
      return QuestionDifficulty.foundation;
    case 'intermediate':
    case 'medium':
      return QuestionDifficulty.intermediate;
    case 'advanced':
    case 'hard':
      return QuestionDifficulty.advanced;
    default:
      return QuestionDifficulty.mixed;
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

Map<String, String> _stringMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
  return const {};
}

Duration? _durationFromSeconds(dynamic value) {
  final seconds = _intValue(value);
  return seconds == null ? null : Duration(seconds: seconds);
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _doubleValue(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool? _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

bool _sameList<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var i = 0; i < first.length; i++) {
    if (first[i] != second[i]) return false;
  }
  return true;
}
