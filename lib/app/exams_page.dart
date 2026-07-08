import 'package:flutter/material.dart';
import '../ui_helpers.dart';
import '../models.dart';
import 'app_widget.dart';

class ExamsPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const ExamsPage({super.key, required this.parent});
  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  void _add() async {
    final titleCtrl = TextEditingController();
    final subjCtrl = TextEditingController();
    DateTime date = DateTime.now().add(const Duration(days: 7));
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Exam'),
        content: StatefulBuilder(builder: (ctx, setS) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              appInput(titleCtrl, 'Title', Icons.event_note),
              const SizedBox(height: 12),
              appInput(subjCtrl, 'Subject', Icons.menu_book),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          'Date: ${date.toString().split(' ').first}')),
                  TextButton(
                    onPressed: () async {
                      final p = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: date);
                      if (p != null) setS(() => date = p);
                    },
                    child: const Text('Pick'),
                  ),
                ],
              )
            ],
          );
        }),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              widget.parent.exams.add(ExamItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text.trim(),
                subject: subjCtrl.text.trim(),
                date: date,
              ));
              widget.parent.saveAll();
              setState(() {});
              Navigator.pop(dialogCtx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.parent.exams;
    return Scaffold(
      body: e.isEmpty
          ? const Center(child: Text('No exams yet'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: e.length,
        itemBuilder: (_, i) {
          final days = e[i].date.difference(DateTime.now()).inDays;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: Text(e[i].title),
              subtitle: Text(
                  '${e[i].subject} • ${e[i].date.toString().split(' ').first}'),
              trailing: Text(days >= 0 ? '$days d' : 'past',
                  style: TextStyle(
                      color: days < 3 ? Colors.red : null,
                      fontWeight: FontWeight.bold)),
              onLongPress: () {
                widget.parent.exams.removeAt(i);
                widget.parent.saveAll();
                setState(() {});
              },
            ),
          );
        },
      ),
      floatingActionButton:
      FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    );
  }
}