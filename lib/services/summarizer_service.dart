import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage.dart';

class SummarizerService {
  static const String _apiUrl = 'https://models.github.ai/inference/chat/completions';

  static Future<String?> _getToken() async {
    return await SecureStorage.getToken();
  }

  static Future<String> summarizeNote(String content) async {
    if (content.isEmpty) {
      return 'No content to summarize.';
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('⚠️ Please set your GitHub token in Settings → GitHub Token');
    }

    try {
      final prompt = '''
        Summarize the following study notes. 
        
        Requirements:
        1. Extract the 3-5 most important key points
        2. Write in clear, concise bullet points
        3. Use emojis for visual appeal (📚, 💡, ⭐, etc.)
        4. Keep each point under 15 words
        5. Focus on main ideas, not details
        
        Notes:
        $content
        
        Return ONLY the summary with bullet points, no other text.
      ''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'model': 'openai/gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert study notes summarizer. Return only the summary.'
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 300,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        throw Exception('❌ Invalid GitHub token. Please regenerate your token in Settings.');
      } else if (response.statusCode == 403) {
        throw Exception('❌ Token does not have required permissions. Need "public_repo" scope.');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback summary if API fails
      return _getFallbackSummary(content);
    }
  }

  static String _getFallbackSummary(String content) {
    final words = content.split(' ');

    if (words.length <= 20) {
      return '''
📝 Summary of your notes:
• ${content.substring(0, content.length > 50 ? 50 : content.length)}...
• Review the full notes for complete understanding
• Key concepts noted
''';
    }

    // Extract key sentences
    final sentences = content.split(RegExp(r'[.!?]+'));
    final keyPoints = sentences
        .where((s) => s.trim().length > 20)
        .take(3)
        .map((s) => '• ${s.trim()}')
        .join('\n');

    return '''
📚 Key Points from Your Notes:

$keyPoints

💡 Review the complete notes for full details.
⭐ Focus on understanding these main concepts.
''';
  }
}