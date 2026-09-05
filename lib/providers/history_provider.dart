import 'package:flutter/material.dart';

import '../core/utils/activity_streak.dart';
import '../models/test_attempt_model.dart';
import '../services/database/sqlite_service.dart';

class HistoryProvider with ChangeNotifier {
  final List<TestAttempt> _attempts = [];
  bool _isLoading = false;
  String? _error;

  List<TestAttempt> get attempts => List.unmodifiable(_attempts);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activityStreak =>
      ActivityStreak.currentStreak(_attempts.map((item) => item.completedAt));

  Future<void> loadHistory() async {
    _setLoading(true);
    try {
      _attempts
        ..clear()
        ..addAll(await SqliteService.instance.getTestAttempts());
      _error = null;
    } catch (e) {
      debugPrint('Failed to load history: $e');
      _error = 'History could not be loaded.';
    }
    _setLoading(false);
  }

  Future<void> saveAttempt(TestAttempt attempt) async {
    try {
      await SqliteService.instance.saveTestAttempt(attempt);
      _attempts.removeWhere((item) => item.id == attempt.id);
      _attempts.insert(0, attempt);
      _attempts.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save history attempt: $e');
      _error = 'Completed attempt could not be saved.';
      notifyListeners();
    }
  }

  TestAttempt? findById(String id) {
    for (final attempt in _attempts) {
      if (attempt.id == id) return attempt;
    }
    return null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
