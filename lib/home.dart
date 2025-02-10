import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<User?> _firebaseUsers = [];
  bool _isInitialized = false;
  String _initializationMessage = "Initializing Firebase...";
  String _firebaseAppId = "";

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _isInitialized = true;
        _initializationMessage = "Firebase initialized successfully! :DDD";
        _firebaseAppId = Firebase.app().options.appId ?? "App ID not available";
      });
      _fetchUsers();
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _initializationMessage = "Firebase init failed: $e";
      });
    }
  }

  Future<void> _fetchUsers() async {
    final User? user = _auth.currentUser;

    setState(() {
      if (user != null) {
        _firebaseUsers.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SmartFood"),
        titleTextStyle: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            fontFamily: "Poiret"
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                  context: context,
                  delegate: CustomSearchDelegate()
              );
            },
          ),
        ],
      ),
      body: Column(
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
                fontFamily: "Poiret",
              ),
            ),
          ),
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
          if (!_isInitialized)
            Center(
              child: CircularProgressIndicator(),
            ),
          if (_firebaseUsers.isEmpty && _isInitialized)
            Center(
              child: Text("No users found.", style: TextStyle(fontSize: 18)),
            ),
          if (_firebaseUsers.isNotEmpty)
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[600],
        onPressed: () {},
        child: Text("click"),
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
