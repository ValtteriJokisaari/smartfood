import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatefulWidget {
  final String menuId;
  final String userId;
  final String dietaryRestrictions;
  final String allergies;
  final String aiResponse;
  final List<Map<String, String>> menus;

  const FeedbackScreen({
    Key? key,
    required this.menuId,
    required this.userId,
    required this.dietaryRestrictions,
    required this.allergies,
    required this.aiResponse,
    required this.menus,
  }) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _feedbackMessage = "";
  List<String> _likedRestaurants = [];
  List<String> _dislikedRestaurants = [];
  List<String> _likedFoods = [];
  List<String> _dislikedFoods = [];

  String? _selectedRestaurant;
  String? _selectedDish;

  void _onRestaurantChanged(String? value) {
    setState(() {
      _selectedRestaurant = value;
    });
  }

  void _onDishChanged(String? value) {
    setState(() {
      _selectedDish = value;
    });
  }

  Future<void> _submitFeedback() async {
    String rating = _ratingController.text;
    String comment = _commentController.text;

    if (rating.isEmpty || comment.isEmpty || _selectedRestaurant == null || _selectedDish == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      Feedback feedback = Feedback(
        menuId: widget.menuId,
        userId: widget.userId,
        rating: int.parse(rating),
        comment: comment,
        dietaryRestrictions: widget.dietaryRestrictions,
        allergies: widget.allergies,
        timestamp: Timestamp.now(),
        aiResponse: widget.aiResponse,
        restaurant: _selectedRestaurant!,
        dish: _selectedDish!,
        likedRestaurants: _likedRestaurants,
        dislikedRestaurants: _dislikedRestaurants,
        likedFoods: _likedFoods,
        dislikedFoods: _dislikedFoods,
      );

      // Send feedback to Firestore under the user's specific menu
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(widget.userId)
          .collection('menus')
          .doc(widget.menuId)
          .set(feedback.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully!")),
      );

      _ratingController.clear();
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting feedback")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Feedback"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Restaurant selection dropdown
            DropdownButton<String>(
              value: _selectedRestaurant,
              hint: const Text("Select Restaurant"),
              onChanged: _onRestaurantChanged,
              items: widget.menus.map((menu) {
                return DropdownMenuItem<String>(
                  value: menu['restaurant'],
                  child: Text(menu['restaurant'] ?? ''),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            
            // Dish selection dropdown
            DropdownButton<String>(
              value: _selectedDish,
              hint: const Text("Select Dish"),
              onChanged: _onDishChanged,
              items: widget.menus.map((menu) {
                return DropdownMenuItem<String>(
                  value: menu['dish'],
                  child: Text(menu['dish'] ?? ''),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Rating input
            TextField(
              controller: _ratingController,
              decoration: const InputDecoration(
                labelText: 'Rating (1-5)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 1, // Ensure rating is a single digit (1-5)
            ),
            const SizedBox(height: 10),
            // Comment input
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            
            // User feedback options for liking or disliking restaurant/dish
            Row(
              children: [
                const Text("Like this restaurant?"),
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    setState(() {
                      if (_selectedRestaurant != null) {
                        _likedRestaurants.add(_selectedRestaurant!);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_down),
                  onPressed: () {
                    setState(() {
                      if (_selectedRestaurant != null) {
                        _dislikedRestaurants.add(_selectedRestaurant!);
                      }
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text("Like this dish?"),
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    setState(() {
                      if (_selectedDish != null) {
                        _likedFoods.add(_selectedDish!);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_down),
                  onPressed: () {
                    setState(() {
                      if (_selectedDish != null) {
                        _dislikedFoods.add(_selectedDish!);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Feedback submission button
            ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text('Submit Feedback'),
            ),
            const SizedBox(height: 10),
            // Feedback status message
            Text(
              _feedbackMessage,
              style: TextStyle(color: Colors.green[700]),
            ),
          ],
        ),
      ),
    );
  }
}

// Feedback model class for structured data
class Feedback {
  final String menuId;
  final String userId;
  final int rating;
  final String comment;
  final String dietaryRestrictions;
  final String allergies;
  final Timestamp timestamp;
  final String aiResponse;
  final String restaurant;
  final String dish;
  final List<String> likedRestaurants;
  final List<String> dislikedRestaurants;
  final List<String> likedFoods;
  final List<String> dislikedFoods;

  Feedback({
    required this.menuId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.dietaryRestrictions,
    required this.allergies,
    required this.timestamp,
    required this.aiResponse,
    required this.restaurant,
    required this.dish,
    required this.likedRestaurants,
    required this.dislikedRestaurants,
    required this.likedFoods,
    required this.dislikedFoods,
  });

  // Convert Feedback to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'dietaryRestrictions': dietaryRestrictions,
      'allergies': allergies,
      'timestamp': timestamp,
      'aiResponse': aiResponse,
      'restaurant': restaurant,
      'dish': dish,
      'likedRestaurants': likedRestaurants,
      'dislikedRestaurants': dislikedRestaurants,
      'likedFoods': likedFoods,
      'dislikedFoods': dislikedFoods,
    };
  }
}
