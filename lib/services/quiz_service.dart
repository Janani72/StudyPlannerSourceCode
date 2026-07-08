import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
  };
}

class QuizService {
  static const String _apiUrl = 'https://models.github.ai/inference/chat/completions';

  static Future<String?> _getToken() async {
    return await SecureStorage.getToken();
  }

  static Future<List<QuizQuestion>> generateQuiz({
    required String subject,
    required String topic,
    required int numberOfQuestions,
  }) async {
    final token = await _getToken();

    // Check if token exists
    if (token == null || token.isEmpty) {
      throw Exception('⚠️ Please set your GitHub token in Settings → GitHub Token');
    }

    try {
      final prompt = '''
        Generate $numberOfQuestions multiple-choice questions about "$topic" in the subject "$subject".
        
        IMPORTANT: Return ONLY valid JSON, no other text.
        
        Format the response as a valid JSON array with this exact structure:
        [
          {
            "question": "What is the question?",
            "options": ["Option A", "Option B", "Option C", "Option D"],
            "correctAnswer": 0
          }
        ]
        
        Ensure:
        - correctAnswer is the index (0-3) of the correct option
        - All questions are educational and accurate
        - Options are plausible but only one is correct
        - Questions get progressively more challenging
        - Make questions specific to $topic in $subject
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
              'content': 'You are an expert quiz generator for students. Return only valid JSON.'
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 2000,
          'temperature': 0.8,
        }),
      );

      print('Quiz API Response Status: ${response.statusCode}');
      print('Quiz API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Parse the JSON response
        try {
          final jsonData = jsonDecode(content);
          if (jsonData is List && jsonData.isNotEmpty) {
            return jsonData.map((q) => QuizQuestion.fromJson(q)).toList();
          } else {
            throw Exception('Invalid response format: expected non-empty array');
          }
        } catch (e) {
          print('JSON Parse Error: $e');
          throw Exception('Failed to parse quiz questions. Please try again.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('❌ Invalid GitHub token. Please regenerate your token in Settings.');
      } else if (response.statusCode == 403) {
        throw Exception('❌ Token does not have required permissions. Need "public_repo" scope.');
      } else if (response.statusCode == 429) {
        throw Exception('⏳ Rate limit exceeded. Please wait a moment and try again.');
      } else {
        throw Exception('Error: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('Quiz Generation Error: $e');
      // Return fallback questions with a message
      throw Exception('Failed to generate quiz: ${e.toString()}');
    }
  }

  // Fallback questions - only used if API completely fails
  static List<QuizQuestion> _getFallbackQuestions(
      String subject, String topic, int count) {
    return List.generate(
      count,
          (index) => QuizQuestion(
        question: 'What is a fundamental concept in $topic? (Question ${index + 1})',
        options: [
          'Core concept of $topic',
          'Secondary concept of $topic',
          'Tertiary concept of $topic',
          'Advanced concept of $topic',
        ],
        correctAnswer: 0,
      ),
    );
  }
}