import 'package:flutter/material.dart';
import 'package:smartfood/auth_service.dart';
import 'package:smartfood/screens/home.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    final user = await AuthService().signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-in failed. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Center(
        child: ElevatedButton.icon(
          label: const Text("Sign in with Google"),
          onPressed: () => _signIn(context),
        ),
      ),
    );
  }
}
