# Google Play Console Release Checklist - Production.INC

## ✅ Files Ready for Upload

### App Bundle (Recommended for Play Store)
- **File**: `build\app\outputs\bundle\release\app-release.aab` (24.6MB)
- **Version**: 1.4.6 (Build 6)
- **Signed**: ✅ Yes (production-inc-keystore.jks)

### APK (Alternative/Testing)
- **File**: `build\app\outputs\flutter-apk\app-release.apk` (49.1MB)
- **Version**: 1.4.6 (Build 6)
- **Signed**: ✅ Yes

## 🔑 App Information

### Basic Details
- **Application ID**: `com.production.inc`
- **App Name**: Production.INC - Business Simulation Game
- **Short Description**: Build your production empire! Buy materials, craft products, and sell for profit
- **Category**: Games > Simulation
- **Content Rating**: PEGI 3 / Everyone

### Technical Requirements
- **Minimum SDK**: Android 7.0 (API 24)
- **Target SDK**: Android 14 (API 35)
- **Permissions**: 
  - INTERNET (for future features)
  - WRITE_EXTERNAL_STORAGE (for save games)
  - READ_EXTERNAL_STORAGE (for save games)

## 📱 Store Listing Content

### App Title (50 characters max)
```
Production.INC - Business Simulation Game
```

### Short Description (80 characters max)
```
Build your production empire! Buy materials, craft products, and sell for profit
```

### Full Description
✅ Available in `Documentation\Store listing.txt`

### Screenshots Needed (Upload to Play Console)
- **Phone Screenshots**: 2-8 screenshots (minimum 2)
  - Recommend: Main menu, gameplay, product catalog, progression
- **Tablet Screenshots**: Optional but recommended
- **Feature Graphic**: 1024 x 500 pixels
- **App Icon**: 512 x 512 pixels (check `assets\images\AppIcon.png`)

## 🎯 Release Steps

### 1. Google Play Console Setup
1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app
3. Fill in app details:
   - App name: "Production.INC"
   - Default language: English (United States)
   - App category: Games > Simulation
   - Content rating: Everyone

### 2. Upload App Bundle
1. Go to "Production" > "Releases"
2. Create new release
3. Upload `app-release.aab`
4. Set version name: 1.4.6
5. Set version code: 6

### 3. Store Listing
1. Complete store listing with content from `Store listing.txt`
2. Upload screenshots and graphics
3. Set content rating
4. Add privacy policy URL (if required)

### 4. Content Rating
1. Complete content rating questionnaire
2. Expected rating: PEGI 3 / Everyone (business simulation game)

### 5. Pricing & Distribution
1. Set price: Free or Paid
2. Select countries for distribution
3. Confirm content guidelines compliance

### 6. Release Management
1. Choose release type:
   - **Internal Testing**: For team testing
   - **Closed Testing**: For beta testers
   - **Open Testing**: For public beta
   - **Production**: For public release
2. Set rollout percentage (recommend 5-10% initially)

## 📋 Pre-Launch Checklist

- ✅ App builds and runs without crashes
- ✅ App is properly signed with production keystore
- ✅ Version numbers are consistent across all files
- ✅ Store listing content is ready
- ✅ App icon and screenshots are prepared
- ✅ Content rating questionnaire can be completed
- ✅ Privacy policy prepared (if collecting user data)
- ✅ App complies with Google Play policies

## 🚀 Next Steps After Upload

1. **Review Process**: Google typically reviews apps within 3 days
2. **Testing**: Use internal testing track first
3. **Gradual Rollout**: Start with 5-10% of users
4. **Monitor**: Watch for crashes and user feedback
5. **Updates**: Prepare patches for any issues found

## 📞 Support Information

- **Developer Name**: Jabez Abella
- **Organization**: Studio 402
- **Contact Email**: [Your email for Play Console]
- **Support Website**: [Your support website if available]

## 🔒 Security Notes

- **Keystore File**: Keep `production-inc-keystore.jks` secure and backed up
- **Passwords**: Store keystore passwords securely
- **Key.properties**: Never commit to version control (already in .gitignore)

---
**Ready for Google Play Console Upload!** 🎉
