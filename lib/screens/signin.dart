import 'package:flutter/material.dart';
import 'package:smartfood/auth_service.dart';
import 'package:smartfood/screens/home.dart';
import 'package:smartfood/screens/age_screen.dart';
import 'package:smartfood/screens/survey.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future _signIn(BuildContext context) async {
    final user = await AuthService().signInWithGoogle();
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      // Check if account info (age) exists.
      bool hasAccountInfo = prefs.getBool('hasAccountInfo') ?? false;

      if (!hasAccountInfo) {
        // Navigate to AgeScreen, passing the auto-filled name and email.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AgeScreen(
              name: user.displayName ?? "No Name",
              email: user.email ?? "No Email",
            ),
          ),
        );
      } else {
        // If account info exists, check if dietary preferences are set.
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-in failed. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.greenAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon.
                Image.asset(
                  'assets/logo.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),
                // App Name.
                const Text(
                  "SmartFood",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Sign-In Button.
                GestureDetector(
                  onTap: () => _signIn(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(width: 10),
                        Text(
                          "Sign in with Google",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "By signing in, you agree to our Terms & Conditions",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
