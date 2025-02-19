import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood/screens/survey.dart';
import 'package:smartfood/screens/home.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:math';

class AgeScreen extends StatefulWidget {
  final String? name;
  final String? email;

  const AgeScreen({Key? key, this.name, this.email}) : super(key: key);

  @override
  _AgeScreenState createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedAge;

  String _displayName = "No Name";
  String _displayEmail = "No Email";

  // Optional height/weight fields
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // We will calculate the BMI only if both height & weight are provided
  double? _bmi;

  @override
  void initState() {
    super.initState();
    _initUserInfo();
  }

  Future<void> _initUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _displayName = user.displayName ?? "No Name";
        _displayEmail = user.email ?? "No Email";
      });
    }

    final prefs = await SharedPreferences.getInstance();

    int? storedAge = prefs.getInt('age');
    if (storedAge != null) {
      setState(() {
        _selectedAge = storedAge;
      });
    }

    // If you have previously stored height, weight, or bmi, you can retrieve them here:
    // double? storedHeight = prefs.getDouble('height');
    // double? storedWeight = prefs.getDouble('weight');
    // double? storedBmi = prefs.getDouble('bmi');
    //
    // If needed, assign them to controllers/variables:
    // _heightController.text = storedHeight?.toString() ?? '';
    // _weightController.text = storedWeight?.toString() ?? '';
    // _bmi = storedBmi;
  }

  /// A helper function to calculate BMI if both fields are valid
  void _calculateBmi(double height, double weight) {
    // Assuming height is in centimeters; convert to meters for BMI.
    // BMI formula = weight (kg) / [height (m)]^2
    final heightInMeters = height / 100;
    _bmi = weight / pow(heightInMeters, 2);
  }

  /// Validate and store Age, Height, Weight, and BMI
  Future<void> _saveUserData() async {
    // Validate age selection
    if (_formKey.currentState?.validate() ?? false) {
      final prefs = await SharedPreferences.getInstance();
      // Store age
      await prefs.setInt('age', _selectedAge!);
      // Mark that we've completed entering account info
      await prefs.setBool('hasAccountInfo', true);

      // Check if user entered height and weight.
      // If user left them empty or invalid, skip calculating/storing.
      final heightText = _heightController.text.trim();
      final weightText = _weightController.text.trim();

      double? height;
      double? weight;

      // Safely parse height if not empty
      if (heightText.isNotEmpty) {
        final parsedHeight = double.tryParse(heightText);
        if (parsedHeight != null && parsedHeight > 0) {
          height = parsedHeight;
          await prefs.setDouble('height', height);
        }
      }

      // Safely parse weight if not empty
      if (weightText.isNotEmpty) {
        final parsedWeight = double.tryParse(weightText);
        if (parsedWeight != null && parsedWeight > 0) {
          weight = parsedWeight;
          await prefs.setDouble('weight', weight);
        }
      }

      // Calculate and store BMI if both height & weight are valid
      if (height != null && weight != null) {
        _calculateBmi(height, weight);
        if (_bmi != null) {
          await prefs.setDouble('bmi', _bmi!);
        }
      }

      // Navigate to next screen based on whether preferences are set
      bool hasPreferences = prefs.getBool('hasPreferences') ?? false;
      if (!hasPreferences) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SurveyScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Setup"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // We only require the Age field from the form's validation perspective.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Name: $_displayName")),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Email: $_displayEmail")),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField2<int>(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                isExpanded: true,
                hint: const Text('Select your Age'),
                value: _selectedAge,
                items: List.generate(120 - 18 + 1, (index) => index + 18)
                    .map((age) => DropdownMenuItem<int>(
                  value: age,
                  child: Text(age.toString()),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAge = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select your age.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                "Height (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter your height (cm)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Weight (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter your weight (kg)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUserData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
