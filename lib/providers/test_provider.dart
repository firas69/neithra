import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../services/database/file_db_service.dart';
import '../services/json_parser_service.dart';

class TestProvider with ChangeNotifier {
  TestModel? _currentTest;
  bool _isLoading = false;
  String? _error;

  TestModel? get currentTest => _currentTest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTest => _currentTest != null;

  final FileDbService _fileDbService = FileDbService();

  Future<void> loadTestFromJson(String jsonString) async {
    _setLoading(true);
    try {
      _currentTest = JsonParserService.parseJsonString(jsonString);
      await _fileDbService.saveTestData(_currentTest!);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentTest = null;
    }
    _setLoading(false);
  }

  Future<void> loadSavedTest() async {
    _setLoading(true);
    try {
      _currentTest = await _fileDbService.loadTestData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> hasSavedTest() async {
    return await _fileDbService.hasTestData();
  }

  void setCurrentTest(TestModel test) {
    _currentTest = test;
    _error = null;
    notifyListeners();
  }

  TestModel? createWeaknessPractice(List<String> categories) {
    if (_currentTest == null || categories.isEmpty) return _currentTest;

    final selected = _currentTest!.questions.where((question) {
      final category = question.category ?? question.topic ?? 'General';
      return categories.contains(category);
    }).toList();

    if (selected.isEmpty) return _currentTest;

    return TestModel(
      id: '${_currentTest!.id}-weakness',
      title: '${_currentTest!.title} - Weakness Practice',
      topic: _currentTest!.topic,
      description: 'Focused practice from your lowest-scoring categories.',
      version: _currentTest!.version,
      defaultMode: TestMode.weaknessPractice,
      difficulty: _currentTest!.difficulty,
      estimatedDuration: _currentTest!.estimatedDuration,
      categories: categories,
      scoringRules: _currentTest!.scoringRules,
      passingScore: _currentTest!.passingScore,
      selectionConfig: {
        ..._currentTest!.selectionConfig,
        'source': 'weaknessPractice',
      },
      shuffleAnswers: _currentTest!.shuffleAnswers,
      shuffleQuestions: true,
      questions: selected,
    );
  }

  void clearTest() async {
    _currentTest = null;
    await _fileDbService.clearTestData();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
