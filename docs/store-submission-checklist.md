# Store Submission Checklist

## Current Release Values

- App name: Read CSV
- Version: 0.1.0+1
- Release date: 2026-05-24

### Artifact Hashes (SHA-256)

- APK (`build/app/outputs/flutter-apk/app-release.apk`):
	`22321F727CFAA34477F3C359DB5589BDE02A40D57983C2485F2F028FCB6DC03B`
- AAB (`build/app/outputs/bundle/release/app-release.aab`):
	`00409A309E8A0C86B60C2398B5D1F4B8372FAA4475F622BDC324B28E6BE57D62`
- Windows EXE (`build/windows/x64/runner/Release/readcsv.exe`):
	`E937C9D32116213A27ED1B579617690A9A98A13720A3BCEDCC005CC240C27DE7`
- Windows MSIX (`build/windows/x64/runner/Release/Read CSV.msix`):
	`7D09967FFB3ADC04AF7F3C168730EDC60D76FB8E709BE39D3F067A5D76CE43BD`

## Pre-Submission

- [ ] Confirm app version and build number are correct in pubspec.yaml (`0.1.0+1`).
- [ ] Run release builds for all target stores.
- [ ] Verify checksums for uploaded binaries.
- [ ] Confirm release notes are prepared.
- [ ] Smoke test critical flows in release builds.

## Android Play Store

### Artifacts

- [ ] Use AAB: build/app/outputs/bundle/release/app-release.aab
- [ ] Keep APK (optional): build/app/outputs/flutter-apk/app-release.apk
- [ ] Verify AAB hash matches expected value in "Current Release Values".

### Play Console Setup

- [ ] Select correct app package/applicationId.
- [ ] Upload AAB to Internal testing first.
- [ ] Resolve any Play Console warnings/errors.
- [ ] Provide release notes/changelog text.
- [ ] Confirm target API/compliance prompts are completed.

### Validation

- [ ] Install from Internal testing track.
- [ ] Validate startup, CSV import, and persistence.
- [ ] Confirm no release-only crashes.

## Microsoft Store (MSIX)

### Artifact

- [ ] Use MSIX: build/windows/x64/runner/Release/Read CSV.msix
- [ ] Optional EXE reference: build/windows/x64/runner/Release/readcsv.exe
- [ ] Verify MSIX hash matches expected value in "Current Release Values".

### Submission Setup

- [ ] Confirm Publisher/Identity in msix config matches Partner Center app.
- [ ] Confirm version increment is greater than previous submission.
- [ ] Upload MSIX to a draft submission first.
- [ ] Fill out store listing metadata/screenshots as required.

### Validation

- [ ] Install submitted package on a clean Windows machine or VM.
- [ ] Verify app launch, permissions, and update behavior.
- [ ] Verify uninstall/reinstall behavior.

## Security and Integrity

- [ ] Keep SHA-256 checksums with release records.
- [ ] Compare uploaded artifact hashes against the values in this file.
- [ ] Archive built artifacts and release notes for rollback.
- [ ] Store signing credentials securely.

## Sign-Off

- [ ] Product/QA sign-off complete.
- [ ] Submission approved and published.
- [ ] Post-release sanity checks complete.
