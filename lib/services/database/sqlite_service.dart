import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/answer_value_model.dart';
import '../../models/response_model.dart';
import '../../models/session_snapshot_model.dart';
import '../../models/test_model.dart';

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
      version: 2,
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
