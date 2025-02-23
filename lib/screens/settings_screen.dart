import 'package:flutter/material.dart';
import 'package:smartfood/screens/survey.dart';
import 'package:smartfood/screens/age_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // This function attempts to retrieve the user's name and email.
  // In a real-world scenario, you may want to retrieve this from your auth service.
  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    // These keys should be set during your sign-in process.
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
            title: const Text("Account Setup"),
            subtitle: const Text("Update your age"),
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
              // Navigate to the Survey (preferences) screen.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SurveyScreen()),
              );
            },
          ),
          // Additional settings options can be added here.
        ],
      ),
    );
  }
}
