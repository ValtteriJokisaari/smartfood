import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood/screens/home.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Options for dietary restrictions with an "Other" option added.
  final List<String> _dietaryRestrictionsOptions = [
    "Vegetarian",
    "Vegan",
    "Carnivore",
    "Lactose intolerance",
    "Gluten intolerance",
    "Kosher",
    "Halal",
    "Other"
  ];

  final List<String> _primaryGoalsOptions = [
    "Weight Loss",
    "Muscle Gain",
    "Maintain Health",
    "Increase Energy",
  ];

  // Selected values
  List<String> _selectedDietaryRestrictions = []; // Supports multiple choices
  String? _selectedPrimaryGoal;

  // Variable to store user input for the "Other" dietary restriction
  String _otherDietaryRestriction = "";

  // Other free-text fields
  String _cuisine = "";
  String _allergies = "";
  int? _mealsPerDay; // Initially null

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Process dietary restrictions:
    // If "Other" is selected and input is provided, replace it with the custom text.
    String finalDietaryRestrictions;
    if (_selectedDietaryRestrictions.contains("Other") &&
        _otherDietaryRestriction.trim().isNotEmpty) {
      List<String> restrictions = List.from(_selectedDietaryRestrictions);
      int otherIndex = restrictions.indexOf("Other");
      restrictions[otherIndex] = "Other: $_otherDietaryRestriction";
      finalDietaryRestrictions = restrictions.join(', ');
    } else {
      finalDietaryRestrictions = _selectedDietaryRestrictions.join(', ');
    }

    await prefs.setString('dietaryRestrictions', finalDietaryRestrictions);
    await prefs.setString('goal', _selectedPrimaryGoal ?? "");
    await prefs.setString('cuisine', _cuisine);
    await prefs.setString('allergies', _allergies);
    await prefs.setInt('mealsPerDay', _mealsPerDay ?? 0);
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
                // Multi-select for Dietary Restrictions
                MultiSelectDialogField(
                  items: _dietaryRestrictionsOptions
                      .map((e) => MultiSelectItem<String>(e, e))
                      .toList(),
                  title: const Text("Dietary Restrictions"),
                  buttonText: const Text("Select Dietary Restrictions"),
                  listType: MultiSelectListType.CHIP,
                  initialValue: _selectedDietaryRestrictions,
                  onConfirm: (selected) {
                    setState(() {
                      _selectedDietaryRestrictions = selected.cast<String>();
                    });
                  },
                  validator: (selected) {
                    if (selected == null || selected.isEmpty) {
                      return "Please select at least one option";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // If "Other" is selected, show an additional text field.
                if (_selectedDietaryRestrictions.contains("Other"))
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Please specify your dietary restriction",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _otherDietaryRestriction = value;
                      });
                    },
                    validator: (value) {
                      if (_selectedDietaryRestrictions.contains("Other") &&
                          (value == null || value.isEmpty)) {
                        return "Please specify your dietary restriction.";
                      }
                      return null;
                    },
                  ),
                if (_selectedDietaryRestrictions.contains("Other"))
                  const SizedBox(height: 16),

                // Primary Goal dropdown (single choice)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Primary Goal",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedPrimaryGoal,
                  items: _primaryGoalsOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPrimaryGoal = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select your primary goal.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Preferred Cuisine (free text)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Preferred Cuisine",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _cuisine = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your preferred cuisine.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Allergies (free text)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Allergies",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _allergies = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your allergies.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Meals per Day (numeric input)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Meals per Day",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _mealsPerDay = int.tryParse(value);
                  },
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
