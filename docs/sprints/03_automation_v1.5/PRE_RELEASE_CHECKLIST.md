# Version 1.5.0 Pre-Release Checklist
**Production.INC - Beta Release to Google Play Console**

---

## ✅ CODE & BUILD

### Version Updates
- [ ] Update `pubspec.yaml` version: `1.4.14+14` → `1.5.0+15`
- [ ] Update `README.md` current version reference
- [ ] Update `CHANGELOG.md` with v1.5.0 entry
- [ ] Verify version number in app title/splash (if applicable)

### Code Quality
- [x] All critical bugs fixed
- [x] No compilation errors
- [x] Flutter analyze passes (0 issues)
- [x] All tests passing
- [ ] Remove debug logging from production code
- [ ] Remove or hide developer controls (optional)

### Build Configuration
- [ ] Verify `android/app/build.gradle.kts` version code/name
- [ ] Confirm ProGuard/R8 enabled for release
- [ ] Check `key.properties` exists (for signing)
- [ ] Verify minSdkVersion and targetSdkVersion
- [ ] Check app permissions in AndroidManifest.xml

### Testing
- [x] Auto-Buy machines tested
- [x] Auto-Build machines tested
- [x] Control screen tested
- [x] Save/Load tested
- [x] Unlock system tested
- [ ] New game experience tested
- [ ] Full gameplay loop tested (start to high-tier products)
- [ ] Performance tested (battery, CPU, memory)

---

## 📱 BUILD & SIGNING

### Build Process
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Build release APK: `flutter build apk --release`
- [ ] Verify APK size (should be ~25-30MB)
- [ ] Test APK on physical Android device
- [ ] Verify no crashes on startup/gameplay

### App Signing
- [ ] Confirm keystore file exists: `android/key.properties`
- [ ] Verify signing configuration in build.gradle.kts
- [ ] Check APK is signed (via `apksigner verify`)
- [ ] Confirm SHA-1 fingerprint matches Play Console

### Alternative: App Bundle (Recommended)
- [ ] Build App Bundle: `flutter build appbundle --release`
- [ ] Verify bundle size
- [ ] Upload bundle to Play Console (preferred method)

---

## 🎮 GOOGLE PLAY CONSOLE

### Release Track Setup
- [ ] Select "Internal Testing" track
- [ ] Create new release: v1.5.0 (15)
- [ ] Upload APK or App Bundle
- [ ] Add release name: "Version 1.5.0 - Automation Update"

### Release Notes (Short Version for Console)
```
🎮 What's New in v1.5.0

🤖 AUTOMATION SYSTEM
• Auto-Buy Machines - Automatically purchase raw materials
• Auto-Build Machines - Automatically produce items across 3 tiers
• New Control Screen - Manage all automation in one place

🐛 Bug Fixes
• Fixed material leak in auto-build system
• Fixed unlock display issues
• Fixed automation not triggering unlocks
• Fixed duplicate ID generation
• Performance improvements

🎯 Beta Testers: Please test automation features and report any issues!
```

### Store Listing Updates (If Needed)
- [ ] Update short description (if mentioning new features)
- [ ] Update full description (add automation section)
- [ ] Add/update screenshots showing Control screen
- [ ] Update feature graphic (if applicable)
- [ ] Add promo video (optional but recommended)

### Beta Testing Configuration
- [ ] Create/verify beta testing track
- [ ] Add beta tester emails or groups
- [ ] Set up feedback channel link
- [ ] Configure opt-in URL (if using open beta)

---

## 📋 DOCUMENTATION

### User-Facing
- [x] Release notes created (GOOGLE_PLAY_BETA_RELEASE_NOTES.md)
- [x] Version summary created (V.1.5.md)
- [ ] Update in-app help/tutorial (if exists)
- [ ] Create "What's New" in-app message (optional)

### Developer
- [x] Bug fix documentation complete
- [x] Feature specifications complete
- [x] CHANGELOG.md updated
- [ ] README.md updated with v1.5 features
- [ ] API documentation updated (if needed)

### Testing
- [ ] Beta testing guide created (what to test)
- [ ] Known issues documented
- [ ] Bug reporting instructions provided
- [ ] Beta tester contact info confirmed

---

## 🎯 PRE-UPLOAD VERIFICATION

### Final Checks
- [ ] Test fresh install (uninstall previous version first)
- [ ] Test update from v1.4.x (if possible)
- [ ] Verify save file migration works
- [ ] Test on at least 2 different Android devices
- [ ] Test on different Android versions (min: API 21)
- [ ] Check app size after install
- [ ] Verify no crashes in first 10 minutes of gameplay

### Gameplay Verification
- [ ] Start new game → works
- [ ] Buy materials → works
- [ ] Build products → works
- [ ] Unlock progression → works
- [ ] Enable auto-buy → works
- [ ] Enable auto-build → works
- [ ] Adjust machine settings → works
- [ ] Save/load game → works
- [ ] Close/reopen app → saves persist

### Performance Checks
- [ ] No excessive battery drain
- [ ] No memory leaks (app doesn't grow unbounded)
- [ ] No UI lag or freezing
- [ ] Smooth animations
- [ ] Fast app startup (< 3 seconds)

---

## 🚀 UPLOAD PROCESS

### Step-by-Step
1. [ ] Log into Google Play Console
2. [ ] Navigate to Production.INC app
3. [ ] Select "Internal Testing" (or preferred track)
4. [ ] Click "Create new release"
5. [ ] Upload APK/App Bundle
6. [ ] Add release notes (copy from template above)
7. [ ] Review release details
8. [ ] Set rollout percentage (100% for internal testing)
9. [ ] Save and review
10. [ ] Click "Start rollout to Internal Testing"

### Post-Upload
- [ ] Verify release is "Under review" or "Live"
- [ ] Confirm beta testers receive notification
- [ ] Test opt-in link works
- [ ] Verify download from Play Store works
- [ ] Check Play Console for immediate crash reports

---

## 📊 MONITORING & FEEDBACK

### First 24 Hours
- [ ] Monitor Play Console vitals (crashes, ANRs)
- [ ] Check beta tester feedback
- [ ] Review crash reports (if any)
- [ ] Respond to beta tester questions
- [ ] Note any critical issues for hotfix

### First Week
- [ ] Collect comprehensive feedback
- [ ] Analyze crash/error statistics
- [ ] Identify patterns in bug reports
- [ ] Plan v1.5.1 patch (if needed)
- [ ] Prepare for next release phase

### Feedback Channels
- [ ] Set up/verify Discord channel
- [ ] Confirm email for bug reports
- [ ] Create GitHub issues template
- [ ] Prepare FAQ for common questions

---

## 🔄 ROLLBACK PLAN

### If Critical Issues Found
- [ ] Document issue severity
- [ ] Halt rollout in Play Console (if possible)
- [ ] Notify beta testers
- [ ] Create hotfix branch
- [ ] Fix critical bugs
- [ ] Test hotfix thoroughly
- [ ] Release v1.5.1 patch

### Emergency Contacts
- [ ] Lead developer contact info
- [ ] Play Console admin credentials
- [ ] Backup build machine access
- [ ] Keystore backup location confirmed

---

## ✅ SIGN-OFF

### Pre-Release Approval
- [ ] Lead Developer Review: _________________ Date: _______
- [ ] QA Testing Complete: __________________ Date: _______
- [ ] Documentation Review: _________________ Date: _______
- [ ] Ready for Upload: ____________________ Date: _______

### Post-Release Confirmation
- [ ] Upload Complete: _____________________ Date: _______
- [ ] Beta Testers Notified: ________________ Date: _______
- [ ] Monitoring Active: ____________________ Date: _______

---

## 📝 NOTES

### Build Information
- **Build Date**: _________________
- **Build Machine**: _________________
- **Flutter Version**: _________________
- **APK SHA-256**: _________________
- **App Bundle SHA-256**: _________________

### Issues & Decisions
_Document any decisions made during the release process:_

---

### Special Instructions
_Any special notes for this release:_

---

---

## 🎉 RELEASE COMPLETE!

When all items are checked:
1. Celebrate! 🎉
2. Monitor feedback closely
3. Be ready for quick fixes
4. Start planning v1.5.1 or v1.6.0
5. Thank your beta testers!

**Good luck with the release! 🚀**

---

**Last Updated**: October 11, 2025  
**Document Version**: 1.0  
**Release**: v1.5.0 Beta
