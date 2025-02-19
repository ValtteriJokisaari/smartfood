import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood/auth_service.dart';
import 'package:smartfood/food_scraper.dart';
import 'package:smartfood/screens/signin.dart';
import 'package:smartfood/screens/settings_screen.dart'; // Import the settings screen
import 'package:smartfood/screens/survey.dart';

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
  List<Map<String, String>> _restaurantMenuList = [];
  String _scraperMessage = "";
  String _aiResponse = "";

  String _dietaryRestrictions = "";
  String _allergies = "";

  @override
  void initState() {
    super.initState();
    _checkUserSignIn();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dietaryRestrictions = prefs.getString('dietaryRestrictions') ?? "None";
      _allergies = prefs.getString('allergies') ?? "None";
    });
  }

  Future<void> _checkUserSignIn() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _fetchMenus() async {
    setState(() {
      _scraperMessage = "Fetching menus...";
    });

    List<Map<String, String>> restaurantMenuList =
    await _foodScraper.fetchLunchMenus(_cityController.text);

    setState(() {
      _restaurantMenuList = restaurantMenuList;
      _scraperMessage = restaurantMenuList.isNotEmpty
          ? "Menus fetched successfully!"
          : "No menus found.";
    });

    _filterMenusWithAI();
  }

  Future<void> _filterMenusWithAI() async {
    if (_restaurantMenuList.isEmpty) {
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

    String response =
    await _foodScraper.askLLMAboutDietaryOptions(_restaurantMenuList, question);

    setState(() {
      _aiResponse = response;
    });
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    setState(() {
      _user = null;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartFood"),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        actions: [
          if (_user != null) ...[
            // Settings icon in the top-right corner
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            // Logout icon
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Welcome to SmartFood",
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            if (_user != null) ...[
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_user?.photoURL ?? ""),
              ),
              const SizedBox(height: 10),
              Text("Hello, ${_user?.displayName ?? "User"}!"),
              Text(_user?.email ?? ""),
            ],
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Button to open SurveyScreen and change preferences
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SurveyScreen()),
                      );
                    },
                    child: Text("Change Preferences"),
                  ),
                  SizedBox(height: 10),
                  // Text field to enter city
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: "Enter City",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchMenus,
                    child: const Text("Fetch Lunch Menus"),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _scraperMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  if (_restaurantMenuList.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    if (_aiResponse.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _aiResponse,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
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
