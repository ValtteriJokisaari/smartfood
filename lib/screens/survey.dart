import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood/screens/home.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  String _dietaryRestrictions = "";
  String _goal = "";
  String _cuisine = "";
  String _allergies = "";
  int _mealsPerDay = 3;

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dietaryRestrictions', _dietaryRestrictions);
    await prefs.setString('goal', _goal);
    await prefs.setString('cuisine', _cuisine);
    await prefs.setString('allergies', _allergies);
    await prefs.setInt('mealsPerDay', _mealsPerDay);
    await prefs.setBool('hasPreferences', true);

    // Navigate to Home after saving
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Preferences")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Dietary Restrictions
                TextFormField(
                  decoration: const InputDecoration(labelText: "Dietary Restrictions"),
                  onChanged: (value) => _dietaryRestrictions = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your dietary restrictions.";
                    }
                    return null;
                  },
                ),

                // Primary Goal
                TextFormField(
                  decoration: const InputDecoration(labelText: "Primary Goal"),
                  onChanged: (value) => _goal = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your primary goal.";
                    }
                    return null;
                  },
                ),

                // Preferred Cuisine
                TextFormField(
                  decoration: const InputDecoration(labelText: "Preferred Cuisine"),
                  onChanged: (value) => _cuisine = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your preferred cuisine.";
                    }
                    return null;
                  },
                ),

                // Allergies Field
                TextFormField(
                  decoration: const InputDecoration(labelText: "Allergies"),
                  onChanged: (value) => _allergies = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your allergies.";
                    }
                    return null;
                  },
                ),

                // Meals per Day
                TextFormField(
                  decoration: const InputDecoration(labelText: "Meals per Day"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _mealsPerDay = int.tryParse(value) ?? 3,
                  validator: (value) {
                    if (value == null || value.isEmpty || int.tryParse(value) == null) {
                      return "Please enter a valid number of meals.";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Save Preferences Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _savePreferences();
                    }
                  },
                  child: const Text("Save Preferences"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
