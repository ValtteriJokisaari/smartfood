import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];

  Future<String> getResponse(String prompt) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "4o-mini",
        "messages": [
          {"role": "system", "content": "You are a helpful assistant."},
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 3000,
      }),
    );

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return decodedResponse["choices"][0]["message"]["content"].trim();
    } else {
      return "Error: ${response.reasonPhrase}";
    }
  }
}
