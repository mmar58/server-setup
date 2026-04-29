# Flutter Terminal Commands

A reference guide for common Flutter tasks via terminal.

---

## Check Flutter Setup

```bash
# Verify Flutter installation and environment
flutter doctor

# Verbose output for detailed diagnostics
flutter doctor -v
```

---

## Manage Devices

```bash
# List all connected/available devices (physical & emulators)
flutter devices

# List available emulators (not yet running)
flutter emulators

# Launch a specific emulator by ID
flutter emulators --launch <emulator_id>

# Example
flutter emulators --launch Pixel_6_API_34
```

---

## Run the App

```bash
# Run on the only connected device (or prompts if multiple)
flutter run

# Run on a specific device by device ID
flutter run -d <device_id>

# Examples
flutter run -d emulator-5554        # Android emulator
flutter run -d "Pixel 6"            # Physical Android by name
flutter run -d chrome               # Web (Chrome)
flutter run -d linux                # Desktop (Linux)

# Run in release mode
flutter run --release

# Run in profile mode (for performance profiling)
flutter run --profile

# Run with a specific flavor
flutter run --flavor production
```

---

## Build the App

### Android

```bash
# Build APK (debug)
flutter build apk

# Build APK (release)
flutter build apk --release

# Build APK split by ABI (smaller file sizes)
flutter build apk --split-per-abi

# Build App Bundle (recommended for Play Store)
flutter build appbundle

# Build App Bundle (release)
flutter build appbundle --release

# Build with a specific flavor
flutter build apk --release --flavor production
```

### iOS

```bash
# Build iOS (release) — requires macOS
flutter build ios --release

# Build IPA for distribution
flutter build ipa
```

### Web

```bash
flutter build web

# With a specific base href
flutter build web --base-href /myapp/
```

### Desktop

```bash
flutter build linux
flutter build windows
flutter build macos
```

---

## Hot Reload & Hot Restart

While `flutter run` is active in terminal:

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | Quit |
| `d` | Detach (leave app running) |
| `p` | Toggle widget inspector overlay |
| `o` | Toggle platform (Android/iOS) |

---

## Package Management

```bash
# Get/install dependencies from pubspec.yaml
flutter pub get

# Upgrade all dependencies to latest allowed versions
flutter pub upgrade

# Add a package
flutter pub add <package_name>

# Remove a package
flutter pub remove <package_name>

# Check for outdated packages
flutter pub outdated
```

---

## Clean & Rebuild

```bash
# Delete build/ and .dart_tool/ directories
flutter clean

# After cleaning, re-fetch dependencies
flutter pub get
```

---

## Testing

```bash
# Run all unit/widget tests
flutter test

# Run a specific test file
flutter test test/my_widget_test.dart

# Run integration tests on a device
flutter test integration_test/app_test.dart -d <device_id>

# Run tests with coverage
flutter test --coverage
```

---

## Code Generation & Analysis

```bash
# Analyze code for errors and warnings
flutter analyze

# Format all Dart files
dart format .

# Fix auto-fixable lint issues
dart fix --apply

# Run build_runner (code generation, e.g. json_serializable, freezed)
dart run build_runner build

# Watch mode for code generation
dart run build_runner watch

# Clean and rebuild generated files
dart run build_runner build --delete-conflicting-outputs
```

---

## Flutter Version Management

```bash
# Check current Flutter version
flutter --version

# List available Flutter channels
flutter channel

# Switch channel (stable / beta / master)
flutter channel stable

# Upgrade Flutter to latest on current channel
flutter upgrade
```

---

## Useful Tips

- Run `flutter devices` before `flutter run` to get the exact device ID when multiple devices are connected.
- Use `flutter build apk --split-per-abi` for Play Store uploads to reduce APK size.
- Always run `flutter clean` followed by `flutter pub get` when facing unexpected build errors.
- Use `flutter pub outdated` regularly to keep dependencies up to date.
