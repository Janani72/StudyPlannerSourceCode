import 'package:flutter/material.dart';
import '../ui_helpers.dart';
import '../models.dart';
import 'app_widget.dart';

class GoalsPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const GoalsPage({super.key, required this.parent});
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  void _add() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Goal'),
        content: appInput(ctrl, 'Goal', Icons.flag),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              widget.parent.goals.add(GoalItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: ctrl.text.trim(),
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
    final g = widget.parent.goals;
    return Scaffold(
      body: g.isEmpty
          ? const Center(child: Text('No goals yet'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: g.length,
        itemBuilder: (_, i) => Card(
          child: CheckboxListTile(
            value: g[i].done,
            onChanged: (v) {
              setState(() => g[i].done = v ?? false);
              if (g[i].done) widget.parent.addXp(20);
              widget.parent.saveAll();
            },
            title: Text(g[i].title),
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.parent.goals.removeAt(i);
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