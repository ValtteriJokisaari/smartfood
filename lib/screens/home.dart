import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood/auth_service.dart';
import 'package:smartfood/food_scraper.dart';
import 'package:smartfood/screens/signin.dart';
import 'package:smartfood/screens/settings_screen.dart';
import 'package:smartfood/screens/feedback.dart';
import 'package:smartfood/process_feedback.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodScraper _foodScraper = FoodScraper();
  final FeedbackProcessor _feedbackProcessor = FeedbackProcessor();

  final TextEditingController _cityController = TextEditingController();

  User? _user;
  List<Map<String, String>> _restaurantMenuList = [];
  String _scraperMessage = "";
  String _aiResponse = "";

  String _dietaryRestrictions = "";
  String _allergies = "";
  String _bmi = "";
  String userFeedbackSummary = "";
  bool usePreviousFeedback = false;
  bool _isFetchingFeedback = false;

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
      _bmi = prefs.getString('bmi') ?? "None";
    });

    String? storedCity = prefs.getString('city');
    if (storedCity != null && storedCity.isNotEmpty) {
      setState(() {
        _cityController.text = storedCity;
      });
    }
  }

  Future<void> _checkUserSignIn() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
      });
      _saveUserData(user);
    }
  }

  Future<void> _saveUserData(User user) async {
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    DocumentSnapshot docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      await userDocRef.set({
        'name': user.displayName,
        'email': user.email,
        'profilePicture': user.photoURL ?? '',
      });
    }
  }

  Future<void> _fetchMenus() async {
    setState(() {
      _scraperMessage = "Fetching menus...";
    });

    List<Map<String, String>> restaurantMenuList = await _foodScraper.fetchLunchMenus(_cityController.text);

    setState(() {
      _restaurantMenuList = restaurantMenuList;
      _scraperMessage = restaurantMenuList.isNotEmpty ? "Menus fetched successfully!" : "No menus found.";
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

    setState(() {
      _aiResponse = "Analyzing menus...";
    });

    Map<String, String> userPreferences = {
      "dietaryRestrictions": _dietaryRestrictions,
      "allergies": _allergies,
      "bmi": _bmi,
    };

    String feedbackSummary = usePreviousFeedback ? userFeedbackSummary : "";
    String response = await _foodScraper.askLLMAboutDietaryOptions(
      _restaurantMenuList, userPreferences, _cityController.text, feedbackSummary
    );

    setState(() {
      _aiResponse = response;
    });
  }

  Future<void> _fetchFeedbackSummary() async {
    if (_user != null) {
      setState(() {
        _isFetchingFeedback = true;
      });
      try {
        List<Map<String, dynamic>> feedbackList = await _feedbackProcessor.getAllFeedbackFromFirestore(_user!.uid);
        String summary = await _feedbackProcessor.generateFeedbackSummary(feedbackList);
        
        setState(() {
          userFeedbackSummary = summary;
        });
      } catch (e) {
        setState(() {
          userFeedbackSummary = "Error retrieving feedback: $e";
        });
      } finally {
        setState(() {
          _isFetchingFeedback = false;
        });
      }
    }
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

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print("Could not launch $url");
    }
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
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
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
                  CheckboxListTile(
                    title: const Text("Use previous feedback for suggestions"),
                    value: usePreviousFeedback,
                    onChanged: (bool? value) {
                      setState(() {
                        usePreviousFeedback = value ?? false;
                      });
                      if (usePreviousFeedback) {
                        _fetchFeedbackSummary();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_isFetchingFeedback)
                    const CircularProgressIndicator(),
                  if (!usePreviousFeedback && userFeedbackSummary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        "Feedback Summary: $userFeedbackSummary",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  const SizedBox(height: 10),
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
                      MarkdownBody(
                        data: _aiResponse,
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            _launchURL(href);
                          }
                        },
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        List<Map<String, String>> parsedMenus = _foodScraper.parseAIResponse(_aiResponse);
                        String menuId = DateTime.now().toIso8601String();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackScreen(
                              menuId: menuId,
                              menus: parsedMenus,
                              userId: _user?.uid ?? "",
                              dietaryRestrictions: _dietaryRestrictions,
                              allergies: _allergies,
                              aiResponse: _aiResponse,
                            ),
                          ),
                        );
                      },
                      child: const Text("Submit Feedback"),
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
