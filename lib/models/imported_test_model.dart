import 'test_model.dart';

class ImportedTest {
  final String id;
  final String displayName;
  final TestModel test;
  final DateTime importedAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final int attemptsCount;
  final double? bestScore;

  const ImportedTest({
    required this.id,
    required this.displayName,
    required this.test,
    required this.importedAt,
    required this.updatedAt,
    this.lastAttemptAt,
    this.attemptsCount = 0,
    this.bestScore,
  });

  factory ImportedTest.fromParsedTest(TestModel test) {
    final now = DateTime.now();
    final id = 'test-${now.microsecondsSinceEpoch}';
    final name = test.title.trim().isEmpty
        ? 'Untitled Test'
        : test.title.trim();
    return ImportedTest(
      id: id,
      displayName: name,
      test: test.copyWith(id: id, title: name),
      importedAt: now,
      updatedAt: now,
    );
  }

  factory ImportedTest.fromJson(Map<String, dynamic> json) {
    final test = TestModel.fromJson(
      Map<String, dynamic>.from(json['test'] as Map),
    );
    final id = json['id'].toString();
    final displayName = json['displayName']?.toString().trim() ?? test.title;

    return ImportedTest(
      id: id,
      displayName: displayName.isEmpty ? 'Untitled Test' : displayName,
      test: test.copyWith(id: id, title: displayName),
      importedAt:
          DateTime.tryParse(json['importedAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      lastAttemptAt: DateTime.tryParse(json['lastAttemptAt']?.toString() ?? ''),
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toDouble(),
    );
  }

  ImportedTest copyWith({
    String? displayName,
    DateTime? updatedAt,
    DateTime? lastAttemptAt,
    int? attemptsCount,
    double? bestScore,
  }) {
    final nextName = displayName?.trim() ?? this.displayName;
    return ImportedTest(
      id: id,
      displayName: nextName,
      test: test.copyWith(id: id, title: nextName),
      importedAt: importedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      bestScore: bestScore ?? this.bestScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'test': test.copyWith(id: id, title: displayName).toJson(),
      'importedAt': importedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (lastAttemptAt != null)
        'lastAttemptAt': lastAttemptAt!.toIso8601String(),
      'attemptsCount': attemptsCount,
      if (bestScore != null) 'bestScore': bestScore,
    };
  }
}
