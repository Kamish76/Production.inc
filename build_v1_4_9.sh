#!/bin/bash

# Production.Inc v1.4.9 Build Script
# Enhanced build process with performance monitoring

echo "🚀 Production.Inc v1.4.9 Build Process"
echo "======================================"
echo "  - Date: $(date)"
echo "  - Version: 1.4.9+9"
echo "  - Status: Development Planning"
echo ""

# Check Flutter version
echo "📱 Checking Flutter Environment..."
flutter --version
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Run code analysis
echo "🔍 Running Flutter analysis..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ Analysis failed. Please fix issues before building."
    exit 1
fi
echo "✅ Analysis passed!"
echo ""

# Run tests
echo "🧪 Running tests..."
flutter test --reporter=compact
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Please fix issues before building."
    exit 1
fi
echo "✅ Tests passed!"
echo ""

# Build debug APK
echo "🔨 Building debug APK..."
flutter build apk --debug
if [ $? -ne 0 ]; then
    echo "❌ Debug build failed."
    exit 1
fi
echo "✅ Debug build successful!"
echo ""

# Build release APK
echo "🎯 Building release APK..."
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "❌ Release build failed."
    exit 1
fi
echo "✅ Release build successful!"
echo ""

# Performance verification
echo "📊 Performance Verification..."
echo "  - APK Size Analysis:"
ls -lh build/app/outputs/flutter-apk/app-release.apk
echo ""

# Success summary
echo "🎉 Build Process Complete!"
echo "=========================="
echo "✅ All checks passed"
echo "✅ Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
echo "✅ Release APK: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "📝 Next Steps:"
echo "  1. Test APK on physical devices"
echo "  2. Performance monitoring validation"
echo "  3. User acceptance testing"
echo "  4. Documentation review"
echo ""
echo "🚀 Ready for v1.4.9 development cycle!"
