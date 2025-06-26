import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _gameVolume = 0.7;
  String _difficulty = 'Medium';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _gameVolume = prefs.getDouble('game_volume') ?? 0.7;
      _difficulty = prefs.getString('difficulty') ?? 'Medium';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('music_enabled', _musicEnabled);
    await prefs.setDouble('game_volume', _gameVolume);
    await prefs.setString('difficulty', _difficulty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSettingCard(
              'Audio Settings',
              [
                SwitchListTile(
                  title: const Text('Sound Effects', 
                    style: TextStyle(color: Colors.white)),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                    _saveSettings();
                  },
                  activeColor: Colors.blue,
                ),
                SwitchListTile(
                  title: const Text('Background Music', 
                    style: TextStyle(color: Colors.white)),
                  value: _musicEnabled,
                  onChanged: (value) {
                    setState(() {
                      _musicEnabled = value;
                    });
                    _saveSettings();
                  },
                  activeColor: Colors.blue,
                ),
                ListTile(
                  title: const Text('Game Volume', 
                    style: TextStyle(color: Colors.white)),
                  subtitle: Slider(
                    value: _gameVolume,
                    onChanged: (value) {
                      setState(() {
                        _gameVolume = value;
                      });
                      _saveSettings();
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettingCard(
              'Game Settings',
              [
                ListTile(
                  title: const Text('Difficulty', 
                    style: TextStyle(color: Colors.white)),
                  trailing: DropdownButton<String>(
                    value: _difficulty,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    items: ['Easy', 'Medium', 'Hard'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _difficulty = value!;
                      });
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text('Back to Menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(String title, List<Widget> children) {
    return Card(
      color: Colors.grey[850],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
