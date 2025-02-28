import 'package:flutter/material.dart';
import 'package:smartfood/screens/survey.dart';
import 'package:smartfood/screens/age_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        ],
      ),
    );
  }
}
