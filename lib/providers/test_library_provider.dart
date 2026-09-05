import 'package:flutter/material.dart';

import '../models/imported_test_model.dart';
import '../services/database/sqlite_service.dart';
import '../services/exam_fingerprint_service.dart';
import '../services/json_parser_service.dart';

class TestLibraryProvider with ChangeNotifier {
  final List<ImportedTest> _tests = [];
  bool _isLoading = false;
  String? _error;
  ImportedTest? _duplicateExam;
  String _searchQuery = '';

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

  Future<void> loadTests() async {
    _setLoading(true);
    try {
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

  Future<ImportedTest?> importJson(String jsonString) async {
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

      final importedTest = ImportedTest.fromParsedTest(parsed, contentHash);
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
