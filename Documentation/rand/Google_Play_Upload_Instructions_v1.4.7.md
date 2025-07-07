# Google Play Console Upload Instructions - v1.4.7

## 📋 Files to Upload

### 1. App Bundle (Main Upload)
- **File:** `build\app\outputs\bundle\release\app-release.aab`
- **Size:** 21.0 MB
- **Upload Location:** Google Play Console → App Bundles and APKs → Upload

### 2. Debug Symbols (Required for Crash Analysis)
- **Location:** `build\app\outputs\symbols\`
- **Files to Upload:**
  - `app.android-arm.symbols`
  - `app.android-arm64.symbols`
  - `app.android-x64.symbols`
- **Upload Location:** Google Play Console → App Bundle Explorer → Downloads tab → Native debug symbols

### 3. Deobfuscation Mapping File
- **File:** `build\app\outputs\mapping\release\mapping.txt`
- **Upload Location:** Google Play Console → App Bundle Explorer → Downloads tab → Deobfuscation files

## 🔄 Upload Process

### Step 1: Upload App Bundle
1. Go to Google Play Console
2. Select your app
3. Navigate to "App Bundles and APKs"
4. Click "Upload" and select `app-release.aab`
5. Wait for upload and processing to complete

### Step 2: Upload Debug Symbols
1. After app bundle is processed, go to "App Bundle Explorer"
2. Click on the "Downloads" tab
3. In the "Native debug symbols" section, click "Upload"
4. Upload all three symbol files:
   - `app.android-arm.symbols`
   - `app.android-arm64.symbols`
   - `app.android-x64.symbols`

### Step 3: Upload Deobfuscation File
1. In the same "Downloads" tab
2. In the "Deobfuscation files" section, click "Upload"
3. Upload `mapping.txt`

### Step 4: Complete Release
1. Review all uploaded files
2. Update release notes with v1.4.7 changes
3. Set rollout percentage (recommend starting with 20%)
4. Submit for review

## ⚠️ Important Notes

- **Debug symbols are required** to resolve the warning about native code
- **Mapping file is essential** for crash analysis with obfuscated code
- **All files must be uploaded together** for the same version code (7)
- **Verify version code 7** appears correctly in the console

## 🎯 Expected Results

After successful upload:
- ✅ No warnings about missing debug symbols
- ✅ Crash reports will be properly deobfuscated
- ✅ Smaller download sizes for users (21.0 MB vs 46.3 MB APK)
- ✅ Automatic optimization for different devices

## 📱 Version Information
- **Version Code:** 7
- **Version Name:** 1.4.7
- **Release:** Enhanced Mobile Experience Update
- **Build Date:** July 6, 2025
