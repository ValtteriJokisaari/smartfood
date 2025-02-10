import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "auth_service.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  bool _isFirebaseInitialized = false;
  String _initializationMessage = "Initializing Firebase...";
  String _firebaseAppId = "";
  List<User?> _firebaseUsers = [];

  @override
  void initState() {
    super.initState();
    _signInWithGoogle();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SmartFood"),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        actions: [
          if (_user != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
        ],
      ),
      body: Center(
        child: !_isFirebaseInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    _initializationMessage,
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_user == null)
                    ElevatedButton(
                      onPressed: _signInWithGoogle,
                      child: Text("Sign in with Google"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                    )
                  else ...[
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_user?.photoURL ?? ""),
                    ),
                    SizedBox(height: 10),
                    Text("Hello, ${_user?.displayName ?? "User"}!"),
                    Text(_user?.email ?? ""),
                    SizedBox(height: 20),
                    Text(
                      "Firebase App ID: $_firebaseAppId",
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _firebaseUsers.isEmpty ? "No users found in Firebase." : "Firebase users testii:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _firebaseUsers.length,
                        itemBuilder: (context, index) {
                          final user = _firebaseUsers[index];
                          return ListTile(
                            title: Text(user?.email ?? "No Email"),
                            subtitle: Text(user?.displayName ?? "No Display Name"),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
