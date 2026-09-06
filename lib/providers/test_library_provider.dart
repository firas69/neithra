import 'package:flutter/material.dart';

import '../models/exam_family_model.dart';
import '../models/imported_test_model.dart';
import '../models/test_attempt_model.dart';
import '../services/database/sqlite_service.dart';
import '../services/exam_fingerprint_service.dart';
import '../services/exam_statistics_service.dart';
import '../services/json_parser_service.dart';

class TestLibraryProvider with ChangeNotifier {
  final List<ExamFamily> _families = [];
  final List<ImportedTest> _tests = [];
  bool _isLoading = false;
  String? _error;
  ImportedTest? _duplicateExam;
  String _searchQuery = '';

  List<ExamFamily> get families => List.unmodifiable(_families);
  List<ImportedTest> get tests => List.unmodifiable(_tests);
  bool get isLoading => _isLoading;
  String? get error => _error;
  ImportedTest? get duplicateExam => _duplicateExam;
  String get searchQuery => _searchQuery;

  List<ImportedTest> get filteredTests {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return tests;
    return _tests.where((item) {
      final searchable = [
        item.displayName,
        item.test.topic,
        item.test.description,
        ...item.test.categories,
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  List<ExamFamily> get filteredFamilies {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return families;

    return _families.where((family) {
      final familyMatches = family.name.toLowerCase().contains(query);
      final examMatches = _tests.any(
        (exam) =>
            exam.familyId == family.id && _examSearchText(exam).contains(query),
      );
      return familyMatches || examMatches;
    }).toList();
  }

  List<ImportedTest> testsForFamily(String familyId, {String query = ''}) {
    final normalizedQuery = query.trim().toLowerCase();
    return _tests.where((exam) {
      if (exam.familyId != familyId) return false;
      if (normalizedQuery.isEmpty) return true;
      return _examSearchText(exam).contains(normalizedQuery);
    }).toList();
  }

  ExamFamily familyForId(String familyId) {
    return _families.firstWhere(
      (family) => family.id == familyId,
      orElse: ExamFamily.uncategorized,
    );
  }

  String familyNameFor(String familyId) => familyForId(familyId).name;

  ExamStats globalStats(List<TestAttempt> attempts) {
    return ExamStatisticsService.global(exams: _tests, attempts: attempts);
  }

  ExamStats familyStats(String familyId, List<TestAttempt> attempts) {
    return ExamStatisticsService.forFamily(
      family: familyForId(familyId),
      exams: _tests,
      attempts: attempts,
    );
  }

  ExamStats examStats(String examId, List<TestAttempt> attempts) {
    final exam = findById(examId);
    if (exam == null) {
      return ExamStatisticsService.global(exams: const [], attempts: const []);
    }
    return ExamStatisticsService.forExam(exam: exam, attempts: attempts);
  }

  Future<void> loadTests() async {
    _setLoading(true);
    try {
      _families
        ..clear()
        ..addAll(await SqliteService.instance.getExamFamilies());
      _tests
        ..clear()
        ..addAll(await SqliteService.instance.getImportedTests());
      _error = null;
      _duplicateExam = null;
    } catch (e) {
      debugPrint('Failed to load exams: $e');
      _error = 'Exams could not be loaded.';
    }
    _setLoading(false);
  }

  Future<ImportedTest?> importJson(
    String jsonString, {
    String familyId = ExamFamily.uncategorizedId,
  }) async {
    _setLoading(true);
    try {
      final parsed = JsonParserService.parseJsonString(jsonString);
      if (parsed == null) {
        throw const FormatException('No exam could be parsed.');
      }
      final contentHash = ExamFingerprintService.hashTest(parsed);
      final duplicate = await SqliteService.instance
          .getImportedTestByContentHash(contentHash);
      if (duplicate != null) {
        _duplicateExam = duplicate;
        _error = 'This exam has already been imported.';
        _setLoading(false);
        return null;
      }

      final selectedFamily = familyForId(familyId);
      final importedTest = ImportedTest.fromParsedTest(
        parsed,
        contentHash,
        familyId: selectedFamily.id,
      );
      await SqliteService.instance.saveImportedTest(importedTest);
      _tests.insert(0, importedTest);
      _error = null;
      _duplicateExam = null;
      _setLoading(false);
      return importedTest;
    } catch (e) {
      debugPrint('Failed to import exam: $e');
      _error = _friendlyImportError(e);
      _duplicateExam = null;
      _setLoading(false);
      return null;
    }
  }

  Future<ExamFamily?> createFamily(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _error = 'Family name cannot be empty.';
      notifyListeners();
      return null;
    }

    try {
      final family = ExamFamily.create(trimmed);
      await SqliteService.instance.saveExamFamily(family);
      _families.add(family);
      _families.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _error = null;
      notifyListeners();
      return family;
    } catch (e) {
      debugPrint('Failed to create family: $e');
      _error = 'A family with this name already exists.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> renameFamily(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _error = 'Family name cannot be empty.';
      notifyListeners();
      return false;
    }

    try {
      await SqliteService.instance.renameExamFamily(id, trimmed);
      final index = _families.indexWhere((family) => family.id == id);
      if (index != -1) {
        _families[index] = _families[index].copyWith(name: trimmed);
      }
      _families.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to rename family: $e');
      _error = 'Family name could not be saved.';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteFamilyMoveExamsToUncategorized(String id) async {
    try {
      await SqliteService.instance.deleteExamFamilyMoveExamsToDefault(id);
      await loadTests();
      _error = null;
    } catch (e) {
      debugPrint('Failed to delete family: $e');
      _error = 'Family could not be deleted.';
      notifyListeners();
    }
  }

  Future<bool> moveExamToFamily(String examId, String familyId) async {
    try {
      await SqliteService.instance.moveImportedTestToFamily(examId, familyId);
      final index = _tests.indexWhere((exam) => exam.id == examId);
      if (index != -1) {
        _tests[index] = _tests[index].copyWith(
          familyId: familyId,
          updatedAt: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to move exam: $e');
      _error = 'Exam could not be moved.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameTest(String id, String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      _error = 'Exam name cannot be empty.';
      notifyListeners();
      return false;
    }

    try {
      await SqliteService.instance.renameImportedTest(id, trimmed);
      final index = _tests.indexWhere((item) => item.id == id);
      if (index != -1) {
        _tests[index] = _tests[index].copyWith(
          displayName: trimmed,
          updatedAt: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to rename exam: $e');
      _error = 'Exam name could not be saved.';
      notifyListeners();
      return false;
    }
  }

  ImportedTest? findById(String id) {
    for (final test in _tests) {
      if (test.id == id) return test;
    }
    return null;
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String _examSearchText(ImportedTest exam) {
    return [
      exam.displayName,
      exam.test.topic,
      exam.test.description,
      ...exam.test.categories,
    ].join(' ').toLowerCase();
  }

  void clearError() {
    _error = null;
    _duplicateExam = null;
    notifyListeners();
  }

  String _friendlyImportError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('Missing required fields')) {
      return 'This file is missing a title or questions list.';
    }
    if (message.contains('Questions array cannot be empty')) {
      return 'This exam does not contain any questions.';
    }
    if (message.contains('Invalid JSON')) {
      return 'This file is not valid Neithra JSON.';
    }
    return 'This exam could not be imported. Please check the schema.';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
