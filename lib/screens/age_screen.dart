import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood/screens/survey.dart';
import 'package:smartfood/screens/home.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AgeScreen extends StatefulWidget {
  // Optional parameters are kept for backwards compatibility.
  final String? name;
  final String? email;

  const AgeScreen({Key? key, this.name, this.email}) : super(key: key);

  @override
  _AgeScreenState createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedAge;

  // Local variables to display in the UI.
  String _displayName = "No Name";
  String _displayEmail = "No Email";

  @override
  void initState() {
    super.initState();
    _initUserInfo();
  }

  /// Always fetch the name and email from FirebaseAuth (Google account)
  /// and load the saved age from SharedPreferences.
  Future<void> _initUserInfo() async {
    // Get the current user from FirebaseAuth.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _displayName = user.displayName ?? "No Name";
        _displayEmail = user.email ?? "No Email";
      });
    }

    // Load the saved age from SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    int? storedAge = prefs.getInt('age');
    if (storedAge != null) {
      setState(() {
        _selectedAge = storedAge;
      });
    }
  }

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
              // Display the user's name from FirebaseAuth.
              Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Name: $_displayName")),
                ],
              ),
              const SizedBox(height: 8),
              // Display the user's email from FirebaseAuth.
              Row(
                children: [
                  const Icon(Icons.email),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Email: $_displayEmail")),
                ],
              ),
              const SizedBox(height: 20),
              // Age Drop-down Field using DropdownButtonFormField2.
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
