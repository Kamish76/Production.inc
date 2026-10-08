import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages dynamic UI zoom and scaling preferences for the application.
class UiSettingsProvider extends ChangeNotifier {
  static const String _prefKey = 'user_ui_scale_factor';
  static const double defaultScale = 0.85;
  static const double minScale = 0.75;
  static const double maxScale = 1.25;

  double _uiScale = defaultScale;
  bool _isLoaded = false;

  double get uiScale => _uiScale;
  bool get isLoaded => _isLoaded;

  UiSettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_prefKey);
      if (saved != null) {
        _uiScale = (saved.clamp(minScale, maxScale) * 100).round() / 100.0;
      }
    } catch (e) {
      debugPrint('Error loading UI scale: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Updates the UI scale factor and persists it to local preferences.
  Future<void> setUiScale(double scale) async {
    final clamped = (scale.clamp(minScale, maxScale) * 100).round() / 100.0;
    if ((_uiScale - clamped).abs() < 0.001) return;

    _uiScale = clamped;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKey, clamped);
    } catch (e) {
      debugPrint('Error saving UI scale: $e');
    }
  }

  /// Resets the UI scale factor back to default 0.85x (85%).
  Future<void> resetUiScale() async {
    await setUiScale(defaultScale);
  }
}
