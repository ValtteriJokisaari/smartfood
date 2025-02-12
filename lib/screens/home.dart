import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartfood/auth_service.dart';
import 'package:smartfood/openai_service.dart';  // Ensure OpenAI service is imported

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final OpenAIService _openAIService = OpenAIService();  // OpenAI instance
  final TextEditingController _promptController = TextEditingController();

  String _aiResponse = ""; // Store AI response
  User? _user = FirebaseAuth.instance.currentUser; // Get current user

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, "/");
  }

  // Function to handle sending prompt to OpenAI
  Future<void> _sendPrompt() async {
    if (_promptController.text.isNotEmpty) {
      setState(() {
        _aiResponse = "Thinking...";
      });

      String response = await _openAIService.getResponse(_promptController.text);

      setState(() {
        _aiResponse = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartFood"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_user != null) ...[
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_user?.photoURL ?? ""),
              ),
              const SizedBox(height: 10),
              Text("Hello, ${_user?.displayName ?? "User"}!"),
              Text(_user?.email ?? ""),
            ],

            const SizedBox(height: 20),

            // OpenAI Prompt Section
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: "Ask AI",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _sendPrompt,
              child: const Text("Ask OpenAI"),
            ),

            const SizedBox(height: 20),

            if (_aiResponse.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_aiResponse, style: const TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
