# Recruiter Review Guide

This guide is a quick path through the project for technical reviewers.

## What This Project Demonstrates

- Flutter UI implementation for a real app workflow rather than a static demo.
- Provider-based state management with clear model boundaries.
- Local-first persistence with SQLite for profile, exam library, sessions, and immutable history.
- Four-tab app shell with route isolation for the active exam-taking screen.
- First-run onboarding, editable username, activity streak, and polished empty states.
- Exam-family hierarchy with safe migration to Uncategorized for legacy imported exams.
- Family-aware global/family/exam statistics derived from immutable attempts.
- Extensible question and answer contracts instead of page-specific hardcoding.
- Deterministic canonical exam fingerprints for duplicate import detection.
- Release-minded Android setup with ignored signing secrets and lower-memory Gradle config.
- Test coverage around the core parser, scoring, fingerprint, and answer-state contracts.

## Suggested Review Path

1. Read `README.md` for product context and run instructions.
2. Inspect `lib/models/question_model.dart` and `lib/models/answer_value_model.dart`.
3. Inspect `lib/services/exam_fingerprint_service.dart`.
4. Inspect `lib/services/exam_statistics_service.dart`.
5. Inspect `lib/views/app_shell.dart` for the bottom-navigation structure.
6. Inspect `lib/providers/test_library_provider.dart` and
   `lib/providers/history_provider.dart`.
7. Inspect `lib/providers/session_provider.dart` for pause/resume session state.
8. Inspect `lib/services/database/sqlite_service.dart` for durable local persistence.
9. Inspect `lib/widgets/answer_input_widget.dart` for compositional question rendering
   and cursor-safe controller lifecycle.
10. Run:

```sh
flutter analyze
flutter test
```

## Core User Flow

1. Create a local username on first launch.
2. Create or choose an exam family.
3. Import a JSON exam into that family.
4. Search families or open a family to see its exams.
5. Start an exam session from an exam card.
6. Pause and resume from the Home dashboard.
7. Submit the session.
8. Review score, explanations, family snapshot, and immutable history detail.
9. Check Profile for activity streak and global/family activity totals.

## Notable Tradeoffs

- The app is local-first. The remote history service is intentionally optional and disabled
  unless `NEITHRA_HISTORY_API` is supplied at build time.
- Imported exams use generated stable IDs. Display names can change without invalidating
  completed history.
- Family deletion moves exams to Uncategorized rather than deleting exam/history data.
- Attempt history snapshots family ID/name at submission time, so moving an exam later
  does not rewrite the historical context.
- Code and open-ended answers use rubric/self-evaluation scoring. A production-grade learning
  platform could later add server-side grading or LLM-assisted review.
- The JSON schema is flexible by design so generated exams can evolve without rewriting UI
  screens.

## Files Worth Opening First

- `lib/views/app_shell.dart`
- `lib/views/home_dashboard_screen.dart`
- `lib/views/exams_screen.dart`
- `lib/views/family_detail_screen.dart`
- `lib/views/history_screen.dart`
- `lib/views/exam_screen.dart`
- `lib/views/results_screen.dart`
- `lib/models/question_model.dart`
- `lib/models/test_model.dart`
- `lib/models/imported_test_model.dart`
- `lib/models/exam_family_model.dart`
- `lib/models/test_attempt_model.dart`
- `lib/providers/session_provider.dart`
- `lib/providers/history_provider.dart`
- `lib/services/json_parser_service.dart`
- `test/widget_test.dart`
