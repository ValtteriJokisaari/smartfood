import 'package:flutter/material.dart';
import 'package:smartfood/screens/survey.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            title: const Text("User Preferences"),
            subtitle: const Text("Update your dietary preferences"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to the Survey (profile/preferences) screen.
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
