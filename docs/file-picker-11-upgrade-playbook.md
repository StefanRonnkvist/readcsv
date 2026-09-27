# file_picker 11 Upgrade Playbook

This project currently builds release APK reliably with file_picker 10.3.10.
Use this playbook to retry file_picker 11 on an isolated branch.

## Goal

Upgrade file_picker to 11.x and keep Android release build green.

## 1. Start from a clean stable state

Run from repo root:

```powershell
git status
flutter pub get
flutter build apk --release
```

Expected: release build succeeds before starting migration.

## 2. Create an isolated branch

```powershell
git switch -c chore/file-picker-11-migration
```

## 3. Upgrade dependency and API call

```powershell
flutter pub upgrade --major-versions
```

Then verify the picker API call in main.dart uses:

```dart
await FilePicker.pickFiles(...)
```

(not FilePicker.platform.pickFiles)

## 4. Apply Built-in Kotlin migration for AGP 9+

In android/gradle.properties:

- android.newDsl=true
- android.builtInKotlin=true

In Android Gradle files, follow the Flutter migration guide and ensure old Kotlin plugin application patterns are removed where required.

Reference guide:
https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin

## 5. Regenerate and validate

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

If build fails on plugin Kotlin compatibility, check whether dependent plugins are built-in Kotlin ready.

## 6. Decide outcome

If successful:

```powershell
git add -A
git commit -m "Migrate to file_picker 11 with built-in Kotlin"
```

If not successful, return to stable:

```powershell
git switch -
git branch -D chore/file-picker-11-migration
```

Only delete the branch if all needed changes are safely retained elsewhere.
