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
  String formatMenusForLLM(List<Map<String, String>> menus) {
    StringBuffer prompt = StringBuffer();
    for (var restaurant in menus) {
      prompt.writeln("**${restaurant['name']}**");
      prompt.writeln("*Opening Hours:* ${restaurant['opening_hours']}");
      prompt.writeln("*Menu:*\n${restaurant['menu']}");
      prompt.writeln("[More Info](${restaurant['link']})\n");
    }
    return prompt.toString();
  }

  Future<String> askLLMAboutDietaryOptions(
      List<Map<String, String>> menus, Map<String, String> userPreferences, String city, String userFeedbackSummary) async {
    if (menus.isEmpty) return "No menus available to analyze.";

    String dietaryRestrictions = userPreferences["dietaryRestrictions"] ?? "None";
    String allergies = userPreferences["allergies"] ?? "None";
    String bmi = userPreferences["bmi"] ?? "None";

    String formattedMenus = formatMenusForLLM(menus);
    print("USERFEEDBACK" + userFeedbackSummary);

    String promptFeedbackString = "";
    if (userFeedbackSummary.isNotEmpty) {
      promptFeedbackString = """
      ### Use previous user feedback to provide better suggestions:
      
      $userFeedbackSummary""";
    }

    String fullPrompt = """
    I am a user looking for lunch options in **$city**. Below are the available restaurant menus:

    $formattedMenus

    ### User Preferences:
    - **Dietary Restrictions:** $dietaryRestrictions
    - **Allergies:** $allergies
    - **BMI:** $bmi

    $promptFeedbackString

    ### Instructions:
    - Identify **dishes that match my dietary needs** while avoiding allergens and taking into account my dietary restrictions.
    - Take my **BMI ($bmi)** into account when recommending meals.
    - If BMI is high, suggest **lower-calorie, balanced meals**.
    - If BMI is low, suggest **high-energy, nutrient-dense foods**.
    - If **BMI** is not provided, then ignore BMI
    - If **no specific dietary restrictions** are provided, suggest balanced and healthy options.
    - If **no allergies are specified**, do not mention them in recommendations.

    ### Response Format:
    Provide a clear and structured response suitable for a **mobile app display**. Use the following format:

    Lunch options in (city) for [LIST HERE MY DIETARY RESTRICTIONS AND ALLERGIES THAT I PROVIDED]
    📍 Restaurant Name
    ⏰ Opening Hours  
    🍽 Dish Name (Dietary Info, if applicable)* - 💰 Price  
    📝 Dish Description 
    ✅ Why this dish is recommended for me
    🔗 [More Info](restaurant link)  

    Example Output:
    📍 Green Bites Café
    ⏰ 11:00-14:00  
    🍽 Quinoa Salad (Vegetarian, Gluten-Free) - 💰 €9.90  
    📝 A fresh salad made with organic quinoa, cherry tomatoes, avocado, and a zesty lemon dressing.  
    ✅ High in protein and fiber, perfect for a balanced vegetarian meal.  
    🔗 [More Info](https://example.com)  

    📍 Healthy Eats Deli
    ⏰ 10:30-15:00  
    🍽 Grilled Salmon with Steamed Vegetables (High-Protein, Omega-3 Rich) - 💰 €12.50 
    📝 A grilled Norwegian salmon fillet served with a mix of broccoli, carrots, and a light herb butter sauce.  
    ✅ Great for a high-protein diet, rich in omega-3 fatty acids for heart health.  
    🔗 [More Info](https://example.com)


    [SUMMARY OF PREVIOUS FEEDBACK if provided]  


    Please ensure your response is structured, concise, and **optimized for a mobile app layout**.
    """;

        return await _openAIService.getResponse(fullPrompt);
    }
    List<Map<String, String>> parseAIResponse(String aiResponse) {
      List<Map<String, String>> parsedMenus = [];
      RegExp menuRegExp = RegExp(r"📍\s*(.*?)\s*⏰\s*(.*?)\s*🍽\s*(.*?)\s*-\s*💰\s*(.*?)\s*📝\s*(.*?)\s*(✅?.*?)(🔗\s*\[(.*?)\]\((.*?)\))?");
      
      Iterable<RegExpMatch> matches = menuRegExp.allMatches(aiResponse);
      
      for (var match in matches) {
        String restaurant = match.group(1) ?? '';
        String openingHours = match.group(2) ?? '';
        String dish = match.group(3) ?? '';
        String price = match.group(4) ?? '';
        String description = match.group(5) ?? '';
        String dietaryNotes = match.group(6) ?? '';
        String moreInfoLink = match.group(8) ?? '';

        parsedMenus.add({
          'restaurant': restaurant,
          'openingHours': openingHours,
          'dish': dish,
          'price': price,
          'description': description,
          'dietaryNotes': dietaryNotes,
          'moreInfoLink': moreInfoLink,
        });
      }
      
      return parsedMenus;
    }
    
    }
    
