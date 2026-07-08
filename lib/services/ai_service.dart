import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'secure_storage.dart';

class AIService {
  static const String _apiUrl = 'https://models.github.ai/inference/chat/completions';

  static Future<String?> _getToken() async {
    return await SecureStorage.getToken();
  }

  static Future<String> generateStudyPlan({
    required List<SubjectItem> subjects,
    required List<ExamItem> exams,
    required List<StudyTask> tasks,
    required List<GoalItem> goals,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return '⚠️ Please set your GitHub token in Settings → GitHub Token.';
    }

    try {
      final prompt = '''
        Create a personalized weekly study plan for a student based on:
        
        Subjects to study: ${subjects.map((s) => s.name).join(', ')}
        
        Upcoming Exams:
        ${exams.map((e) => '- ${e.title} on ${e.date.toString().split(' ').first}').join('\n')}
        
        Pending Tasks: ${tasks.where((t) => !t.done).length} tasks remaining
        ${tasks.where((t) => !t.done).map((t) => '- ${t.title}').join('\n')}
        
        Goals: ${goals.map((g) => '- ${g.title}').join('\n')}
        
        Provide a structured weekly study schedule with:
        1. Daily time allocations per subject
        2. Break recommendations
        3. Priority tasks for each day
        4. Exam preparation strategy
        
        Format the response with clear headings and bullet points.
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
            {'role': 'system', 'content': 'You are an expert academic study planner assistant.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        return '❌ Invalid GitHub token. Please regenerate your token in Settings.';
      } else if (response.statusCode == 403) {
        return '❌ Token does not have required permissions. Need "public_repo" scope.';
      } else {
        return 'Error: ${response.statusCode}\nPlease try again later.';
      }
    } catch (e) {
      return 'Error connecting to AI service: $e\n\nMake sure you have a valid GitHub token.';
    }
  }
}