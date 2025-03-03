import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatefulWidget {
  final String menuId;
  final String userId;
  const FeedbackScreen({Key? key, required this.menuId, required this.userId})
      : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _feedbackMessage = "";

  Future<void> _submitFeedback() async {
    String rating = _ratingController.text;
    String comment = _commentController.text;

    if (rating.isEmpty || comment.isEmpty) {
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
        timestamp: Timestamp.now(),
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

  // Method to load existing feedback if any
  Future<void> _loadExistingFeedback() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .doc(widget.userId)
          .collection('menus')
          .doc(widget.menuId)
          .get();

      if (docSnapshot.exists) {
        // If feedback exists, populate the text fields
        setState(() {
          _ratingController.text = docSnapshot['rating'].toString();
          _commentController.text = docSnapshot['comment'];
          _feedbackMessage = "Feedback loaded successfully!";
        });
      } else {
        setState(() {
          _feedbackMessage = "No existing feedback for this menu.";
        });
      }
    } catch (e) {
      setState(() {
        _feedbackMessage = "Error loading feedback.";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingFeedback(); // Load existing feedback when the screen is initialized
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
  final Timestamp timestamp;

  Feedback({
    required this.menuId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  // Convert Feedback to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
    };
  }
}
