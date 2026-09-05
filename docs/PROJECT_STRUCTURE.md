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
    utils/              Small file helpers
  models/
    answer_value_model.dart
    question_model.dart
    response_model.dart
    result_model.dart
    session_snapshot_model.dart
    test_model.dart
  providers/
    test_provider.dart
    session_provider.dart
    result_provider.dart
  services/
    api/                Optional remote history integration
    database/           Local file persistence and SQLite
    json_parser_service.dart
  views/
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
  -> TestProvider
  -> SessionProvider
  -> SqliteService snapshots
  -> ResultProvider scoring
  -> ResultsScreen review and weakness practice
```

## State Management

The app uses `provider` for simple, explicit state ownership:

- `TestProvider`: current loaded test and weakness-practice selection.
- `SessionProvider`: active session, current question, answers, flags, elapsed time,
  per-question timing, pause/resume snapshots.
- `ResultProvider`: scoring, category analytics, and optional remote history persistence.

## Persistence

- `FileDbService` stores the last loaded test definition.
- `SqliteService` stores resumable session snapshots and response history.
- A session snapshot includes the concrete question order, current index, answers,
  flags, elapsed time, per-question timing, mode, and status.

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
