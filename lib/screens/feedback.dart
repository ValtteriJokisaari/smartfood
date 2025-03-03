import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatefulWidget {
  final String menuId; // The menu the user is providing feedback for
  const FeedbackScreen({Key? key, required this.menuId}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  Future<void> _submitFeedback() async {
    String rating = _ratingController.text;
    String comment = _commentController.text;

    if (rating.isEmpty || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    Feedback feedback = Feedback(
      menuId: widget.menuId,
      userId: "sampleUserId",
      rating: int.parse(rating),
      comment: comment,
      timestamp: Timestamp.now(),
    );

    // Send feedback to Firestore
    try {
      CollectionReference feedbackCollection =
          FirebaseFirestore.instance.collection('feedback');
      await feedbackCollection.add(feedback.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully!")),
      );

      // Clear input fields
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _ratingController,
              decoration: const InputDecoration(
                labelText: 'Rating (1-5)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text('Submit Feedback'),
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
