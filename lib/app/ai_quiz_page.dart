import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../ui_helpers.dart';

class AIQuizPage extends StatefulWidget {
  const AIQuizPage({super.key});

  @override
  State<AIQuizPage> createState() => _AIQuizPageState();
}

class _AIQuizPageState extends State<AIQuizPage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _questionCountController =
  TextEditingController(text: '5');

  bool _isLoading = false;
  List<QuizQuestion> _questions = [];
  int? _selectedAnswer;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  String _errorMessage = '';

  Future<void> _generateQuiz() async {
    final subject = _subjectController.text.trim();
    final topic = _topicController.text.trim();
    final count = int.tryParse(_questionCountController.text) ?? 5;

    if (subject.isEmpty || topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both subject and topic')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _quizCompleted = false;
      _selectedAnswer = null;
      _errorMessage = '';
    });

    try {
      final questions = await QuizService.generateQuiz(
        subject: subject,
        topic: topic,
        numberOfQuestions: count.clamp(1, 20),
      );

      if (questions.isEmpty) {
        throw Exception('No questions generated. Please try again.');
      }

      setState(() => _questions = questions);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _answerQuestion(int index) {
    if (_selectedAnswer != null) return;

    setState(() {
      _selectedAnswer = index;
      if (index == _questions[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswer = null;
        });
      } else {
        setState(() => _quizCompleted = true);
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _quizCompleted = false;
      _selectedAnswer = null;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Quiz Generator'),
        actions: [
          if (_questions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetQuiz,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating quiz questions...'),
              SizedBox(height: 8),
              Text(
                'This may take 5-10 seconds',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        )
            : _questions.isNotEmpty
            ? _buildQuiz()
            : _buildQuizSetup(),
      ),
    );
  }

  Widget _buildQuizSetup() {
    return SingleChildScrollView(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Quiz Setup'),
            const SizedBox(height: 8),
            const Text(
              'Enter the subject and topic to generate a custom quiz',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject (e.g., Mathematics)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic (e.g., Algebra)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.topic),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _questionCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Questions (1-20)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generateQuiz,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Quiz'),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '⚠️ $_errorMessage',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Tips:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Make sure you have set your GitHub token in Settings\n'
                        '• Use specific topics for better questions\n'
                        '• Start with 5 questions to test the feature',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    if (_quizCompleted) {
      final percentage = (_score / _questions.length * 100);
      String emoji = '😊';
      String message = 'Good effort!';
      if (percentage >= 90) {
        emoji = '🏆';
        message = 'Excellent! You\'re a genius!';
      } else if (percentage >= 70) {
        emoji = '🌟';
        message = 'Great job! Keep it up!';
      } else if (percentage >= 50) {
        emoji = '💪';
        message = 'Good effort! Keep practicing!';
      } else {
        emoji = '📚';
        message = 'Keep studying! You\'ll get better!';
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppCard(
            child: Column(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quiz Completed!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      ' / ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _resetQuiz,
                        icon: const Icon(Icons.replay),
                        label: const Text('Try Again'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetQuiz,
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    final question = _questions[_currentQuestionIndex];
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Score: $_score',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                question.question,
                style: const TextStyle(fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 20),
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                bool isCorrect = index == question.correctAnswer;
                bool isSelected = _selectedAnswer == index;
                bool isWrong = isSelected && !isCorrect;

                Color? backgroundColor;
                Color? borderColor = Colors.grey.shade300;
                if (_selectedAnswer != null) {
                  if (isCorrect) {
                    backgroundColor = Colors.green.withValues(alpha: 0.15);
                    borderColor = Colors.green;
                  } else if (isWrong) {
                    backgroundColor = Colors.red.withValues(alpha: 0.15);
                    borderColor = Colors.red;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _selectedAnswer == null ? () => _answerQuestion(index) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _selectedAnswer != null
                                  ? (isCorrect
                                  ? Colors.green
                                  : (isWrong ? Colors.red : Colors.grey.shade300))
                                  : Colors.grey.shade300,
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  color: _selectedAnswer != null
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _selectedAnswer != null
                                      ? (isCorrect || isWrong ? Colors.black87 : Colors.grey)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (_selectedAnswer != null && isCorrect)
                              const Icon(Icons.check_circle, color: Colors.green),
                            if (_selectedAnswer != null && isWrong)
                              const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}