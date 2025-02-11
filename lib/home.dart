import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "openai_service.dart";  // Import OpenAI service

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OpenAIService _openAIService = OpenAIService();  // OpenAI service instance
  final TextEditingController _promptController = TextEditingController();

  User? _user;
  bool _isFirebaseInitialized = false;
  String _initializationMessage = "";
  String _firebaseAppId = "";
  List<User?> _firebaseUsers = [];
  String _aiResponse = ""; // Store AI response

  // Access environment variables
  String? firebaseApiKey = dotenv.env['FIREBASE_API_KEY'];  // Example Firebase API Key
  String? firebaseProjectId = dotenv.env['FIREBASE_PROJECT_ID'];  // Example Firebase Project ID

  Future<void> _signInWithGoogle() async {
    User? user = await _authService.signInWithGoogle();
    if (user != null) {
      setState(() {
        _user = user;
      });
      _initializeFirebase();
    } else {
      setState(() {
        _initializationMessage = "Google Sign-In failed!";
      });
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      setState(() {
        _initializationMessage = "Initializing Firebase...";
      });

      await FirebaseAuth.instance.authStateChanges().first;

      setState(() {
        _isFirebaseInitialized = true;
        _initializationMessage = "Firebase initialized successfully!";
        _firebaseAppId = Firebase.app().options.appId ?? "App ID not available";
      });

      _fetchUsers();
    } catch (e) {
      setState(() {
        _isFirebaseInitialized = false;
        _initializationMessage = "Firebase init failed: $e";
      });
    }
  }

  Future<void> _fetchUsers() async {
    final User? currentUser = _auth.currentUser;
    setState(() {
      _firebaseUsers = currentUser != null ? [currentUser] : [];
    });
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    setState(() {
      _user = null;
      _isFirebaseInitialized = false;
      _firebaseUsers.clear();
    });
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
        title: Text("SmartFood"),
        titleTextStyle: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
          fontFamily: "Poiret",
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
          ),
          if (_user != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Welcome to SmartFood",
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.grey[600],
                ),
              ),
            ),
            // Display environment variables (optional)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Firebase API Key: $firebaseApiKey",  // Display Firebase API key
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Firebase Project ID: $firebaseProjectId",  // Display Firebase Project ID
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
            if (_user == null) ...[
              // Only show Google sign-in button if user is not signed in
              ElevatedButton(
                onPressed: _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text("Sign in with Google"),
              )
            ] else ...[
              // After sign-in, show user details
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_user?.photoURL ?? ""),
              ),
              SizedBox(height: 10),
              Text("Hello, ${_user?.displayName ?? "User"}!"),
              Text(_user?.email ?? ""),
            ],

            if (_isFirebaseInitialized) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _initializationMessage,
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Firebase App ID: $_firebaseAppId",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],

            if (!_isFirebaseInitialized && _user != null)
              Center(child: CircularProgressIndicator()),

            if (_firebaseUsers.isEmpty && _isFirebaseInitialized)
              Center(child: Text("No users found.", style: TextStyle(fontSize: 18))),

            if (_firebaseUsers.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _firebaseUsers.length,
                itemBuilder: (context, index) {
                  final user = _firebaseUsers[index];
                  return ListTile(
                    title: Text(user?.email ?? "No Email"),
                    subtitle: Text(user?.displayName ?? "No Display Name"),
                  );
                },
              ),

            // OpenAI Prompt Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      labelText: "Ask AI",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _sendPrompt,
                    child: Text("Ask OpenAI"),
                  ),

                  SizedBox(height: 20),

                  if (_aiResponse.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_aiResponse, style: TextStyle(fontSize: 16)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text(query),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Text("Search suggestions"),
    );
  }
}
