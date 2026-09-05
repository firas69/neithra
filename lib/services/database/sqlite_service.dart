import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/answer_value_model.dart';
import '../../models/imported_test_model.dart';
import '../../models/response_model.dart';
import '../../models/session_snapshot_model.dart';
import '../../models/test_attempt_model.dart';
import '../../models/test_model.dart';
import '../../models/user_profile_model.dart';

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  factory SqliteService() => _instance;
  SqliteService._internal();
  static SqliteService get instance => _instance;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'quiz_app.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE responses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        questionId TEXT NOT NULL,
        response TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        sessionId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions(
        id TEXT PRIMARY KEY,
        testTitle TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        currentQuestionIndex INTEGER DEFAULT 0,
        isCompleted INTEGER DEFAULT 0,
        mode TEXT DEFAULT 'practice',
        status TEXT DEFAULT 'paused',
        testJson TEXT,
        answersJson TEXT DEFAULT '{}',
        flaggedQuestionIdsJson TEXT DEFAULT '[]',
        perQuestionSecondsJson TEXT DEFAULT '{}',
        elapsedSeconds INTEGER DEFAULT 0,
        totalQuestions INTEGER DEFAULT 0,
        answeredQuestions INTEGER DEFAULT 0,
        lastActiveAt TEXT
      )
    ''');

    await _createProfileTable(db);
    await _createImportedTestsTable(db);
    await _createTestAttemptsTable(db);
  }

  Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(
        db,
        'sessions',
        'mode',
        "TEXT DEFAULT 'practice'",
      );
      await _addColumnIfMissing(
        db,
        'sessions',
        'status',
        "TEXT DEFAULT 'paused'",
      );
      await _addColumnIfMissing(db, 'sessions', 'testJson', 'TEXT');
      await _addColumnIfMissing(
        db,
        'sessions',
        'answersJson',
        "TEXT DEFAULT '{}'",
      );
      await _addColumnIfMissing(
        db,
        'sessions',
        'flaggedQuestionIdsJson',
        "TEXT DEFAULT '[]'",
      );
      await _addColumnIfMissing(
        db,
        'sessions',
        'perQuestionSecondsJson',
        "TEXT DEFAULT '{}'",
      );
      await _addColumnIfMissing(
        db,
        'sessions',
        'elapsedSeconds',
        'INTEGER DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        'sessions',
        'totalQuestions',
        'INTEGER DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        'sessions',
        'answeredQuestions',
        'INTEGER DEFAULT 0',
      );
      await _addColumnIfMissing(db, 'sessions', 'lastActiveAt', 'TEXT');
    }

    if (oldVersion < 3) {
      await _createProfileTable(db);
      await _createImportedTestsTable(db);
      await _createTestAttemptsTable(db);
    }
  }

  Future<void> _createProfileTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profiles(
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createImportedTestsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS imported_tests(
        id TEXT PRIMARY KEY,
        displayName TEXT NOT NULL,
        testJson TEXT NOT NULL,
        importedAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        lastAttemptAt TEXT,
        attemptsCount INTEGER DEFAULT 0,
        bestScore REAL
      )
    ''');
  }

  Future<void> _createTestAttemptsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS test_attempts(
        id TEXT PRIMARY KEY,
        testId TEXT NOT NULL,
        testName TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        elapsedSeconds INTEGER NOT NULL,
        scorePercentage REAL NOT NULL,
        earnedPoints REAL NOT NULL,
        maxPoints REAL NOT NULL,
        correctAnswers INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL,
        questionResultsJson TEXT NOT NULL
      )
    ''');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> init() async {
    await database;
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final rows = await db.query('profiles', orderBy: 'createdAt ASC', limit: 1);
    if (rows.isEmpty) return null;

    try {
      return UserProfile.fromJson(Map<String, dynamic>.from(rows.first));
    } catch (e) {
      debugPrint('Failed to read profile: $e');
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'profiles',
      profile.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveImportedTest(ImportedTest importedTest) async {
    final db = await database;
    await db.insert('imported_tests', {
      'id': importedTest.id,
      'displayName': importedTest.displayName,
      'testJson': jsonEncode(importedTest.test.toJson()),
      'importedAt': importedTest.importedAt.toIso8601String(),
      'updatedAt': importedTest.updatedAt.toIso8601String(),
      'lastAttemptAt': importedTest.lastAttemptAt?.toIso8601String(),
      'attemptsCount': importedTest.attemptsCount,
      'bestScore': importedTest.bestScore,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ImportedTest>> getImportedTests() async {
    final db = await database;
    final rows = await db.query('imported_tests', orderBy: 'updatedAt DESC');
    final tests = <ImportedTest>[];

    for (final row in rows) {
      try {
        tests.add(_importedTestFromRow(row));
      } catch (e) {
        debugPrint('Skipping malformed imported test ${row['id']}: $e');
      }
    }

    return tests;
  }

  Future<void> renameImportedTest(String id, String displayName) async {
    final db = await database;
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Test name cannot be empty');
    }

    final rows = await db.query(
      'imported_tests',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final importedTest = _importedTestFromRow(
      rows.first,
    ).copyWith(displayName: trimmed, updatedAt: DateTime.now());
    await saveImportedTest(importedTest);
  }

  Future<void> saveTestAttempt(TestAttempt attempt) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('test_attempts', {
        'id': attempt.id,
        'testId': attempt.testId,
        'testName': attempt.testName,
        'startedAt': attempt.startedAt.toIso8601String(),
        'completedAt': attempt.completedAt.toIso8601String(),
        'elapsedSeconds': attempt.elapsedTime.inSeconds,
        'scorePercentage': attempt.scorePercentage,
        'earnedPoints': attempt.earnedPoints,
        'maxPoints': attempt.maxPoints,
        'correctAnswers': attempt.correctAnswers,
        'totalQuestions': attempt.totalQuestions,
        'questionResultsJson': jsonEncode(
          attempt.questionResults.map((item) => item.toJson()).toList(),
        ),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final rows = await txn.query(
        'imported_tests',
        where: 'id = ?',
        whereArgs: [attempt.testId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final importedTest = _importedTestFromRow(rows.first);
        await txn.update(
          'imported_tests',
          {
            'lastAttemptAt': attempt.completedAt.toIso8601String(),
            'attemptsCount': importedTest.attemptsCount + 1,
            'bestScore': importedTest.bestScore == null
                ? attempt.scorePercentage
                : importedTest.bestScore! > attempt.scorePercentage
                ? importedTest.bestScore
                : attempt.scorePercentage,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [attempt.testId],
        );
      }
    });
  }

  Future<List<TestAttempt>> getTestAttempts() async {
    final db = await database;
    final rows = await db.query('test_attempts', orderBy: 'completedAt DESC');
    final attempts = <TestAttempt>[];

    for (final row in rows) {
      try {
        attempts.add(_testAttemptFromRow(row));
      } catch (e) {
        debugPrint('Skipping malformed attempt ${row['id']}: $e');
      }
    }

    return attempts;
  }

  Future<TestAttempt?> getTestAttempt(String id) async {
    final db = await database;
    final rows = await db.query(
      'test_attempts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    try {
      return _testAttemptFromRow(rows.first);
    } catch (e) {
      debugPrint('Failed to read attempt $id: $e');
      return null;
    }
  }

  Future<void> saveResponse(ResponseModel response) async {
    final db = await database;
    await db.insert('responses', response.toJson());
  }

  Future<List<ResponseModel>> getResponsesForSession(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'responses',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(
      maps.length,
      (index) => ResponseModel.fromJson(Map<String, dynamic>.from(maps[index])),
    );
  }

  Future<void> createSession(String sessionId, String testTitle) async {
    final db = await database;
    await db.insert('sessions', {
      'id': sessionId,
      'testTitle': testTitle,
      'startTime': DateTime.now().toIso8601String(),
      'currentQuestionIndex': 0,
      'isCompleted': 0,
      'lastActiveAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveSessionSnapshot(SessionSnapshot snapshot) async {
    final db = await database;
    final answersJson = snapshot.answers.map(
      (key, value) => MapEntry(key, value.toJson()),
    );

    await db.insert('sessions', {
      'id': snapshot.id,
      'testTitle': snapshot.test.title,
      'startTime': snapshot.startedAt.toIso8601String(),
      'endTime': snapshot.status == SessionStatus.completed
          ? snapshot.lastActiveAt.toIso8601String()
          : null,
      'currentQuestionIndex': snapshot.currentQuestionIndex,
      'isCompleted': snapshot.status == SessionStatus.completed ? 1 : 0,
      'mode': snapshot.mode.name,
      'status': snapshot.status.name,
      'testJson': jsonEncode(snapshot.test.toJson()),
      'answersJson': jsonEncode(answersJson),
      'flaggedQuestionIdsJson': jsonEncode(
        snapshot.flaggedQuestionIds.toList(),
      ),
      'perQuestionSecondsJson': jsonEncode(snapshot.perQuestionSeconds),
      'elapsedSeconds': snapshot.elapsedTime.inSeconds,
      'totalQuestions': snapshot.test.questions.length,
      'answeredQuestions': snapshot.answers.values
          .where((answer) => answer.isAnswered)
          .length,
      'lastActiveAt': snapshot.lastActiveAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SessionSummary>> getSavedSessionSummaries() async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      where: 'isCompleted = ? AND testJson IS NOT NULL',
      whereArgs: [0],
      orderBy: 'lastActiveAt DESC',
    );

    return rows.map((row) {
      return SessionSummary.fromJson({
        'id': row['id'],
        'testTitle': row['testTitle'],
        'mode': row['mode'],
        'currentQuestionIndex': row['currentQuestionIndex'],
        'totalQuestions': row['totalQuestions'],
        'answeredQuestions': row['answeredQuestions'],
        'elapsedSeconds': row['elapsedSeconds'],
        'status': row['status'],
        'startedAt': row['startTime'],
        'lastActiveAt': row['lastActiveAt'] ?? row['startTime'],
      });
    }).toList();
  }

  Future<SessionSnapshot?> getSessionSnapshot(String sessionId) async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      where: 'id = ? AND testJson IS NOT NULL',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final row = rows.first;
    final test = TestModel.fromJson(
      jsonDecode(row['testJson'] as String) as Map<String, dynamic>,
    );
    final rawAnswers = jsonDecode(row['answersJson']?.toString() ?? '{}');
    final rawFlags = jsonDecode(
      row['flaggedQuestionIdsJson']?.toString() ?? '[]',
    );
    final rawTiming = jsonDecode(
      row['perQuestionSecondsJson']?.toString() ?? '{}',
    );

    return SessionSnapshot(
      id: row['id'].toString(),
      test: test,
      mode: _parseMode(row['mode']),
      currentQuestionIndex: row['currentQuestionIndex'] as int? ?? 0,
      answers: rawAnswers is Map
          ? rawAnswers.map(
              (key, value) => MapEntry(
                key.toString(),
                AnswerValue.fromJson(Map<String, dynamic>.from(value as Map)),
              ),
            )
          : {},
      flaggedQuestionIds: rawFlags is List
          ? rawFlags.map((item) => item.toString()).toSet()
          : {},
      perQuestionSeconds: rawTiming is Map
          ? rawTiming.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            )
          : {},
      elapsedTime: Duration(seconds: row['elapsedSeconds'] as int? ?? 0),
      status: _parseStatus(row['status']),
      startedAt:
          DateTime.tryParse(row['startTime']?.toString() ?? '') ??
          DateTime.now(),
      lastActiveAt:
          DateTime.tryParse(row['lastActiveAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> updateSessionProgress(
    String sessionId,
    int questionIndex,
  ) async {
    final db = await database;
    await db.update(
      'sessions',
      {
        'currentQuestionIndex': questionIndex,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> completeSession(String sessionId) async {
    final db = await database;
    await db.update(
      'sessions',
      {
        'endTime': DateTime.now().toIso8601String(),
        'isCompleted': 1,
        'status': SessionStatus.completed.name,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    await db.delete(
      'responses',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  ImportedTest _importedTestFromRow(Map<String, Object?> row) {
    final test = TestModel.fromJson(
      jsonDecode(row['testJson'].toString()) as Map<String, dynamic>,
    );
    return ImportedTest.fromJson({
      'id': row['id'],
      'displayName': row['displayName'],
      'test': test.toJson(),
      'importedAt': row['importedAt'],
      'updatedAt': row['updatedAt'],
      'lastAttemptAt': row['lastAttemptAt'],
      'attemptsCount': row['attemptsCount'],
      'bestScore': row['bestScore'],
    });
  }

  TestAttempt _testAttemptFromRow(Map<String, Object?> row) {
    final rawQuestionResults = jsonDecode(
      row['questionResultsJson']?.toString() ?? '[]',
    );
    return TestAttempt.fromJson({
      'id': row['id'],
      'testId': row['testId'],
      'testName': row['testName'],
      'startedAt': row['startedAt'],
      'completedAt': row['completedAt'],
      'elapsedSeconds': row['elapsedSeconds'],
      'scorePercentage': row['scorePercentage'],
      'earnedPoints': row['earnedPoints'],
      'maxPoints': row['maxPoints'],
      'correctAnswers': row['correctAnswers'],
      'totalQuestions': row['totalQuestions'],
      'questionResults': rawQuestionResults,
    });
  }
}

TestMode _parseMode(dynamic value) {
  switch (value?.toString()) {
    case 'exam':
      return TestMode.exam;
    case 'weaknessPractice':
      return TestMode.weaknessPractice;
    case 'practice':
    default:
      return TestMode.practice;
  }
}

SessionStatus _parseStatus(dynamic value) {
  switch (value?.toString()) {
    case 'completed':
      return SessionStatus.completed;
    case 'active':
      return SessionStatus.active;
    case 'paused':
    default:
      return SessionStatus.paused;
  }
}
