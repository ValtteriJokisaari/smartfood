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
  List<Map<String, String>> _parsedMenus = [];

  String _dietaryRestrictions = "";
  String _allergies = "";
  String _bmi = "";
  String userFeedbackSummary = "";
  bool usePreviousFeedback = false;
  bool _isFetchingFeedback = false;
  bool _newFeedbackSubmitted = false;
  bool isFeedbackFetched = false;
  bool _isAscending = true;

  String _responseProgress = "";
  bool _isAnalyzing = false;

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
      _aiResponse = "";
      _parsedMenus = [];
      _responseProgress = "";
      _isAnalyzing = false;
    });

    List<Map<String, String>> restaurantMenuList = await _foodScraper.fetchLunchMenus(_cityController.text);

    setState(() {
      _restaurantMenuList = restaurantMenuList;
      _scraperMessage = restaurantMenuList.isNotEmpty
          ? "Menus fetched with nutrition data!\n"
          "Note: Calorie values are indicative estimates and not exact measurements."
          : "No menus found.";
    });

    await _filterMenusWithAI();
  }

  Future<void> _filterMenusWithAI() async {
    if (_restaurantMenuList.isEmpty) {
      setState(() {
        _aiResponse = "No menus available to analyze.";
        _responseProgress = "";
        _isAnalyzing = false;
      });
      return;
    }

    setState(() {
      _responseProgress = "Analyzing menus...";
      _isAnalyzing = true;
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
      _parsedMenus = _sortParsedMenus(_foodScraper.parseAIResponse(_aiResponse));
      _responseProgress = "";
      _isAnalyzing = false;
    });
  }

  Future<void> _fetchFeedbackSummary() async {
    if (_user != null && (_newFeedbackSubmitted || usePreviousFeedback)) {
      if (!isFeedbackFetched || _newFeedbackSubmitted) {
        setState(() {
          _isFetchingFeedback = true;
        });
        try {
          List<Map<String, dynamic>> feedbackList = await _feedbackProcessor.getAllFeedbackFromFirestore(_user!.uid);
          String summary = await _feedbackProcessor.generateFeedbackSummary(feedbackList);
          
          setState(() {
            userFeedbackSummary = summary;
            isFeedbackFetched = true;
          });
        } catch (e) {
          setState(() {
            userFeedbackSummary = "Error retrieving feedback: $e";
          });
        } finally {
          setState(() {
            _isFetchingFeedback = false;
            _newFeedbackSubmitted = false;
          });
        }
      }
    }
  }

  Future<void> _onFeedbackSubmitted() async {
    setState(() {
      _newFeedbackSubmitted = true;
    });

    _fetchFeedbackSummary();
    print("NEW FEEDBACK WAS SUBMITTED, FETCHED FEEDBACK SUMMARY: $userFeedbackSummary");
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

  List<Map<String, String>> _sortParsedMenus(List<Map<String, String>> menus) {
    menus.sort((a, b) {
      double priceA = double.tryParse(
          a['price']!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      double priceB = double.tryParse(
          b['price']!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      return _isAscending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
    });
    return menus;
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
                      if (usePreviousFeedback && !isFeedbackFetched) {
                        _fetchFeedbackSummary();
                        print("FETCHED FEEDBACK: $userFeedbackSummary");
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
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green),
                      const SizedBox(width: 8),
                      DropdownButton<bool>(
                        value: _isAscending,
                        items: [
                          DropdownMenuItem<bool>(
                            value: true,
                            child: Row(
                              children: const [
                                Icon(Icons.arrow_upward, size: 18),
                                SizedBox(width: 6),
                                Text("Low to high"),
                              ],
                            ),
                          ),
                          DropdownMenuItem<bool>(
                            value: false,
                            child: Row(
                              children: const [
                                Icon(Icons.arrow_downward, size: 18),
                                SizedBox(width: 6),
                                Text("High to low"),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _isAscending = newValue;
                              _parsedMenus = _sortParsedMenus(_parsedMenus);
                            });
                          }
                        },
                      ),
                    ],
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
                  if (_responseProgress.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          _responseProgress,
                          style: const TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                        if (_isAnalyzing)
                          const Padding(
                            padding: EdgeInsets.only(top: 10.0),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  if (_parsedMenus.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _parsedMenus.map((menu) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "📍 ${menu['restaurant'] ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text("⏰ ${menu['openingHours'] ?? ''}"),
                                const SizedBox(height: 6),
                                Text("🍽 ${menu['dish'] ?? ''} - 💰 ${menu['price'] ?? ''}"),
                                const SizedBox(height: 6),
                                Text("🔥 ${menu['calories'] ?? ''}"),
                                const SizedBox(height: 6),
                                Text("📝 ${menu['description'] ?? ''}"),
                                const SizedBox(height: 6),
                                Text("✅ ${menu['dietaryNotes'] ?? 'No specific notes'}"),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: () => _launchURL(
                                    menu['moreInfoLink']!.isNotEmpty ? menu['moreInfoLink']! : "#",
                                  ),
                                  child: const Text("🔗 More Info"),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                  if (_parsedMenus.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        String menuId = DateTime.now().toIso8601String();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackScreen(
                              menuId: menuId,
                              menus: _parsedMenus,
                              userId: _user?.uid ?? "",
                              dietaryRestrictions: _dietaryRestrictions,
                              allergies: _allergies,
                              aiResponse: _aiResponse,
                              onFeedbackSubmitted: _onFeedbackSubmitted,
                            ),
                          ),
                        );
                      },
                      child: const Text("Submit Feedback"),
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
