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

  List<String> _selectedDietaryRestrictions = [];
  String? _selectedPrimaryGoal;

  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _mealsPerDayController = TextEditingController();
  final TextEditingController _otherDietaryRestrictionController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    String? dietaryRestrictions = prefs.getString('dietaryRestrictions');
    if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
      List<String> restrictions = dietaryRestrictions
          .split(',')
          .map((e) => e.trim())
          .toList();
      setState(() {
        _selectedDietaryRestrictions = restrictions;
      });

      for (String restriction in restrictions) {
        if (restriction.startsWith("Other:")) {
          String otherValue = restriction.substring(6).trim();
          _otherDietaryRestrictionController.text = otherValue;
        }
      }
    }

    String? goal = prefs.getString('goal');
    setState(() {
      _selectedPrimaryGoal = goal;
    });

    String? cuisine = prefs.getString('cuisine');
    _cuisineController.text = cuisine ?? "";

    String? allergies = prefs.getString('allergies');
    _allergiesController.text = allergies ?? "";

    int? mealsPerDay = prefs.getInt('mealsPerDay');
    _mealsPerDayController.text = mealsPerDay != null ? mealsPerDay.toString() : "";
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    String cuisine = _cuisineController.text;
    String allergies = _allergiesController.text;
    int? mealsPerDay = int.tryParse(_mealsPerDayController.text);
    String otherDietary = _otherDietaryRestrictionController.text;

    String finalDietaryRestrictions;
    if (_selectedDietaryRestrictions.contains("Other") &&
        otherDietary.trim().isNotEmpty) {
      List<String> restrictions = List.from(_selectedDietaryRestrictions);
      int otherIndex = restrictions.indexOf("Other");
      restrictions[otherIndex] = "Other: $otherDietary";
      finalDietaryRestrictions = restrictions.join(', ');
    } else {
      finalDietaryRestrictions = _selectedDietaryRestrictions.join(', ');
    }

    await prefs.setString('dietaryRestrictions', finalDietaryRestrictions);
    await prefs.setString('goal', _selectedPrimaryGoal ?? "");
    await prefs.setString('cuisine', cuisine);
    await prefs.setString('allergies', allergies);
    await prefs.setInt('mealsPerDay', mealsPerDay ?? 0);
    await prefs.setBool('hasPreferences', true);

    // Navigate to Home after saving.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  @override
  void dispose() {
    _cuisineController.dispose();
    _allergiesController.dispose();
    _mealsPerDayController.dispose();
    _otherDietaryRestrictionController.dispose();
    super.dispose();
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
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: MultiSelectDialogField(
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
                  ),
                ),
                const SizedBox(height: 16),

                // If "Other" is selected, show an additional text field.
                if (_selectedDietaryRestrictions.contains("Other"))
                  TextFormField(
                    controller: _otherDietaryRestrictionController,
                    decoration: const InputDecoration(
                      labelText: "Please specify your dietary restriction",
                      border: OutlineInputBorder(),
                    ),
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

                // Primary Goal dropdown (single choice).
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

                // Preferred Cuisine (free text).
                TextFormField(
                  controller: _cuisineController,
                  decoration: const InputDecoration(
                    labelText: "Preferred Cuisine (Optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Allergies (free text).
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: "Allergies (Optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Meals per Day (numeric input).
                TextFormField(
                  controller: _mealsPerDayController,
                  decoration: const InputDecoration(
                    labelText: "Meals per Day",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty || int.tryParse(value) == null) {
                      return "Please enter a valid number of meals.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Save Preferences Button.
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
