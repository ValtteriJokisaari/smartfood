import 'package:flutter/material.dart';
import 'package:smartfood/screens/survey.dart';
import 'package:smartfood/screens/age_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = prefs.getString('themeMode') ?? 'system';
    });
  }

  void _changeTheme(String mode) {
    setState(() {
      _themeMode = mode;
    });

    // Notify the app about the theme change
    final themeNotifier = context.findAncestorWidgetOfExactType<MyApp>()?.themeNotifier;
    themeNotifier?.setTheme(mode);
  }

  // Retrieve stored user info (for account setup)
  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('userName') ?? "User Name";
    String email = prefs.getString('userEmail') ?? "user@example.com";
    return {"name": name, "email": email};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green[700],
      ),
      body: ListView(
        children: [
          // Account Setup
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("User Profile"),
            subtitle: const Text("Update your age, height and weight"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              Map<String, String> userInfo = await _getUserInfo();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgeScreen(
                    name: userInfo["name"]!,
                    email: userInfo["email"]!,
                  ),
                ),
              );
            },
          ),

          // User Preferences
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("User Preferences"),
            subtitle: const Text("Update your dietary preferences"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SurveyScreen()),
              );
            },
          ),

          // Theme Mode Selection
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text("Theme Mode"),
            subtitle: Text("Current: ${_themeMode == 'light' ? 'Light' : _themeMode == 'dark' ? 'Dark' : 'System'}"),
            trailing: DropdownButton<String>(
              value: _themeMode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _changeTheme(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: 'light', child: Text("Light")),
                DropdownMenuItem(value: 'dark', child: Text("Dark")),
                DropdownMenuItem(value: 'system', child: Text("System Default")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
