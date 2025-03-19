import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartfood/openai_service.dart';

class FeedbackProcessor {
  final OpenAIService _openAIService = OpenAIService();

  Future<List<Map<String, dynamic>>> getAllFeedbackFromFirestore(String userId) async {
    try {
      QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .doc(userId)
          .collection('menus')
          .get();

      if (feedbackSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> feedbackList = feedbackSnapshot.docs
            .map((doc) {
              Map<String, dynamic> feedbackData = doc.data() as Map<String, dynamic>;
              feedbackData.remove('aiResponse');
              return feedbackData;
            })
            .toList();
        return feedbackList;
      } else {
        throw Exception("No feedback found for the given userId.");
      }
    } catch (e) {
      throw Exception("Error retrieving feedback: $e");
    }
  }

  Future<String> generateFeedbackSummary(List<Map<String, dynamic>> feedbackList) async {
  if (feedbackList.isEmpty) {
    return "No feedback available to summarize.";
  }

  try {
    String summary = "Feedback Summary:\n\n";

    for (var feedback in feedbackList) {
      summary += "Restaurant: ${feedback['restaurant']}\n";
      summary += "Dish: ${feedback['dish']}\n";
      summary += "Rating: ${feedback['rating']}\n";
      summary += "Comment: ${feedback['comment']}\n";
      summary += "Dish Comment: ${feedback['dishComment']}\n";
      summary += "Dietary Restrictions: ${feedback['dietaryRestrictions']}\n";
      summary += "Allergies: ${feedback['allergies']}\n";
      summary += "Liked Foods: ${feedback['likedFoods'].join(', ')}\n";
      summary += "Disliked Foods: ${feedback['dislikedFoods'].join(', ')}\n";
      summary += "Liked Restaurants: ${feedback['likedRestaurants'].join(', ')}\n";
      summary += "Disliked Restaurants: ${feedback['dislikedRestaurants'].join(', ')}\n";
      summary += "Restaurant Comment: ${feedback['restaurantComment']}\n\n";
    }

    String prompt = "Summarize the following feedback:\n$summary";
    print(summary);
    String llmProcessedSummary = await _openAIService.getResponse(prompt);

    return llmProcessedSummary;
  } catch (e) {
    return "Error generating feedback summary: $e";
  }
}

}
