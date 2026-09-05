import 'question_model.dart';

enum TestMode { practice, exam, weaknessPractice }

enum TestDifficulty { mixed, foundation, intermediate, advanced }

class TestModel {
  final String id;
  final String title;
  final String topic;
  final String description;
  final String version;
  final TestMode defaultMode;
  final TestDifficulty difficulty;
  final Duration? estimatedDuration;
  final List<String> categories;
  final Map<String, dynamic> scoringRules;
  final DateTime generatedAt;
  final double? passingScore;
  final Map<String, dynamic> selectionConfig;
  final bool shuffleAnswers;
  final bool shuffleQuestions;
  final List<Question> questions;

  TestModel({
    String? id,
    required this.title,
    this.topic = '',
    required this.description,
    required this.version,
    this.defaultMode = TestMode.practice,
    this.difficulty = TestDifficulty.mixed,
    this.estimatedDuration,
    this.categories = const [],
    this.scoringRules = const {},
    DateTime? generatedAt,
    this.passingScore,
    this.selectionConfig = const {},
    this.shuffleAnswers = false,
    this.shuffleQuestions = false,
    required this.questions,
  }) : id = id ?? title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
       generatedAt = generatedAt ?? DateTime.now();

  factory TestModel.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List)
        .map((question) => Question.fromJson(question as Map<String, dynamic>))
        .toList();

    return TestModel(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Test',
      topic: json['topic']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      version: json['version']?.toString() ?? '1.0',
      defaultMode: _parseMode(json['test_mode'] ?? json['mode']),
      difficulty: _parseDifficulty(json['difficulty']),
      estimatedDuration: _durationFromMinutes(
        json['estimated_duration'] ?? json['estimatedDuration'],
      ),
      categories: _stringList(json['categories']),
      scoringRules: _map(json['scoring_rules'] ?? json['scoringRules']),
      generatedAt: _dateValue(json['generated_date'] ?? json['generatedAt']),
      passingScore: (json['passing_score'] ?? json['passingScore']) is num
          ? ((json['passing_score'] ?? json['passingScore']) as num).toDouble()
          : null,
      selectionConfig: _map(
        json['question_selection'] ?? json['selectionConfig'],
      ),
      shuffleAnswers:
          json['shuffle_answers'] == true || json['shuffleAnswers'] == true,
      shuffleQuestions:
          json['shuffle_questions'] == true || json['shuffleQuestions'] == true,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (topic.isNotEmpty) 'topic': topic,
      'description': description,
      'version': version,
      'test_mode': defaultMode.name,
      'difficulty': difficulty.name,
      if (estimatedDuration != null)
        'estimated_duration': estimatedDuration!.inMinutes,
      if (categories.isNotEmpty) 'categories': categories,
      if (scoringRules.isNotEmpty) 'scoring_rules': scoringRules,
      'generated_date': generatedAt.toIso8601String(),
      if (passingScore != null) 'passing_score': passingScore,
      if (selectionConfig.isNotEmpty) 'question_selection': selectionConfig,
      'shuffle_answers': shuffleAnswers,
      'shuffle_questions': shuffleQuestions,
      'question_count': questions.length,
      'questions': questions.map((question) => question.toJson()).toList(),
    };
  }

  int get questionCount => questions.length;

  Duration get effectiveEstimatedDuration {
    if (estimatedDuration != null) return estimatedDuration!;

    final seconds = questions.fold<int>(
      0,
      (total, question) => total + (question.estimatedTime?.inSeconds ?? 60),
    );
    return Duration(seconds: seconds);
  }

  TestModel copyWith({
    String? id,
    String? title,
    String? topic,
    String? description,
    String? version,
    TestMode? defaultMode,
    TestDifficulty? difficulty,
    Duration? estimatedDuration,
    List<String>? categories,
    Map<String, dynamic>? scoringRules,
    DateTime? generatedAt,
    double? passingScore,
    Map<String, dynamic>? selectionConfig,
    bool? shuffleAnswers,
    bool? shuffleQuestions,
    List<Question>? questions,
  }) {
    return TestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      version: version ?? this.version,
      defaultMode: defaultMode ?? this.defaultMode,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      categories: categories ?? this.categories,
      scoringRules: scoringRules ?? this.scoringRules,
      generatedAt: generatedAt ?? this.generatedAt,
      passingScore: passingScore ?? this.passingScore,
      selectionConfig: selectionConfig ?? this.selectionConfig,
      shuffleAnswers: shuffleAnswers ?? this.shuffleAnswers,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      questions: questions ?? this.questions,
    );
  }
}

TestMode _parseMode(dynamic value) {
  switch (value?.toString().toLowerCase()) {
    case 'exam':
    case 'test':
      return TestMode.exam;
    case 'weaknesspractice':
    case 'weakness_practice':
    case 'weakness':
      return TestMode.weaknessPractice;
    case 'practice':
    default:
      return TestMode.practice;
  }
}

TestDifficulty _parseDifficulty(dynamic value) {
  switch (value?.toString().toLowerCase()) {
    case 'foundation':
    case 'easy':
      return TestDifficulty.foundation;
    case 'intermediate':
    case 'medium':
      return TestDifficulty.intermediate;
    case 'advanced':
    case 'hard':
      return TestDifficulty.advanced;
    default:
      return TestDifficulty.mixed;
  }
}

Duration? _durationFromMinutes(dynamic value) {
  if (value is int) return Duration(minutes: value);
  if (value is num) return Duration(minutes: value.toInt());
  if (value is String) {
    final minutes = int.tryParse(value);
    if (minutes != null) return Duration(minutes: minutes);
  }
  return null;
}

DateTime? _dateValue(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<String> _stringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}
