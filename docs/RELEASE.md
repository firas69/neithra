# Release Notes

This project can build Android debug and release APKs. Build artifacts and signing
secrets are intentionally ignored by Git.

## Prerequisites

- Flutter 3.35.x or newer
- Dart 3.9.x
- Android SDK with build tools
- JDK 17

## Android Package

- Application ID: `com.neithra.practice`
- App label: `Neithra`

## Local Signing Setup

Create `android/key.properties` locally:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=neithra
storeFile=neithra-release.keystore
```

Create a local keystore:

```sh
keytool -genkeypair \
  -v \
  -keystore android/app/neithra-release.keystore \
  -storetype PKCS12 \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias neithra
```

Both `android/key.properties` and `*.keystore` files are ignored.

## Build Commands

```sh
flutter analyze
flutter test
flutter build apk --release
```

If your editor crashes while building, run the same commands from a terminal instead of
inside VS Code. The local Gradle settings already cap memory and worker count to reduce
pressure during release builds.

With optional remote history:

```sh
flutter build apk --release \
  --dart-define=NEITHRA_HISTORY_API=https://your-api.example.com/api
```

## Lower-Memory Builds

The project limits Gradle memory and workers in `android/gradle.properties` to make local
builds friendlier on development machines and avoid editor crashes during APK generation.
