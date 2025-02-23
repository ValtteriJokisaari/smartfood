import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'openai_service.dart';

class FoodScraper {
  final OpenAIService _openAIService = OpenAIService();

  Future<List<Map<String, String>>> fetchLunchMenus(String city) async {
    String sanitizedCity = city.replaceAll(RegExp(r'[äÄ]'), 'a').replaceAll(RegExp(r'[öÖ]'), 'o').toLowerCase();
    String url = "https://www.lounaat.info/$sanitizedCity";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var document = html.parse(response.body);
        List<Map<String, String>> restaurantMenuList = [];

        var restaurantElements = document.querySelectorAll('.menu.item');

        for (var restaurant in restaurantElements) {
          String name = restaurant.querySelector('.item-header h3 a')?.text.trim() ?? "Unknown";
          String menu = "";
          String link = "https://www.lounaat.info" + (restaurant.querySelector('.item-header h3 a')?.attributes['href'] ?? "#");
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

          restaurantMenuList.add({
            'name': name,
            'menu': menu.isNotEmpty ? menu : "No menu available",
            'link': link,
            'opening_hours': openingHours,
          });
        }
        print(restaurantMenuList);
        return restaurantMenuList;
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
      prompt.writeln("**${restaurant['name']}**");
      prompt.writeln("*Opening Hours:* ${restaurant['opening_hours']}");
      prompt.writeln("*Menu:*\n${restaurant['menu']}");
      prompt.writeln("[More Info](${restaurant['link']})\n");
    }

    prompt.writeln("\nBased on this, what would you recommend?");
    return prompt.toString();
  }

  /// Queries the LLM with dietary-related questions using a dictionary of user preferences.
  Future<String> askLLMAboutDietaryOptions(
      List<Map<String, String>> menus, Map<String, String> userPreferences) async {
    if (menus.isEmpty) return "No menus available to analyze.";

    // Extract preferences from the dictionary.
    String dietaryRestrictions = userPreferences["dietaryRestrictions"] ?? "None";
    String allergies = userPreferences["allergies"] ?? "None";

    String formattedMenus = formatMenusForLLM(menus, "your location");

    String fullPrompt = """
    I have the following lunch menus available in your area:
    
    $formattedMenus
    
    Which options are suitable for someone who follows a $dietaryRestrictions diet and is allergic to $allergies?
    f $dietaryRestrictions is null then provide general food that follow other user's preferences
    f $allergies is null then provide general food that follow other user's preferences
    Provide the filtered options based on these preferences. Also, mention the user's preferences.
    
    Please provide dietary recommendations based on the following options:
    - List the recommended dishes that align with the given dietary preferences.
    - For each recommendation, include:
      - The restaurant name
      - The dish name
      - Any dietary information (e.g., gluten-free, vegetarian, etc.), if there is no allergies, do not mention them
      - A brief note on why it's a good option for the dietary restrictions
    
    Your response should be in the following format:
    
    1. **Restaurant Name**: Recommended Dish (Dietary Info) - Reasoning
    2. **Restaurant Name**: Recommended Dish (Dietary Info) - Reasoning
    3. (continue with more options)
    
    Please ensure the response is clear and easy to follow, with a focus on matching the dietary preferences and allergies mentioned.
    """;

    return await _openAIService.getResponse(fullPrompt);
  }
}