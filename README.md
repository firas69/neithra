# Neithra

Neithra is a Flutter learning and assessment app for structured practice sessions.
It turns JSON-based test definitions into a focused workflow:

`Create profile -> Import tests -> Practice -> Pause -> Resume -> Complete -> Review history`

The project is intentionally local-first. Tests and in-progress sessions are persisted on
device with SQLite, while the optional remote history service is disabled unless a backend
URL is provided at build time.

## Highlights

- Focused practice and exam modes with responsive phone/tablet layouts.
- First-launch username setup with an editable local profile.
- Persistent bottom navigation for Home, Tests, History, and Profile.
- Internal test library with stable test IDs, friendly display names, search, and rename.
- Durable pause/resume sessions that survive app restarts.
- Immutable completed-attempt history with question-by-question snapshots.
- Activity streak based on local calendar days with completed tests.
- Rich question model with scoring, metadata, explanations, hints, skills, categories,
  estimated time, points, and optional negative marking.
- Extensible answer rendering for single choice, multiple answer, true/false, short answer,
  fill in the blank, matching, ordering, numerical, scenario, code, and self-evaluated
  questions.
- Review screen with score, points, manual-review count, category performance, and weakness
  practice generation.
- Clean Provider-based state management with local file and SQLite persistence.

## Screens

Current main surfaces:

- `AppShell`: persistent bottom navigation using an `IndexedStack`.
- `HomeDashboardScreen`: greeting, quick import, recent tests, and resume card.
- `TestsScreen`: searchable imported test library with rename actions.
- `HistoryScreen`: completed attempts, newest first.
- `ProfileScreen`: username editing, activity streak, and activity summary.
- `PracticeScreen`: focused answering UI, question map, elapsed time, flags, pause/save.
- `ResultsScreen`: review answers, explanations, scoring details, weakest categories.

## Project Structure

```text
lib/
  core/                 Theme, constants, small utilities
  models/               Profile, imported test, test, question, answer, session, attempt
  providers/            Provider state for profile, library, sessions, results, history
  services/             JSON parsing, local file storage, SQLite, optional remote history
  views/                App shell, tabs, detail screens, active test, results
  widgets/              Reusable test-taking and answer-rendering widgets
docs/                   Architecture, schema, release, and reviewer notes
samples/                Example test definitions
test/                   Focused parser/scoring tests
```

See [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) for a reviewer-oriented map.

## Run Locally

Prerequisites:

- Flutter 3.35.x or newer
- Dart 3.9.x
- Android Studio or Android SDK for APK builds
- JDK 17 for Android builds

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Import `samples/symfony_learning_sprint.json` from the app, or use the built-in sample
action on Home.

## Build Android APK

Debug:

```sh
flutter build apk --debug
```

Release:

```sh
flutter build apk --release
```

The release signing file and keystore are intentionally ignored. See
[docs/RELEASE.md](docs/RELEASE.md) for the expected local signing setup.

## Optional Remote History API

Remote history saving is disabled by default. To enable it, build with:

```sh
flutter build apk --release --dart-define=NEITHRA_HISTORY_API=https://your-api.example.com/api
```

The app remains fully usable without a backend.

## Reviewer Guide

Start with [docs/RECRUITER_REVIEW.md](docs/RECRUITER_REVIEW.md) for the quickest technical
walkthrough and suggested review path.
