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
- **Version**: 1.4.19 (Build 19)
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

## 📋 Production Release Status:

1. **✅ COMPLETED**: Update version name to "1.4.19"
2. **✅ COMPLETED**: Add proper ProGuard rules
3. **✅ COMPLETED**: Configure release signing
4. **✅ COMPLETED**: Add network security config
5. **✅ COMPLETED**: Add data extraction rules
6. **✅ COMPLETED**: Update app label to "Production.Inc"
7. **✅ COMPLETED**: Create production keystore (`production-inc-keystore.jks`)
8. **✅ COMPLETED**: Test release builds (v1.4.8+)
9. **✅ COMPLETED**: Production app icon with adaptive design
10. **🎯 READY**: Upload to Google Play Console (production-ready)

## ⚠️ Important Notes:

- Keep `key.properties` file secure and never commit to version control
- All release builds tested and verified working on multiple devices
- Android optimizations complete for production deployment
- Database migration system ensures safe updates for existing users
- Portrait-only orientation enforced for optimal mobile experience
