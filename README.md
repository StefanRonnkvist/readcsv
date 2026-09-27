# Read CSV

Read CSV is a Flutter app for importing, inspecting, filtering, and converting
tabular data in a responsive workspace.

## Features

- Imports local CSV, TSV, and TXT files on Android and Windows.
- Detects comma, semicolon, tab, and pipe delimiters automatically.
- Normalizes blank and duplicate headers and skips empty data rows.
- Keeps each imported dataset in a separate, persistent tab.
- Filters by an exact column value and searches text across every column.
- Displays rows in a horizontally and vertically scrollable table.
- Generates complete JSON and XML previews that can be copied to the
	clipboard.
- Renames and permanently deletes stored datasets.
- Provides System, Dark, and Light themes with a remembered preference.
- Adapts the workspace for phone, tablet, and desktop widths.

## Using the App

1. Open **Upload New Document** and choose a `.csv`, `.tsv`, or `.txt` file.
2. Open the new dataset tab to inspect its rows and columns.
3. Select a column and value for exact filtering, or use text search for a
	 case-insensitive match across all columns.
4. Select **Export JSON** or **Export XML** to preview the generated text and
	 copy it to the clipboard.
5. Use **Rename** to organize dataset tabs or **Delete** to remove a dataset
	 and all of its rows.

The first record in an imported file is treated as the header row. If the app
has no saved datasets, it opens Help on startup; otherwise it opens Upload New
Document.

## Data and Network Use

Imported datasets and rows are stored locally using Sembast and remain
available after the app restarts. Importing, browsing, filtering, and
generating exports do not send dataset contents to the contact server.

The **Information** tab contains the app's network features:

- **Form** sends the entered name, return email, question, and basic app/device
	diagnostics to the configured contact endpoint.
- **Server Data** downloads the remote submissions CSV and displays records
	associated with the current app package.

The selected Information sub-tab and theme preference are stored locally.

## Platform Behavior

Local file import is currently enabled on Android and Windows. Other platform
builds show an unsupported-platform message when import is requested. Web
builds also display a notice that database data is temporary for the browser
session.

## Development

Prerequisites:

- Flutter with a Dart SDK compatible with `^3.12.0`
- Android or Windows tooling for the corresponding local target

Restore dependencies and run the app:

```powershell
flutter pub get
flutter run
```

Run static analysis:

```powershell
flutter analyze
```

## Release Builds

Build a target using the version in `pubspec.yaml`:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build-release.ps1 -Target apk
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build-release.ps1 -Target appbundle
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build-release.ps1 -Target msix
```

For an Android APK build that first clears common locked generated paths and
restores packages:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build-apk-release.ps1
```

## Troubleshooting

If `flutter pub get` fails with an error about deleting
`ios/Flutter/ephemeral/Packages/.packages` or
`macos/Flutter/ephemeral/Packages/.packages`, run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/cleanup-ephemerals.ps1 -RunPubGet
```

You can also run the VS Code task `Flutter: Fix Apple Ephemeral Packages`.
