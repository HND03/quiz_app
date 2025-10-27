import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeSelected;

  const ThemeSelectionScreen({super.key, required this.onThemeSelected});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  ThemeMode _selectedTheme = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'light';
    setState(() {
      _selectedTheme =
      theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
    widget.onThemeSelected(mode);
  }

  Widget _buildThemeOption(String label, ThemeMode mode, IconData icon) {
    final bool isSelected = _selectedTheme == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        await _saveTheme(mode);
        setState(() => _selectedTheme = mode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select App Theme")),
      body: Column(
        children: [
          _buildThemeOption("Light", ThemeMode.light, Icons.light_mode),
          _buildThemeOption("Dark", ThemeMode.dark, Icons.dark_mode),
        ],
      ),
    );
  }
}
