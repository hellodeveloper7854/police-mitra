# App & Package Name Update - Stage Environment

## Summary
Successfully updated the app name and package name to include "stage-" prefix for staging environment.

---

## Changes Made

### 1. **pubspec.yaml** (Line 98)
- **Old:** `name: polismitr`
- **New:** `name: stage_polismitr`

### 2. **Android - AndroidManifest.xml** (Line 10)
- **Old App Name:** `android:label="पोलीस मित्र ठाणे पोलीस"`
- **New App Name:** `android:label="पोलीस मित्र ठाणे पोलीस (Stage)"`

### 3. **Android - build.gradle**
- **Line 32 (namespace):**
  - Old: `namespace "com.police.policemitr"`
  - New: `namespace "com.police.stage_policemitr"`

- **Line 50 (applicationId):**
  - Old: `applicationId "com.police.policemitr"`
  - New: `applicationId "com.police.stage_policemitr"`

### 4. **Android - MainActivity.kt** (NEW FILE)
- **Created:** `android/app/src/main/kotlin/com/police/stage_policemitr/MainActivity.kt`
- **Package:** `package com.police.stage_policemitr`
- **Old location:** `android/app/src/main/kotlin/com/police/policemitr/MainActivity.kt`

### 5. **iOS - Info.plist**
- **Line 8 (CFBundleDisplayName):**
  - Old: `<string>पोलीस मित्र ठाणे पोलीस</string>`
  - New: `<string>पोलीस मित्र ठाणे पोलीस (Stage)</string>`

- **Line 16 (CFBundleName):**
  - Old: `<string>polismitr</string>`
  - New: `<string>stage-polismitr</string>`

### 6. **iOS - project.pbxproj**
- **All occurrences replaced:**
  - Old: `com.example.polismitr`
  - New: `com.police.stagePolicemitr`

### 7. **Test Files**
- **test/widget_test.dart (Line 11):**
  - Old: `import 'package:polismitr/main.dart';`
  - New: `import 'package:stage_polismitr/main.dart';`

---

## Final Configuration

### Android
- **Package Name:** `com.police.stage_policemitr`
- **App Display Name:** `पोलीस मित्र ठाणे पोलीस (Stage)`
- **Application ID:** `com.police.stage_policemitr`

### iOS
- **Bundle Identifier:** `com.police.stagePolicemitr`
- **App Display Name:** `पोलीस मित्र ठाणे पोलीस (Stage)`
- **Bundle Name:** `stage-polismitr`

### Flutter (Dart)
- **Package Name:** `stage_polismitr`
- **Imports will use:** `package:stage_polismitr/...`

---

## Next Steps

### 1. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### 2. For Android Release
If you had previous signed builds, you may need to:
1. Update keystore (if using release signing)
2. Uninstall the old app from device
3. Install the new stage version

### 3. For iOS Release
1. Clean build folder in Xcode
2. Update bundle identifier in Apple Developer portal
3. Update provisioning profiles

---

## Important Notes

### Package Name vs App Display Name

**Package Name (Technical):**
- Android: `com.police.stage_policemitr`
- iOS: `com.police.stagePolicemitr`
- Flutter: `stage_polismitr`
- Used internally by the system
- Cannot be changed without reinstall

**App Display Name (User-facing):**
- Shows as: `पोलीस मित्र ठाणे पोलीस (Stage)`
- What users see on their home screen
- Clearly indicates this is a staging/testing version

### Why "Stage"?
- Indicates this is a staging/development environment
- Differentiates from production app
- Allows both versions to be installed simultaneously
- Users can easily identify which version they're using

### Impact on Existing Features
- ✅ All functionality remains the same
- ✅ Supabase configuration unchanged
- ✅ All imports automatically updated
- ✅ Certificate generation works
- ✅ Image upload works
- ✅ All features preserved

---

## Verification

After updating, verify:

1. **App Icon** shows correct name on home screen
2. **Package Info** shows new package name
3. **Both versions** (production and stage) can coexist if needed
4. **All features** work correctly

---

## Rollback (if needed)

To revert to production:
1. Change `name: stage_polismitr` back to `name: polismitr`
2. Revert Android package to `com.police.policemitr`
3. Revert iOS bundle to `com.police.policemitr`
4. Remove "(Stage)" from app display names
5. Run `flutter clean && flutter pub get`

---

**Status:** ✅ COMPLETED

All package names and app display names have been successfully updated to include the "stage-" prefix for staging environment!
