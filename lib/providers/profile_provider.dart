import 'package:flutter/material.dart';

import '../models/user_profile_model.dart';
import '../services/database/sqlite_service.dart';

class ProfileProvider with ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get hasProfile =>
      _profile != null && _profile!.username.trim().isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile() async {
    _setLoading(true);
    try {
      _profile = await SqliteService.instance.getUserProfile();
      _error = null;
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      _error = 'Profile could not be loaded.';
    }
    _setLoading(false);
  }

  Future<bool> createProfile(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      _error = 'Username cannot be empty.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      _profile = UserProfile.create(trimmed);
      await SqliteService.instance.saveUserProfile(_profile!);
      _error = null;
    } catch (e) {
      debugPrint('Failed to create profile: $e');
      _error = 'Profile could not be saved.';
    }
    _setLoading(false);
    return _error == null;
  }

  Future<bool> updateUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      _error = 'Username cannot be empty.';
      notifyListeners();
      return false;
    }
    if (_profile == null) return createProfile(trimmed);

    _setLoading(true);
    try {
      _profile = _profile!.copyWith(username: trimmed);
      await SqliteService.instance.saveUserProfile(_profile!);
      _error = null;
    } catch (e) {
      debugPrint('Failed to update username: $e');
      _error = 'Username could not be saved.';
    }
    _setLoading(false);
    return _error == null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
