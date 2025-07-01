# Android Configuration - Production.Inc

## 🔧 Setup Requirements

### For Development Builds:
- No additional setup required
- Uses debug signing automatically

### For Release/Production Builds:
1. **Create Keystore** (one-time setup):
   ```bash
   keytool -genkey -v -keystore production-inc-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias prodinckey
   ```

2. **Configure Signing**:
   - Copy `key.properties.template` to `key.properties`
   - Fill in your keystore details in `key.properties`
   - Keep `key.properties` secure and DO NOT commit to version control

3. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```

## 📱 Current Configuration

### App Details:
- **Package Name**: `com.production.inc`
- **App Name**: Production.Inc
- **Version**: 1.3.3 (Build 1)
- **Min SDK**: Android 7.0 (API 24)
- **Target SDK**: Android 15 (API 35)

### Features Enabled:
- ✅ Hardware acceleration
- ✅ Large heap for game performance
- ✅ Landscape orientation optimized
- ✅ ProGuard/R8 optimization for release
- ✅ Resource shrinking
- ✅ Network security configuration
- ✅ Modern data extraction rules

### Permissions:
- `INTERNET` - For future online features
- `VIBRATE` - Haptic feedback
- `WAKE_LOCK` - Keep screen on during gameplay

## 🚀 Build Variants

### Debug Build:
- Package: `com.production.inc.debug`
- Debuggable, larger APK size
- Uses debug signing

### Release Build:
- Package: `com.production.inc`
- Optimized, smaller APK size
- Requires proper signing configuration

## 📋 TODO for Production Release:

1. **✅ COMPLETED**: Update version name from "P1.0.0" to "1.3.3"
2. **✅ COMPLETED**: Add proper ProGuard rules
3. **✅ COMPLETED**: Configure release signing
4. **✅ COMPLETED**: Add network security config
5. **✅ COMPLETED**: Add data extraction rules
6. **✅ COMPLETED**: Update app label from "Game1" to "Production.Inc"
7. **🎯 NEXT**: Create production keystore
8. **🎯 NEXT**: Test release build
9. **🎯 NEXT**: Upload to Google Play Console (when ready)

## ⚠️ Important Notes:

- Keep `key.properties` file secure and never commit to version control
- Test release builds thoroughly before publishing
- Current build uses debug signing for development ease
- All Android optimizations are in place for production release
