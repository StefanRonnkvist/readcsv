# Release Notes - 2026-05-24

## Project

- Name: Read CSV
- Version: 0.1.0+1
- Build date: 2026-05-24

## Build Summary

All release targets completed successfully:

- Android APK
- Android App Bundle (AAB)
- Web
- Windows EXE
- Windows MSIX

## Artifacts

| Artifact | Path | Size (bytes) | Last Write Time |
|---|---|---:|---|
| APK | build/app/outputs/flutter-apk/app-release.apk | 51441399 | 2026-05-24 15:53:14 |
| AAB | build/app/outputs/bundle/release/app-release.aab | 50558092 | 2026-05-24 15:53:19 |
| Web Entry | build/web/index.html | 1528 | 2026-05-24 15:53:43 |
| Windows EXE | build/windows/x64/runner/Release/readcsv.exe | 309248 | 2026-05-24 15:55:43 |
| Windows MSIX | build/windows/x64/runner/Release/Read CSV.msix | 13572509 | 2026-05-24 15:56:44 |

## SHA-256 Checksums

- app-release.apk: `22321F727CFAA34477F3C359DB5589BDE02A40D57983C2485F2F028FCB6DC03B`
- app-release.aab: `00409A309E8A0C86B60C2398B5D1F4B8372FAA4475F622BDC324B28E6BE57D62`
- readcsv.exe: `E937C9D32116213A27ED1B579617690A9A98A13720A3BCEDCC005CC240C27DE7`
- Read CSV.msix: `7D09967FFB3ADC04AF7F3C168730EDC60D76FB8E709BE39D3F067A5D76CE43BD`

## Notes

- During MSIX packaging, certificate installation was prompted and skipped (`N`), but the MSIX package was still created successfully.
- Flutter displayed a non-blocking warning that `file_picker` uses Kotlin Gradle Plugin integration that may require migration in future Flutter versions.
