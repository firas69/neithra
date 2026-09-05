# Recruiter Review Guide

This guide is a quick path through the project for technical reviewers.

## What This Project Demonstrates

- Flutter UI implementation for a real app workflow rather than a static demo.
- Provider-based state management with clear model boundaries.
- Local-first persistence with SQLite for profile, library, sessions, and immutable history.
- Four-tab app shell with route isolation for the active test-taking screen.
- First-run onboarding, editable username, activity streak, and polished empty states.
- Extensible question and answer contracts instead of page-specific hardcoding.
- Release-minded Android setup with ignored signing secrets and lower-memory Gradle config.
- Test coverage around the core parser and scoring contracts.

## Suggested Review Path

1. Read `README.md` for product context and run instructions.
2. Inspect `lib/models/question_model.dart` and `lib/models/answer_value_model.dart`.
3. Inspect `lib/views/app_shell.dart` for the bottom-navigation structure.
4. Inspect `lib/providers/test_library_provider.dart` and
   `lib/providers/history_provider.dart`.
5. Inspect `lib/providers/session_provider.dart` for pause/resume session state.
6. Inspect `lib/services/database/sqlite_service.dart` for durable local persistence.
7. Inspect `lib/widgets/answer_input_widget.dart` for compositional question rendering.
8. Run:

```sh
flutter analyze
flutter test
```

## Core User Flow

1. Create a local username on first launch.
2. Import a JSON test into the persistent library.
3. Search or open a test card and choose Practice or Exam mode.
4. Answer questions in a focused test interface.
5. Pause and resume from the Home dashboard.
6. Complete the session.
7. Review score, explanations, weak categories, and immutable history detail.
8. Check Profile for activity streak and activity totals.

## Notable Tradeoffs

- The app is local-first. The remote history service is intentionally optional and disabled
  unless `NEITHRA_HISTORY_API` is supplied at build time.
- Imported tests use generated stable IDs. Display names can change without invalidating
  completed history.
- Code and open-ended answers use rubric/self-evaluation scoring. A production-grade learning
  platform could later add server-side grading or LLM-assisted review.
- The JSON schema is flexible by design so generated tests can evolve without rewriting UI
  screens.

## Files Worth Opening First

- `lib/views/app_shell.dart`
- `lib/views/home_dashboard_screen.dart`
- `lib/views/tests_screen.dart`
- `lib/views/history_screen.dart`
- `lib/views/practice_screen.dart`
- `lib/views/results_screen.dart`
- `lib/models/question_model.dart`
- `lib/models/test_model.dart`
- `lib/models/imported_test_model.dart`
- `lib/models/test_attempt_model.dart`
- `lib/providers/session_provider.dart`
- `lib/providers/history_provider.dart`
- `lib/services/json_parser_service.dart`
- `test/widget_test.dart`
