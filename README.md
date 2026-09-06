# Neithra

Neithra is a Flutter learning and assessment app for structured exam sessions.
It turns JSON-based exam definitions into a focused workflow:

`Create profile -> Create family -> Import exams -> Start exam -> Pause -> Resume -> Submit -> Review history`

The project is intentionally local-first. Exams, in-progress sessions, profile data, and
attempt history are persisted on device with SQLite, while the optional remote history
service is disabled unless a backend URL is provided at build time.

## Highlights

- Focused exam sessions with responsive phone/tablet layouts.
- First-launch username setup with an editable local profile.
- Persistent bottom navigation for Home, Exams, History, and Profile.
- Family-based exam library with stable IDs, friendly display names, search, rename,
  move-to-family actions, and SHA-256 duplicate protection based on canonical exam content.
- Durable pause/resume sessions that survive app restarts.
- Immutable completed-attempt history with question-by-question snapshots.
- Historical family snapshots on completed attempts so moves/renames do not corrupt history.
- Activity streak based on local calendar days with completed exams.
- Global, family, and exam-level statistics derived from persisted attempts.
- Rich question model with scoring, metadata, explanations, hints, skills, categories,
  estimated time, points, and optional negative marking.
- Extensible answer rendering for single choice, multiple answer, true/false, short answer,
  fill in the blank, matching, ordering, numerical, scenario, code, and self-evaluated
  questions.
- Review screen with score, points, manual-review count, category performance, and
  persisted history review.
- Clean Provider-based state management with local file and SQLite persistence.

## Screens

Current main surfaces:

- `AppShell`: persistent bottom navigation using an `IndexedStack`.
- `HomeDashboardScreen`: greeting, quick import, recent exams, and resume card.
- `ExamsScreen`: family cards, search, create/rename/delete family, and import actions.
- `FamilyDetailScreen`: family statistics, scoped exam search, imports, and exam cards.
- `HistoryScreen`: completed attempts, newest first.
- `ProfileScreen`: username editing, activity streak, and activity summary.
- `ExamScreen`: focused answering UI, question map, elapsed time, flags, pause/save.
- `ResultsScreen`: review answers, explanations, scoring details, weakest categories.

## Project Structure

```text
lib/
  core/                 Theme, constants, small utilities
  models/               Profile, family, imported exam, exam definition, question, answer, session, attempt
  providers/            Provider state for profile, library, sessions, results, history
  services/             JSON parsing, local file storage, SQLite, optional remote history
  views/                App shell, tabs, detail screens, active exam, results
  widgets/              Reusable exam-taking and answer-rendering widgets
docs/                   Architecture, schema, release, and reviewer notes
samples/                Example exam definitions
test/                   Parser, scoring, fingerprint, family stats, cursor, and answer-state tests
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
exam action on Home.

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
