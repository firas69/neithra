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
    json_parser_service.dart
  views/
    app_bootstrap.dart
    app_shell.dart
    home_dashboard_screen.dart
    tests_screen.dart
    test_detail_screen.dart
    history_screen.dart
    history_detail_screen.dart
    profile_screen.dart
    username_onboarding_screen.dart
    upload_screen.dart
    practice_screen.dart
    results_screen.dart
  widgets/
    answer_input_widget.dart
    custom_button.dart
    question_widget.dart
    timer_widget.dart
```

## App Flow

```text
JSON test definition
  -> JsonParserService
  -> TestModel / Question models
  -> ImportedTest / TestLibraryProvider
  -> SessionProvider
  -> SqliteService snapshots
  -> ResultProvider scoring
  -> TestAttempt / HistoryProvider
  -> ResultsScreen and HistoryDetailScreen review
```

## State Management

The app uses `provider` for simple, explicit state ownership:

- `ProfileProvider`: first-launch username and profile edits.
- `TestLibraryProvider`: imported tests, search state, test import, and rename.
- `TestProvider`: current test handoff into the active practice screen and
  weakness-practice selection.
- `SessionProvider`: active session, current question, answers, flags, elapsed time,
  per-question timing, pause/resume snapshots.
- `ResultProvider`: scoring, category analytics, and optional remote history persistence.
- `HistoryProvider`: immutable completed attempts and activity streak input.

## Persistence

- `FileDbService` remains for backward-compatible current-test storage.
- `SqliteService` stores the profile, imported test library, resumable session snapshots,
  response history, and completed attempts.
- A session snapshot includes the concrete question order, current index, answers,
  flags, elapsed time, per-question timing, mode, and status.
- A completed attempt stores test name, score, elapsed time, completion date, and
  question-by-question review data independently from the current imported test.

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
- Add tests for parser and scoring behavior.
