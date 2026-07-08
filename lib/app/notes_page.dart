import 'package:flutter/material.dart';
import '../ui_helpers.dart';
import '../models.dart';
import 'app_widget.dart';

class NotesPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const NotesPage({super.key, required this.parent});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  void _add() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            appInput(titleCtrl, 'Title', Icons.title),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Body'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              widget.parent.notes.add(NoteItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text.trim(),
                body: bodyCtrl.text.trim(),
                createdAt: DateTime.now(),
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
    final n = widget.parent.notes;
    return Scaffold(
      body: n.isEmpty
          ? const Center(child: Text('No notes yet'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: n.length,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.sticky_note_2),
            title: Text(n[i].title),
            subtitle: Text(n[i].body,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            onLongPress: () {
              widget.parent.notes.removeAt(i);
              widget.parent.saveAll();
              setState(() {});
            },
          ),
        ),
      ),
      floatingActionButton:
      FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    );
  }
}