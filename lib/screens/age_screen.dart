import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood/screens/survey.dart';
import 'package:smartfood/screens/home.dart';

class AgeScreen extends StatefulWidget {
  final String name;
  final String email;

  const AgeScreen({Key? key, required this.name, required this.email}) : super(key: key);

  @override
  _AgeScreenState createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedAge;

  Future<void> _saveAge() async {
    if (_formKey.currentState?.validate() ?? false) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('age', _selectedAge!);
      await prefs.setBool('hasAccountInfo', true);

      // After saving age, check if dietary preferences have been set.
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Display auto-filled Name and Email.
              Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Name: ${widget.name}")),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Email: ${widget.email}")),
                ],
              ),
              const SizedBox(height: 20),
              // Age Drop-down Field.
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: "Select your Age",
                  border: OutlineInputBorder(),
                ),
                value: _selectedAge,
                items: List.generate(120, (index) => index + 1)
                    .map((age) => DropdownMenuItem(
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
                    return "Please select your age.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAge,
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
