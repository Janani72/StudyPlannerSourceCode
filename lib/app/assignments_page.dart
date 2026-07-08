import 'package:flutter/material.dart';
import '../ui_helpers.dart';
import '../models.dart';
import 'app_widget.dart';

class AssignmentsPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const AssignmentsPage({super.key, required this.parent});
  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  void _add() async {
    final titleCtrl = TextEditingController();
    final subjCtrl = TextEditingController();
    DateTime due = DateTime.now().add(const Duration(days: 3));
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Assignment'),
        content: StatefulBuilder(builder: (ctx, setS) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              appInput(titleCtrl, 'Title', Icons.assignment),
              const SizedBox(height: 12),
              appInput(subjCtrl, 'Subject', Icons.menu_book),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          'Due: ${due.toString().split(' ').first}')),
                  TextButton(
                    onPressed: () async {
                      final p = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: due);
                      if (p != null) setS(() => due = p);
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
              widget.parent.assignments.add(AssignmentItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text.trim(),
                subject: subjCtrl.text.trim(),
                due: due,
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
    final a = widget.parent.assignments;
    return Scaffold(
      body: a.isEmpty
          ? const Center(child: Text('No assignments yet'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: a.length,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(a[i].title),
            subtitle: Text(
                '${a[i].subject} • due ${a[i].due.toString().split(' ').first}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.parent.assignments.removeAt(i);
                widget.parent.saveAll();
                setState(() {});
              },
            ),
          ),
        ),
      ),
      floatingActionButton:
      FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    );
  }
}