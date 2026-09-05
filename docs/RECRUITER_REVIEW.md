# Recruiter Review Guide

This guide is a quick path through the project for technical reviewers.

## What This Project Demonstrates

- Flutter UI implementation for a real app workflow rather than a static demo.
- Provider-based state management with clear model boundaries.
- Local-first persistence using both file storage and SQLite.
- Extensible question and answer contracts instead of page-specific hardcoding.
- Release-minded Android setup with ignored signing secrets and lower-memory Gradle config.
- Test coverage around the core parser and scoring contracts.

## Suggested Review Path

1. Read `README.md` for product context and run instructions.
2. Inspect `lib/models/question_model.dart` and `lib/models/answer_value_model.dart`.
3. Inspect `lib/providers/session_provider.dart` for pause/resume session state.
4. Inspect `lib/services/database/sqlite_service.dart` for durable snapshot persistence.
5. Inspect `lib/widgets/answer_input_widget.dart` for compositional question rendering.
6. Run:

```sh
flutter analyze
flutter test
```

## Core User Flow

1. Load or paste a JSON test definition.
2. Choose Practice or Exam mode.
3. Answer questions in a focused test interface.
4. Pause and resume from the in-progress session list.
5. Complete the session.
6. Review score, explanations, and weak categories.
7. Start weakness practice from the results screen.

## Notable Tradeoffs

- The app is local-first. The remote history service is intentionally optional and disabled
  unless `NEITHRA_HISTORY_API` is supplied at build time.
- Code and open-ended answers use rubric/self-evaluation scoring. A production-grade learning
  platform could later add server-side grading or LLM-assisted review.
- The JSON schema is flexible by design so generated tests can evolve without rewriting UI
  screens.

## Files Worth Opening First

- `lib/views/upload_screen.dart`
- `lib/views/practice_screen.dart`
- `lib/views/results_screen.dart`
- `lib/models/question_model.dart`
- `lib/models/test_model.dart`
- `lib/providers/session_provider.dart`
- `lib/services/json_parser_service.dart`
- `test/widget_test.dart`
