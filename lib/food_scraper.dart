import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'database_service.dart';
import 'openai_service.dart';

class FoodScraper {
  final OpenAIService _openAIService = OpenAIService();
  final DatabaseService _dbService = DatabaseService();

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

            menu += "• $dish$dietInfo - $price\n";
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

  double _cosineSimilarity(String a, String b) {
    final tokensA = _tokenize(a);
    final tokensB = _tokenize(b);

    final allTokens = Set<String>.from(tokensA.keys)..addAll(tokensB.keys);

    double dotProduct = 0;
    double magA = 0;
    double magB = 0;

    allTokens.forEach((token) {
      final aCount = tokensA[token] ?? 0;
      final bCount = tokensB[token] ?? 0;
      dotProduct += aCount * bCount;
      magA += aCount * aCount;
      magB += bCount * bCount;
    });

    if (magA == 0 || magB == 0) return 0.0;

    return dotProduct / (sqrt(magA) * sqrt(magB));
  }

  Map<String, int> _tokenize(String text) {
    const stopWords = {
      'ja', 'sekä', 'tai', 'kanssa', 'ilman', 'sisältää', 'sis.', 'sisältyy',
      'l', 'g', 've', 'm', 'ga', 'vl', 'vs', 'v', 'sek', 'jne', 'myös', 'kyllä',
      'ei', 'sekään', 'niin', 'että', 'kun', 'koska', 'jotta', 'ellei', 'vaan'
    };

    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\såäö-]'), '')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && !stopWords.contains(token))
        .fold<Map<String, int>>({}, (map, token) {
      final baseForm = token
          .replaceAll(RegExp(r'(lla|llä|ssa|ssä|sta|stä|lle|ksi|ineen|t)$'), '')
          .replaceAll(RegExp(r'(ia|iä|ja|jä|a|ä)$'), '');

      map[baseForm] = (map[baseForm] ?? 0) + 1;
      return map;
    });
  }

  Future<List<Map<String, dynamic>>> enhanceWithNutrition(List<Map<String, String>> menus) async {
    List<Map<String, dynamic>> enhancedMenus = [];

    for (var restaurant in menus) {
      final menuItems = restaurant['menu']!.split('\n');
      List<String> enhancedItems = [];

      for (var item in menuItems) {
        if (item.isEmpty) {
          enhancedItems.add(item);
          continue;
        }

        final dishPart = item.split('•').last.split(RegExp(r'[-–]')).first.trim();
        final dishName = dishPart.replaceAll(RegExp(r'\(.*?\)'), '').trim();

        final candidates = await _dbService.searchFoodCandidates(dishName);

        // Calculate cosine similarity for each candidate
        final matches = candidates.map((candidate) {
          final candidateName = candidate['foodname'] as String;
          return {
            'foodid': candidate['foodid'],
            'similarity': _cosineSimilarity(dishName, candidateName),
          };
        }).where((match) => match['similarity'] > 0.4).toList();

        matches.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));

        if (matches.isNotEmpty) {
          final bestMatch = matches.first;
          final energy = await _dbService.getEnergyValues(bestMatch['foodid'] as int);

          if (energy != null) {
            final kcal = (energy / 4.184).round();
            enhancedItems.add('$item - 🔥 ${kcal}kcal');
            continue;
          }
        }

        enhancedItems.add(item);
      }

      enhancedMenus.add({
        ...restaurant,
        'menu': enhancedItems.join('\n'),
      });
    }

    return enhancedMenus;
  }

  /// Formats scraped data into an LLM-friendly prompt
  String formatMenusForLLM(List<Map<String, dynamic>> menus) {
    StringBuffer prompt = StringBuffer();
    for (var restaurant in menus) {
      prompt.writeln("**${restaurant['name']}**");
      prompt.writeln("*Opening Hours:* ${restaurant['opening_hours']}");
      prompt.writeln(_extractCalorieInfo(restaurant['menu']!));
      prompt.writeln("*Menu:*\n${restaurant['menu']}");
      prompt.writeln("[More Info](${restaurant['link']})\n");
    }
    return prompt.toString();
  }

  String _extractCalorieInfo(String menu) {
    final regex = RegExp(r'🔥 (\d+)kcal');
    final matches = regex.allMatches(menu);
    if (matches.isEmpty) return '';

    final calories = matches.map((m) => int.parse(m.group(1)!)).toList();
    final minCal = calories.reduce((a, b) => a < b ? a : b);
    final maxCal = calories.reduce((a, b) => a > b ? a : b);
    return '*Estimated Calories:* ${minCal}-${maxCal} kcal/100g\n';
  }

  Future<String> askLLMAboutDietaryOptions(
      List<Map<String, dynamic>> menus, Map<String, String> userPreferences, String city) async {
    if (menus.isEmpty) return "No menus available to analyze.";

    String dietaryRestrictions = userPreferences["dietaryRestrictions"] ?? "None";
    String allergies = userPreferences["allergies"] ?? "None";
    String bmi = userPreferences["bmi"] ?? "None";

    String formattedMenus = formatMenusForLLM(menus);

    String fullPrompt = """
    I am a user looking for lunch options in **$city**. Below are the available restaurant menus:

    $formattedMenus

    ### User Preferences:
    - **Dietary Restrictions:** $dietaryRestrictions
    - **Allergies:** $allergies
    - **BMI:** $bmi

    ### Instructions:
    - Identify **dishes that match my dietary needs** while avoiding allergens and taking into account my dietary restrictions.
    - Take my **BMI ($bmi)** into account when recommending meals.
    - If BMI is high, suggest **lower-calorie, balanced meals**.
    - If BMI is low, suggest **high-energy, nutrient-dense foods**.
    - If **BMI** is not provided, then ignore BMI
    - If **no specific dietary restrictions** are provided, suggest balanced and healthy options.
    - If **no allergies are specified**, do not mention them in recommendations.
    - Show calories
    - Note all calorie values are per 100g

    ### Response Format:
    Provide a clear and structured response suitable for a **mobile app display**. Use the following format:

    Lunch options in (city) for [LIST HERE MY DIETARY RESTRICTIONS AND ALLERGIES THAT I PROVIDED]
    📍 Restaurant Name
    ⏰ Opening Hours  
    🍽 Dish Name (Dietary Info, if applicable)* - 💰 Price - 🔥 kcal/100g
    📝 Dish Description 
    ✅ Why this dish is recommended for me
    🔗 [More Info](restaurant link)  

    Example Output:
    📍 Green Bites Café
    ⏰ 11:00-14:00  
    🍽 Quinoa Salad (Vegetarian, Gluten-Free) - 💰 €9.90  - 🔥 420kcal/100g
    📝 A fresh salad made with organic quinoa, cherry tomatoes, avocado, and a zesty lemon dressing.  
    ✅ High in protein and fiber, perfect for a balanced vegetarian meal.  
    🔗 [More Info](https://example.com)  

    📍 Healthy Eats Deli
    ⏰ 10:30-15:00  
    🍽 Grilled Salmon with Steamed Vegetables (High-Protein, Omega-3 Rich) - 💰 €12.50 - 🔥 700kcal/100g
    📝 A grilled Norwegian salmon fillet served with a mix of broccoli, carrots, and a light herb butter sauce.  
    ✅ Great for a high-protein diet, rich in omega-3 fatty acids for heart health.  
    🔗 [More Info](https://example.com)  


    Please ensure your response is structured, concise, and **optimized for a mobile app layout**.
    """;

        return await _openAIService.getResponse(fullPrompt);
      }
    }
