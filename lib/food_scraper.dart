import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'openai_service.dart';  // Import OpenAI service

class FoodScraper {
  final OpenAIService _openAIService = OpenAIService();  // LLM instance

  /// Fetches lunch menus for a given city from lounaat.info
  Future<List<Map<String, String>>> fetchLunchMenus(String city) async {
    String formattedCity = city.toLowerCase();
    String url = "https://www.lounaat.info/$formattedCity";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var document = html.parse(response.body);
        List<Map<String, String>> menus = [];

        var restaurantElements = document.querySelectorAll('.menu.item');

        for (var restaurant in restaurantElements) {
          String name = restaurant.querySelector('.item-header h3 a')?.text.trim() ?? "Unknown";
          String menu = "";
          String link = "https://www.lounaat.info" + (restaurant.querySelector('.item-header h3 a')?.attributes['href'] ?? "#");
          String distance = restaurant.querySelector('.item-footer .dist')?.text.trim() ?? "N/A";
          String openingHours = restaurant.querySelector('.item-header .lunch')?.text.trim() ?? "N/A";

          var menuItems = restaurant.querySelectorAll('.menu-item');

          for (var item in menuItems) {
            String price = item.querySelector('.price')?.text.trim() ?? "";
            String dish = item.querySelector('.dish')?.text.trim() ?? "";

            // Collect dietary information
            List<String> dietTags = [];
            var dietElements = item.querySelectorAll('.diet');
            for (var diet in dietElements) {
              dietTags.add(diet.text.trim());
            }
            String dietInfo = dietTags.isNotEmpty ? " (${dietTags.join(", ")})" : "";

            menu += "• $dish $dietInfo - $price\n";
          }

          menus.add({
            'name': name,
            'menu': menu.isNotEmpty ? menu : "No menu available",
            'link': link,
            'distance': distance,
            'opening_hours': openingHours,
          });
        }

        return menus;
      } else {
        throw Exception("Failed to load data from lounaat.info");
      }
    } catch (e) {
      print("Error fetching lunch menus: $e");
      return [];
    }
  }

  /// Formats scraped data into an LLM-friendly prompt
  String formatMenusForLLM(List<Map<String, String>> menus, String city) {
    if (menus.isEmpty) return "No lunch menus found for $city today.";

    StringBuffer prompt = StringBuffer();
    prompt.writeln("Here are today's lunch menus in $city:\n");

    for (var restaurant in menus) {
      prompt.writeln("🍽 **${restaurant['name']}**");
      prompt.writeln("📌 *Distance:* ${restaurant['distance']}");
      prompt.writeln("🕒 *Opening Hours:* ${restaurant['opening_hours']}");
      prompt.writeln("📜 *Menu:*\n${restaurant['menu']}");
      prompt.writeln("🔗 [More Info](${restaurant['link']})\n");
    }

    prompt.writeln("\nBased on this, what would you recommend?");
    return prompt.toString();
  }

  /// Queries the LLM with dietary-related questions
  Future<String> askLLMAboutDietaryOptions(List<Map<String, String>> menus, String question) async {
    if (menus.isEmpty) return "No menus available to analyze.";

    String formattedMenus = formatMenusForLLM(menus, "your location");
    
    String fullPrompt = """
    I have the following lunch menus available:

    $formattedMenus

    Question: $question

    Based on this, can you provide a dietary recommendation?
    """;

    return await _openAIService.getResponse(fullPrompt);
  }
}