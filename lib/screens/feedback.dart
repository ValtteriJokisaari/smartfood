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
  final Map<String, TextEditingController> _restaurantComments = {};
  final Map<String, TextEditingController> _dishComments = {};

  String? _selectedRestaurant;
  String? _selectedDish;

  List<String> _likedRestaurants = [];
  List<String> _dislikedRestaurants = [];
  List<String> _likedFoods = [];
  List<String> _dislikedFoods = [];

  int _rating = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onRestaurantChanged(String? value) {
    setState(() {
      _selectedRestaurant = value;
      _selectedDish = null;
      _commentController.clear();
    });
  }

  void _onDishChanged(String? value) {
    setState(() {
      _selectedDish = value;
      _commentController.clear();
    });
  }

  void _toggleLikeRestaurant() {
    setState(() {
      if (_selectedRestaurant != null) {
        if (_likedRestaurants.contains(_selectedRestaurant!)) {
          _likedRestaurants.remove(_selectedRestaurant!);
        } else {
          _likedRestaurants.add(_selectedRestaurant!);
          _dislikedRestaurants.remove(_selectedRestaurant!);
        }
      }
    });
  }

  void _toggleDislikeRestaurant() {
    setState(() {
      if (_selectedRestaurant != null) {
        if (_dislikedRestaurants.contains(_selectedRestaurant!)) {
          _dislikedRestaurants.remove(_selectedRestaurant!);
        } else {
          _dislikedRestaurants.add(_selectedRestaurant!);
          _likedRestaurants.remove(_selectedRestaurant!);
        }
      }
    });
  }

  void _toggleLikeDish() {
    setState(() {
      if (_selectedDish != null) {
        if (_likedFoods.contains(_selectedDish!)) {
          _likedFoods.remove(_selectedDish!);
        } else {
          _likedFoods.add(_selectedDish!);
          _dislikedFoods.remove(_selectedDish!);
        }
      }
    });
  }

  void _toggleDislikeDish() {
    setState(() {
      if (_selectedDish != null) {
        if (_dislikedFoods.contains(_selectedDish!)) {
          _dislikedFoods.remove(_selectedDish!);
        } else {
          _dislikedFoods.add(_selectedDish!);
          _likedFoods.remove(_selectedDish!);
        }
      }
    });
  }

  Future<void> _submitFeedback() async {
    if (_selectedRestaurant == null || _selectedDish == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a restaurant and a dish")),
      );
      return;
    }

    String restaurantComment = _restaurantComments[_selectedRestaurant]?.text ?? "";
    String dishComment = _dishComments[_selectedDish]?.text ?? "";

    try {
      Feedback feedback = Feedback(
        menuId: widget.menuId,
        userId: widget.userId,
        rating: _rating,
        comment: _commentController.text,
        dietaryRestrictions: widget.dietaryRestrictions,
        allergies: widget.allergies,
        timestamp: Timestamp.now(),
        aiResponse: widget.aiResponse,
        restaurant: _selectedRestaurant!,
        dish: _selectedDish!,
        restaurantComment: restaurantComment,
        dishComment: dishComment,
        likedRestaurants: _likedRestaurants,
        dislikedRestaurants: _dislikedRestaurants,
        likedFoods: _likedFoods,
        dislikedFoods: _dislikedFoods,
      );

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Feedback"),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              DropdownButton<String>(
                value: _selectedRestaurant,
                hint: const Text("Select Restaurant"),
                onChanged: _onRestaurantChanged,
                items: widget.menus.map((menu) {
                  return DropdownMenuItem<String>(
                    value: menu['restaurant'],
                    child: Text(menu['restaurant'] ?? ''),
                  );
                }).toSet().toList(),
              ),
              const SizedBox(height: 10),

              DropdownButton<String>(
                value: _selectedDish,
                hint: const Text("Select Dish"),
                onChanged: _onDishChanged,
                items: widget.menus
                    .where((menu) => menu['restaurant'] == _selectedRestaurant)
                    .map((menu) {
                  return DropdownMenuItem<String>(
                    value: menu['dish'],
                    child: Text(menu['dish'] ?? ''),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Text("Rating (0-5): "),
                  Text("$_rating", style: TextStyle(fontSize: 20)),
                ],
              ),
              Slider(
                value: _rating.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                label: _rating.toString(),
                onChanged: (double newRating) {
                  setState(() {
                    _rating = newRating.toInt();
                  });
                },
              ),
              const SizedBox(height: 10),
              
              if (_selectedRestaurant != null)
                TextField(
                  controller: _restaurantComments.putIfAbsent(
                    _selectedRestaurant!,
                    () => TextEditingController(),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Comment for ${_selectedRestaurant!}',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              const SizedBox(height: 10),
              
              if (_selectedDish != null)
                TextField(
                  controller: _dishComments.putIfAbsent(
                    _selectedDish!,
                    () => TextEditingController(),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Comment for ${_selectedDish!}',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              const SizedBox(height: 10),
              
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'General Comment',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  const Text("Like this restaurant?"),
                  IconButton(
                    icon: Icon(
                      Icons.thumb_up,
                      color: _likedRestaurants.contains(_selectedRestaurant) ? Colors.green : null,
                    ),
                    onPressed: _toggleLikeRestaurant,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.thumb_down,
                      color: _dislikedRestaurants.contains(_selectedRestaurant) ? Colors.red : null,
                    ),
                    onPressed: _toggleDislikeRestaurant,
                  ),
                ],
              ),
              
              Row(
                children: [
                  const Text("Like this dish?"),
                  IconButton(
                    icon: Icon(
                      Icons.thumb_up,
                      color: _likedFoods.contains(_selectedDish) ? Colors.green : null,
                    ),
                    onPressed: _toggleLikeDish,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.thumb_down,
                      color: _dislikedFoods.contains(_selectedDish) ? Colors.red : null,
                    ),
                    onPressed: _toggleDislikeDish,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: _submitFeedback,
                child: const Text('Submit Feedback'),
              ),
            ],
          ),
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
  final String restaurantComment;
  final String dishComment;
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
    required this.restaurantComment,
    required this.dishComment,
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
      'restaurantComment': restaurantComment,
      'dishComment': dishComment,
      'likedRestaurants': likedRestaurants,
      'dislikedRestaurants': dislikedRestaurants,
      'likedFoods': likedFoods,
      'dislikedFoods': dislikedFoods,
    };
  }
}
