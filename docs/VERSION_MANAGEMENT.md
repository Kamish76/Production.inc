# Version Management Process - Production.INC

This document outlines the standardized process for managing version numbers across the Production.INC Flutter project.

## Version Numbering Scheme

We use **Semantic Versioning (SemVer)** with the following format:
- **Flutter (pubspec.yaml):** `MAJOR.MINOR.PATCH+BUILD`
- **Android:** `versionName = "MAJOR.MINOR.PATCH"` and `versionCode = BUILD`

### Current Version: `1.4.14+14`
- **Major:** 1 (Breaking changes)
- **Minor:** 4 (New features, backward compatible)
- **Patch:** 14 (Bug fixes, backward compatible)
- **Build:** 14 (Internal build number, increments with each release)

## Files That Must Stay Synchronized

### 1. `pubspec.yaml`
```yaml
version: 1.4.14+14
```

### 2. `android/app/build.gradle.kts`
```kotlin
versionCode = 14
versionName = "1.4.14"
```

## Version Update Process

### Step 1: Determine Version Increment
- **Patch Release (x.y.Z+B):** Bug fixes only
- **Minor Release (x.Y.0+B):** New features, backward compatible
- **Major Release (X.0.0+B):** Breaking changes

### Step 2: Update Version Numbers
1. **Update `pubspec.yaml`:**
   ```bash
   # Example: 1.4.14+14 → 1.4.15+15
   version: 1.4.15+15
   ```

2. **Update `android/app/build.gradle.kts`:**
   ```kotlin
   versionCode = 15        // Always increment
   versionName = "1.4.15"  // Match semantic version
   ```

### Step 3: Verification Commands
```bash
# Verify pubspec version
grep "version:" pubspec.yaml

# Verify Android version
grep -E "(versionCode|versionName)" android/app/build.gradle.kts

# Test build
flutter build apk --release
```

### Step 4: Git Workflow
```bash
# Create version update branch
git checkout develop
git pull origin develop
git checkout -b version/1.4.15

# Make version changes
# ... edit files ...

# Commit changes
git add pubspec.yaml android/app/build.gradle.kts
git commit -m "chore: bump version to 1.4.15+15

- Update pubspec.yaml version to 1.4.15+15
- Update Android versionCode to 15
- Update Android versionName to 1.4.15"

# Push and create PR
git push origin version/1.4.15
# Create PR to develop branch
```

## Release Checklist

- [ ] Version numbers updated in all required files
- [ ] Build verification completed successfully
- [ ] Tests passing
- [ ] CHANGELOG.md updated
- [ ] Git tag created for release
- [ ] App store listings updated (if needed)

## Automation Opportunities

### Future Improvements:
1. **Automated Version Bumping:** Script to update all files simultaneously
2. **CI/CD Integration:** Automatic version validation in build pipeline
3. **Release Automation:** GitHub Actions for tag creation and deployment

## Version History Reference

| Version | Date | Type | Description |
|---------|------|------|-------------|
| 1.4.14+14 | 2025-10-08 | Patch | Version synchronization fix |
| 1.4.11+11 | Previous | Minor | Quantity preferences feature |

## Common Issues and Solutions

### Issue: Version Mismatch
**Problem:** pubspec.yaml and build.gradle.kts have different versions
**Solution:** Follow this documented process to synchronize all files

### Issue: Build Number Conflicts
**Problem:** versionCode conflicts in Play Store
**Solution:** Always increment build number, never reuse

### Issue: Semantic Versioning Confusion
**Problem:** Unclear when to increment major/minor/patch
**Solution:** Follow SemVer guidelines strictly

---

**Last Updated:** October 8, 2025  
**Next Review:** December 8, 2025