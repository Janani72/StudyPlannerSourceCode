import 'package:flutter/material.dart';
import '../ui_helpers.dart';
import '../models.dart';
import 'app_widget.dart';

class TasksPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const TasksPage({super.key, required this.parent});
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  void _add() async {
    final titleCtrl = TextEditingController();
    DateTime? due;
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Task'),
        content: StatefulBuilder(builder: (ctx, setS) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              appInput(titleCtrl, 'Title', Icons.task),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Text(due == null
                          ? 'No date'
                          : 'Due: ${due.toString().split(' ').first}')),
                  TextButton(
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (p != null) setS(() => due = p);
                    },
                    child: const Text('Pick Date'),
                  )
                ],
              ),
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
              widget.parent.tasks.add(StudyTask(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text.trim(),
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
    final t = widget.parent.tasks;
    return Scaffold(
      body: t.isEmpty
          ? const Center(child: Text('No tasks yet'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: t.length,
        itemBuilder: (_, i) => Card(
          child: CheckboxListTile(
            value: t[i].done,
            onChanged: (v) {
              setState(() => t[i].done = v ?? false);
              if (t[i].done) widget.parent.addXp(10);
              widget.parent.saveAll();
            },
            title: Text(t[i].title,
                style: TextStyle(
                    decoration: t[i].done
                        ? TextDecoration.lineThrough
                        : null)),
            subtitle: t[i].due != null
                ? Text('Due: ${t[i].due.toString().split(' ').first}')
                : null,
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.parent.tasks.removeAt(i);
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