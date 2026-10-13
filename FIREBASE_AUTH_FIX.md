# Firebase Authentication reCAPTCHA Network Error Fix

## Problem

```
E/RecaptchaCallWrapper: Initial task failed for action RecaptchaAction(action=signInWithPassword)
with exception - A network error (such as timeout, interrupted connection or unreachable host) has occurred.
```

## Solutions Applied

### 1. ✅ Increased Minimum SDK Version

**File:** `android/app/build.gradle.kts`

- Changed `minSdk` from `flutter.minSdkVersion` (default 21) to **23**
- This ensures better compatibility with Firebase Authentication and reCAPTCHA

### 2. ✅ Enabled Cleartext Traffic

**File:** `android/app/src/main/AndroidManifest.xml`

- Added `android:usesCleartextTraffic="true"` to `<application>` tag
- Allows HTTP traffic in development (needed for Firebase Auth on emulators)

## Additional Troubleshooting Steps

### If Error Persists:

#### Option 1: Clean and Rebuild

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

#### Option 2: Use a Real Device

- Emulators sometimes have network restrictions
- Test on a physical Android device for better Firebase Auth support

#### Option 3: Restart ADB and Emulator

```bash
adb kill-server
adb start-server
```

Then restart your Android emulator.

#### Option 4: Check Internet Connection

- Ensure your emulator has internet access
- In Android emulator settings: Extended Controls → Settings → Proxy
- Set to "No proxy" or configure properly

#### Option 5: Enable MultiDex (for older devices/emulators)

If using minSdk < 21 or having build issues, add to `android/app/build.gradle.kts`:

```kotlin
android {
    defaultConfig {
        multiDexEnabled = true
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
```

#### Option 6: Verify Google Services Configuration

Make sure `google-services.json` is properly configured:

- Located at: `android/app/google-services.json`
- SHA-1 fingerprint registered in Firebase Console
- Android package name matches `applicationId` in build.gradle.kts

### Get SHA-1 Fingerprint (if needed)

```bash
cd android
./gradlew signingReport
```

Copy the SHA-1 key and add it to Firebase Console:

1. Go to Firebase Console → Project Settings
2. Add fingerprint under "Your apps" → Android app

## Testing After Fix

1. Stop the current app
2. Run: `flutter clean && flutter pub get`
3. Restart the app: `flutter run`
4. Try logging in again

## Production Considerations

⚠️ **Important:** Before releasing to production:

1. **Remove cleartext traffic** or restrict it:

   ```xml
   android:usesCleartextTraffic="false"
   ```

2. **Add network security config** for specific domains only:
   Create `android/app/src/main/res/xml/network_security_config.xml`:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <network-security-config>
       <base-config cleartextTrafficPermitted="false" />
   </network-security-config>
   ```

3. **Enable App Check** in Firebase Console for enhanced security

## Common Causes of This Error

1. ❌ Emulator network issues
2. ❌ Insufficient SDK version (< 23)
3. ❌ Missing internet permissions (already added in your app)
4. ❌ Firewall/proxy blocking reCAPTCHA
5. ❌ Invalid google-services.json configuration
6. ❌ Missing SHA-1 fingerprint in Firebase Console

## Verification

After applying fixes, you should see successful login without reCAPTCHA errors. Check logcat for:

```
✅ I/flutter: Login successful
✅ No RecaptchaCallWrapper errors
```
