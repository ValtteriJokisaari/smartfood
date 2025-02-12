import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood/auth_service.dart';
import 'package:smartfood/food_scraper.dart';
import 'package:smartfood/screens/signin.dart';  // Import SignIn screen

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodScraper _foodScraper = FoodScraper();

  final TextEditingController _cityController = TextEditingController();

  User? _user;
  List<Map<String, String>> _lunchMenus = [];
  String _scraperMessage = "";
  String _aiResponse = "";

  // Stored preferences
  String _dietaryRestrictions = "";
  String _allergies = "";

  @override
  void initState() {
    super.initState();
    _checkUserSignIn(); // Check if the user is already signed in
    _loadPreferences(); // Load stored preferences on startup
  }

  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dietaryRestrictions = prefs.getString('dietaryRestrictions') ?? "None";
      _allergies = prefs.getString('allergies') ?? "None";
    });
  }

  // Check if user is signed in
  Future<void> _checkUserSignIn() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
      });
    }
  }

  // Fetches lunch menus for the entered city
  Future<void> _fetchMenus() async {
    setState(() {
      _scraperMessage = "Fetching menus...";
    });

    List<Map<String, String>> menus = await _foodScraper.fetchLunchMenus(_cityController.text);

    setState(() {
      _lunchMenus = menus;
      _scraperMessage = menus.isNotEmpty ? "Menus fetched successfully!" : "No menus found.";
    });

    // Automatically filter the menus with stored preferences (no need for manual input)
    _filterMenusWithAI();
  }

  // Queries AI for dietary-friendly lunch options using stored preferences
  Future<void> _filterMenusWithAI() async {
    if (_lunchMenus.isEmpty) {
      setState(() {
        _aiResponse = "No menus available to analyze.";
      });
      return;
    }

    String question = """
      Which options are suitable for someone who follows a $_dietaryRestrictions diet and is allergic to $_allergies?
      Provide the filtered options based on these preferences. Also, mention the user's preferences.
    """;

    setState(() {
      _aiResponse = "Analyzing menus...";
    });

    String response = await _foodScraper.askLLMAboutDietaryOptions(_lunchMenus, question);

    setState(() {
      _aiResponse = response;
    });
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    setState(() {
      _user = null;
    });

    // Navigate to SignIn screen after sign out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),  // Replace with your sign-in screen
    );
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Welcome to SmartFood",
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
            ),

            // Display user info if logged in
            if (_user != null) ...[
              CircleAvatar(radius: 40, backgroundImage: NetworkImage(_user?.photoURL ?? "")),
              SizedBox(height: 10),
              Text("Hello, ${_user?.displayName ?? "User"}!"),
              Text(_user?.email ?? ""),
            ],

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: "Enter City",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchMenus,
                    child: Text("Fetch Lunch Menus"),
                  ),
                  SizedBox(height: 10),
                  Text(_scraperMessage, style: TextStyle(fontSize: 16, color: Colors.blue)),

                  if (_lunchMenus.isNotEmpty) ...[
                    SizedBox(height: 10),
                    if (_aiResponse.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _aiResponse,
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
