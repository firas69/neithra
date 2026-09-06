# Project Structure

Neithra keeps the Flutter app organized by responsibility. The goal is to make
new question types, persistence changes, and review analytics possible without turning
screen widgets into large conditional blocks.

## Source Layout

```text
lib/
  main.dart
  core/
    constants/          App colors, text constants, and theme
    utils/              Small file helpers and local-calendar streak logic
  models/
    answer_value_model.dart
    exam_family_model.dart
    imported_test_model.dart
    question_model.dart
    response_model.dart
    result_model.dart
    session_snapshot_model.dart
    test_attempt_model.dart
    test_model.dart
    user_profile_model.dart
  providers/
    history_provider.dart
    profile_provider.dart
    test_provider.dart
    test_library_provider.dart
    session_provider.dart
    result_provider.dart
  services/
    api/                Optional remote history integration
    database/           Local file persistence and SQLite
    exam_fingerprint_service.dart
    exam_statistics_service.dart
    json_parser_service.dart
  views/
    app_bootstrap.dart
    app_shell.dart
    home_dashboard_screen.dart
    exams_screen.dart
    exam_detail_screen.dart
    family_detail_screen.dart
    history_screen.dart
    history_detail_screen.dart
    profile_screen.dart
    username_onboarding_screen.dart
    exam_screen.dart
    results_screen.dart
  widgets/
    answer_input_widget.dart
    custom_button.dart
    question_widget.dart
    timer_widget.dart
```

## App Flow

```text
JSON exam definition
  -> JsonParserService
  -> TestModel / Question models
  -> ExamFamily / ImportedTest / TestLibraryProvider
  -> SessionProvider
  -> SqliteService snapshots
  -> ResultProvider scoring
  -> TestAttempt / HistoryProvider
  -> ResultsScreen and HistoryDetailScreen review
```

## State Management

The app uses `provider` for simple, explicit state ownership:

- `ProfileProvider`: first-launch username and profile edits.
- `TestLibraryProvider`: families, imported exams, search state, duplicate-safe import,
  family assignment, moving, and rename/delete actions.
- `TestProvider`: current exam handoff into the active exam screen. The name is retained
  internally for compatibility with the existing JSON/session model.
- `SessionProvider`: active session, current question, answers, flags, elapsed time,
  per-question timing, pause/resume snapshots.
- `ResultProvider`: scoring, category analytics, and optional remote history persistence.
- `HistoryProvider`: immutable completed attempts and activity streak input.

## Persistence

- `FileDbService` remains for backward-compatible current-definition storage.
- `SqliteService` stores the profile, exam families, imported exam library, resumable
  session snapshots, response history, and completed attempts.
- A session snapshot includes family context, concrete question order, current index,
  answers, flags, elapsed time, per-question timing, mode, and status.
- A completed attempt stores exam name, score, elapsed time, completion date, and
  question-by-question review data independently from the current imported exam.
- Imported exams store a canonical SHA-256 `contentHash` so semantically identical JSON
  is rejected even if formatting or file names differ.
- `ExamStatisticsService` derives global, family, and exam-level statistics from attempts.
- Completed attempts store `familyId` and `familyName` snapshots for historical integrity.

## Question Rendering

`AnswerInputWidget` dispatches by `QuestionType`, while `Question` owns validation and
scoring. This keeps UI rendering, answer representation, and scoring connected but not
jammed into one screen.

Supported types:

- Single choice
- Multiple answer
- True/false
- Short answer
- Fill in the blank
- Matching
- Ordering
- Numerical
- Scenario/case-based
- Code-related
- Open-ended/self-evaluated

## Extension Points

- Add a new `QuestionType` in `question_model.dart`.
- Add the answer shape in `answer_value_model.dart`.
- Add focused rendering in `answer_input_widget.dart`.
- Extend `JsonParserService` validation if the type has required fields.
- Add tests for parser, scoring, fingerprinting, and answer-state behavior.
