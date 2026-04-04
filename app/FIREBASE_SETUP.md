# Firebase Setup Guide - SHA-1 Certificate Fingerprints

## Required for Google Sign-In and Firebase Authentication

### Quick Setup

#### 1. Get Debug Certificate SHA-1

**Windows:**
```cmd
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore
```
Password: `android`

**Mac/Linux:**
```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
```
Password: `android`

#### 2. Get Release Certificate SHA-1

If using **Play App Signing** (recommended):
- Go to [Google Play Console](https://play.google.com/console)
- Release > Setup > App Integrity
- Copy SHA-1 from "App signing key certificate"

If **self-signing**:
```bash
keytool -list -v -alias <your-key-name> -keystore <path-to-keystore>
```

#### 3. Add to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `neospartan-36e73`
3. Project Settings (gear icon) > General
4. Under "Your apps", select your Android app
5. Click "Add fingerprint"
6. Paste your SHA-1
7. Add both debug and release SHA-1s

### Alternative: Use Gradle Signing Report

```bash
cd android
./gradlew signingReport
```

This shows all signing certificates including SHA-1.

### Verification

After adding SHA-1 to Firebase:
1. Download updated `google-services.json`
2. Replace file in `android/app/`
3. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

### Troubleshooting

**Error: "SHA-1 fingerprint not found"**
- Ensure SHA-1 is added to correct Firebase project
- Check package name matches exactly
- Verify both debug and release keys are added

**Error: "API key not valid"**
- Regenerate google-services.json after adding SHA-1
- Ensure file is in correct location: `android/app/google-services.json`

### Security Note

Never commit release keystore or passwords to version control. Add to `.gitignore`:
```
*.jks
*.keystore
key.properties
```
