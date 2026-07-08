import 'package:flutter/material.dart';
import '../services/ai_service.dart';  // ✅ IMPORT IS HERE
import '../ui_helpers.dart';
import 'app_widget.dart';

class AIPlannerPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const AIPlannerPage({super.key, required this.parent});

  @override
  State<AIPlannerPage> createState() => _AIPlannerPageState();
}

class _AIPlannerPageState extends State<AIPlannerPage> {
  bool _isLoading = false;
  String _plan = '';
  String _error = '';

  Future<void> _generatePlan() async {
    if (widget.parent.subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some subjects first to generate a study plan.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _plan = '';
    });

    try {
      final plan = await AIService.generateStudyPlan(
        subjects: widget.parent.subjects,
        exams: widget.parent.exams,
        tasks: widget.parent.tasks,
        goals: widget.parent.goals,
      );
      setState(() => _plan = plan);
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Study plan copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.parent.subjects.isEmpty ? null : _generatePlan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.parent.subjects.isEmpty)
              const AppCard(
                child: Column(
                  children: [
                    Icon(Icons.warning, size: 48, color: Colors.orange),
                    SizedBox(height: 12),
                    Text(
                      'Please add some subjects first to generate a study plan.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Go to Subjects page and add your courses.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating your personalized study plan...'),
                      SizedBox(height: 8),
                      Text(
                        'This may take a few seconds',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (_plan.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology, color: Colors.indigo),
                              const SizedBox(width: 8),
                              const Text(
                                'Your AI Study Plan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: _copyPlan,
                                tooltip: 'Copy plan',
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            _plan,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _generatePlan,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Regenerate Plan'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.psychology, size: 80, color: Colors.indigo),
                        const SizedBox(height: 16),
                        const Text(
                          'Ready to create your study plan!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click the button below to generate a personalized\nstudy plan based on your subjects and tasks.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _generatePlan,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Study Plan'),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}