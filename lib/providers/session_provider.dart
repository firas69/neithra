import 'package:flutter/material.dart';

import '../models/answer_value_model.dart';
import '../models/question_model.dart';
import '../models/response_model.dart';
import '../models/session_snapshot_model.dart';
import '../models/test_model.dart';
import '../services/database/sqlite_service.dart';

class SessionProvider with ChangeNotifier {
  String? _sessionId;
  TestModel? _test;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<String, AnswerValue> _answers = {};
  final Set<String> _flaggedQuestionIds = {};
  final Map<String, int> _perQuestionSeconds = {};
  DateTime? _startedAt;
  DateTime? _currentRunStartedAt;
  DateTime? _lastQuestionStartedAt;
  Duration _elapsedBeforeCurrentRun = Duration.zero;
  bool _isSessionActive = false;
  TestMode _mode = TestMode.practice;
  SessionStatus _status = SessionStatus.paused;
  List<SessionSummary> _savedSessions = [];

  String? get sessionId => _sessionId;
  TestModel? get test => _test;
  TestMode get mode => _mode;
  SessionStatus get status => _status;
  List<Question> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Question? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;
  Map<String, AnswerValue> get answers => Map.unmodifiable(_answers);
  bool get isSessionActive => _isSessionActive;
  bool get hasNextQuestion => _currentQuestionIndex < _questions.length - 1;
  bool get isLastQuestion => _currentQuestionIndex == _questions.length - 1;
  DateTime? get startTime => _startedAt;
  List<SessionSummary> get savedSessions => _savedSessions;

  Duration get elapsedTime {
    if (!_isSessionActive || _currentRunStartedAt == null) {
      return _elapsedBeforeCurrentRun;
    }
    return _elapsedBeforeCurrentRun +
        DateTime.now().difference(_currentRunStartedAt!);
  }

  int get answeredCount =>
      _answers.values.where((answer) => answer.isAnswered).length;

  Future<void> startSession(
    TestModel test, {
    TestMode? mode,
    List<Question>? questions,
  }) async {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _mode = mode ?? test.defaultMode;
    _questions = questions ?? _prepareQuestions(test);
    _test = test.copyWith(questions: _questions);
    _currentQuestionIndex = 0;
    _answers.clear();
    _flaggedQuestionIds.clear();
    _perQuestionSeconds.clear();
    _startedAt = DateTime.now();
    _currentRunStartedAt = DateTime.now();
    _lastQuestionStartedAt = DateTime.now();
    _elapsedBeforeCurrentRun = Duration.zero;
    _isSessionActive = true;
    _status = SessionStatus.active;

    await SqliteService.instance.saveSessionSnapshot(_snapshot());
    notifyListeners();
  }

  Future<bool> resumeSession(String sessionId) async {
    final snapshot = await SqliteService.instance.getSessionSnapshot(sessionId);
    if (snapshot == null) return false;

    _sessionId = snapshot.id;
    _test = snapshot.test;
    _mode = snapshot.mode;
    _questions = snapshot.test.questions;
    _currentQuestionIndex = snapshot.currentQuestionIndex
        .clamp(0, snapshot.test.questions.length - 1)
        .toInt();
    _answers
      ..clear()
      ..addAll(snapshot.answers);
    _flaggedQuestionIds
      ..clear()
      ..addAll(snapshot.flaggedQuestionIds);
    _perQuestionSeconds
      ..clear()
      ..addAll(snapshot.perQuestionSeconds);
    _startedAt = snapshot.startedAt;
    _elapsedBeforeCurrentRun = snapshot.elapsedTime;
    _currentRunStartedAt = DateTime.now();
    _lastQuestionStartedAt = DateTime.now();
    _isSessionActive = true;
    _status = SessionStatus.active;

    await persistSession();
    notifyListeners();
    return true;
  }

  Future<void> loadSavedSessions() async {
    _savedSessions = await SqliteService.instance.getSavedSessionSummaries();
    notifyListeners();
  }

  Future<void> discardSession(String sessionId) async {
    await SqliteService.instance.deleteSession(sessionId);
    _savedSessions.removeWhere((session) => session.id == sessionId);
    if (_sessionId == sessionId) {
      resetSession(notify: false);
    }
    notifyListeners();
  }

  Future<void> saveAnswer(AnswerValue answer) async {
    if (currentQuestion == null || _sessionId == null) return;

    _answers[currentQuestion!.id] = answer;

    final responseModel = ResponseModel(
      questionId: currentQuestion!.id,
      answer: answer,
      timestamp: DateTime.now(),
      sessionId: _sessionId!,
    );

    await SqliteService.instance.saveResponse(responseModel);
    await persistSession(notify: false);
    notifyListeners();
  }

  Future<void> nextQuestion() async {
    if (hasNextQuestion) {
      await goToQuestion(_currentQuestionIndex + 1);
    }
  }

  Future<void> previousQuestion() async {
    if (_currentQuestionIndex > 0) {
      await goToQuestion(_currentQuestionIndex - 1);
    }
  }

  Future<void> goToQuestion(int index) async {
    if (index < 0 || index >= _questions.length || _sessionId == null) return;

    _captureQuestionTime();
    _currentQuestionIndex = index;
    _lastQuestionStartedAt = DateTime.now();
    await persistSession(notify: false);
    notifyListeners();
  }

  Future<void> toggleFlagCurrentQuestion() async {
    final question = currentQuestion;
    if (question == null) return;

    if (_flaggedQuestionIds.contains(question.id)) {
      _flaggedQuestionIds.remove(question.id);
    } else {
      _flaggedQuestionIds.add(question.id);
    }

    await persistSession(notify: false);
    notifyListeners();
  }

  bool isQuestionFlagged(String questionId) {
    return _flaggedQuestionIds.contains(questionId);
  }

  bool isQuestionAnswered(String questionId) {
    return _answers[questionId]?.isAnswered ?? false;
  }

  Future<void> pauseSession() async {
    if (_sessionId == null) return;
    _captureQuestionTime();
    _elapsedBeforeCurrentRun = elapsedTime;
    _currentRunStartedAt = null;
    _isSessionActive = false;
    _status = SessionStatus.paused;
    await persistSession(notify: false);
    await loadSavedSessions();
  }

  Future<void> completeSession() async {
    if (_sessionId == null) return;
    _captureQuestionTime();
    _elapsedBeforeCurrentRun = elapsedTime;
    _currentRunStartedAt = null;
    _isSessionActive = false;
    _status = SessionStatus.completed;
    await persistSession(notify: false);
    await SqliteService.instance.completeSession(_sessionId!);
    _savedSessions.removeWhere((session) => session.id == _sessionId);
    notifyListeners();
  }

  Future<void> persistSession({bool notify = true}) async {
    if (_sessionId == null || _test == null || _startedAt == null) return;
    await SqliteService.instance.saveSessionSnapshot(_snapshot());
    if (notify) notifyListeners();
  }

  AnswerValue getAnswerForQuestion(String questionId) {
    return _answers[questionId] ?? const AnswerValue.empty();
  }

  Map<String, int> get perQuestionSeconds =>
      Map.unmodifiable(_perQuestionSeconds);

  set currentQuestionIndex(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  void resetSession({bool notify = true}) {
    _sessionId = null;
    _test = null;
    _questions.clear();
    _currentQuestionIndex = 0;
    _answers.clear();
    _flaggedQuestionIds.clear();
    _perQuestionSeconds.clear();
    _startedAt = null;
    _currentRunStartedAt = null;
    _lastQuestionStartedAt = null;
    _elapsedBeforeCurrentRun = Duration.zero;
    _isSessionActive = false;
    _status = SessionStatus.paused;
    if (notify) notifyListeners();
  }

  List<Question> _prepareQuestions(TestModel test) {
    final prepared = [...test.questions];
    if (test.shuffleQuestions) prepared.shuffle();
    return prepared;
  }

  void _captureQuestionTime() {
    final question = currentQuestion;
    if (question == null || _lastQuestionStartedAt == null) return;

    final spent = DateTime.now().difference(_lastQuestionStartedAt!).inSeconds;
    _perQuestionSeconds[question.id] =
        (_perQuestionSeconds[question.id] ?? 0) + spent;
  }

  SessionSnapshot _snapshot() {
    return SessionSnapshot(
      id: _sessionId!,
      test: _test!,
      mode: _mode,
      currentQuestionIndex: _currentQuestionIndex,
      answers: Map.unmodifiable(_answers),
      flaggedQuestionIds: Set.unmodifiable(_flaggedQuestionIds),
      perQuestionSeconds: Map.unmodifiable(_perQuestionSeconds),
      elapsedTime: elapsedTime,
      status: _status,
      startedAt: _startedAt!,
      lastActiveAt: DateTime.now(),
    );
  }
}
