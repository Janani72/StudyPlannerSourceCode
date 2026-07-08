import 'package:flutter/material.dart';
import '../ui_helpers.dart';
import '../models.dart';
import 'app_widget.dart';

class SubjectsPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const SubjectsPage({super.key, required this.parent});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  String _searchQuery = '';
  SubjectPriority? _filterPriority;
  String? _selectedSubjectId;

  List<SubjectItem> get _filteredSubjects {
    var subjects = widget.parent.subjects;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      subjects = subjects.where((s) =>
      s.name.toLowerCase().contains(query) ||
          (s.description?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Priority filter
    if (_filterPriority != null) {
      subjects = subjects.where((s) => s.priority == _filterPriority).toList();
    }

    return subjects;
  }

  // ============ ADD SUBJECT ============
  void _addSubject() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '2');
    ColorTag color = ColorTag.blue;
    SubjectPriority priority = SubjectPriority.medium;
    final topicsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Subject'),
        content: StatefulBuilder(
          builder: (ctx, setS) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Color
                  DropdownButtonFormField<ColorTag>(
                    value: color,
                    items: ColorTag.values
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getColor(c),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name.toUpperCase()),
                        ],
                      ),
                    ))
                        .toList(),
                    onChanged: (v) => setS(() => color = v ?? ColorTag.blue),
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.color_lens),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Priority
                  DropdownButtonFormField<SubjectPriority>(
                    value: priority,
                    items: SubjectPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Icon(
                              _getPriorityIcon(p),
                              color: _getPriorityColor(p),
                            ),
                            const SizedBox(width: 8),
                            Text(_getPriorityLabel(p)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setS(() => priority = v ?? SubjectPriority.medium),
                    decoration: const InputDecoration(
                      labelText: 'Study Priority',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Study Hours per Week
                  TextField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Study Hours per Week',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Topics
                  TextField(
                    controller: topicsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Topics (comma separated)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a subject name')),
                );
                return;
              }

              final topics = topicsCtrl.text.isNotEmpty
                  ? topicsCtrl.text.split(',').map((t) => t.trim()).toList()
                  : null;

              widget.parent.subjects.add(SubjectItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                color: color,
                priority: priority,
                description: descCtrl.text.trim(),
                studyHoursPerWeek: int.tryParse(hoursCtrl.text) ?? 2,
                topics: topics,
              ));
              widget.parent.saveAll();
              setState(() {});
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Subject added successfully!')),
              );
            },
            child: const Text('Add Subject'),
          ),
        ],
      ),
    );
  }

  // ============ EDIT SUBJECT ============
  void _editSubject(SubjectItem subject) async {
    final nameCtrl = TextEditingController(text: subject.name);
    final descCtrl = TextEditingController(text: subject.description ?? '');
    final hoursCtrl = TextEditingController(text: subject.studyHoursPerWeek.toString());
    ColorTag color = subject.color;
    SubjectPriority priority = subject.priority;
    final topicsCtrl = TextEditingController(
      text: subject.topics?.join(', ') ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Subject'),
        content: StatefulBuilder(
          builder: (ctx, setS) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ColorTag>(
                    value: color,
                    items: ColorTag.values
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getColor(c),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name.toUpperCase()),
                        ],
                      ),
                    ))
                        .toList(),
                    onChanged: (v) => setS(() => color = v ?? ColorTag.blue),
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.color_lens),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SubjectPriority>(
                    value: priority,
                    items: SubjectPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Icon(
                              _getPriorityIcon(p),
                              color: _getPriorityColor(p),
                            ),
                            const SizedBox(width: 8),
                            Text(_getPriorityLabel(p)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setS(() => priority = v ?? SubjectPriority.medium),
                    decoration: const InputDecoration(
                      labelText: 'Study Priority',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Study Hours per Week',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: topicsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Topics (comma separated)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a subject name')),
                );
                return;
              }

              final topics = topicsCtrl.text.isNotEmpty
                  ? topicsCtrl.text.split(',').map((t) => t.trim()).toList()
                  : null;

              final index = widget.parent.subjects.indexOf(subject);
              widget.parent.subjects[index] = SubjectItem(
                id: subject.id,
                name: nameCtrl.text.trim(),
                color: color,
                priority: priority,
                description: descCtrl.text.trim(),
                studyHoursPerWeek: int.tryParse(hoursCtrl.text) ?? 2,
                topics: topics,
              );
              widget.parent.saveAll();
              setState(() {});
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Subject updated successfully!')),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // ============ DELETE SUBJECT ============
  Future<void> _deleteSubject(SubjectItem subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${subject.name}"?\n'
              'This will not delete associated tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.parent.subjects.remove(subject);
      widget.parent.saveAll();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ "${subject.name}" deleted')),
      );
    }
  }

  // ============ HELPER METHODS ============
  Color _getColor(ColorTag c) {
    switch (c) {
      case ColorTag.blue: return Colors.blue;
      case ColorTag.green: return Colors.green;
      case ColorTag.orange: return Colors.orange;
      case ColorTag.purple: return Colors.purple;
      case ColorTag.red: return Colors.red;
    }
  }

  Color _getPriorityColor(SubjectPriority p) {
    switch (p) {
      case SubjectPriority.veryHigh: return Colors.red;
      case SubjectPriority.high: return Colors.orange;
      case SubjectPriority.medium: return Colors.blue;
      case SubjectPriority.low: return Colors.green;
    }
  }

  IconData _getPriorityIcon(SubjectPriority p) {
    switch (p) {
      case SubjectPriority.veryHigh: return Icons.flag_circle;
      case SubjectPriority.high: return Icons.flag;
      case SubjectPriority.medium: return Icons.flag_outlined;
      case SubjectPriority.low: return Icons.flag_outlined;
    }
  }

  String _getPriorityLabel(SubjectPriority p) {
    switch (p) {
      case SubjectPriority.veryHigh: return 'Very High Priority';
      case SubjectPriority.high: return 'High Priority';
      case SubjectPriority.medium: return 'Medium Priority';
      case SubjectPriority.low: return 'Low Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _filteredSubjects;
    final totalSubjects = widget.parent.subjects.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          if (totalSubjects > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Priority: ', style: TextStyle(fontSize: 12)),
                    _buildFilterChip('All', null),
                    _buildFilterChip('🔴 Very High', SubjectPriority.veryHigh),
                    _buildFilterChip('🟠 High', SubjectPriority.high),
                    _buildFilterChip('🔵 Medium', SubjectPriority.medium),
                    _buildFilterChip('🟢 Low', SubjectPriority.low),
                  ],
                ),
              ),
            ),

          // Subject count
          if (totalSubjects > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${subjects.length} of $totalSubjects subjects',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  if (_searchQuery.isNotEmpty || _filterPriority != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _filterPriority = null;
                      }),
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
            ),

          // Subject List
          Expanded(
            child: subjects.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty || _filterPriority != null
                        ? 'No subjects match your filters'
                        : 'No subjects yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  if (_searchQuery.isNotEmpty || _filterPriority != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _filterPriority = null;
                      }),
                      child: const Text('Clear Filters'),
                    ),
                  const SizedBox(height: 16),
                  if (totalSubjects == 0)
                    FilledButton.icon(
                      onPressed: _addSubject,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Subject'),
                    ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: subjects.length,
              itemBuilder: (_, i) => _buildSubjectCard(subjects[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, SubjectPriority? priority) {
    final isSelected = _filterPriority == priority;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterPriority = selected ? priority : null;
          });
        },
        selectedColor: Colors.indigo.withValues(alpha: 0.2),
        checkmarkColor: Colors.indigo,
      ),
    );
  }

  Widget _buildSubjectCard(SubjectItem subject) {
    final color = _getColor(subject.color);
    final priorityColor = _getPriorityColor(subject.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editSubject(subject),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Color indicator
                  Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and priority
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subject.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPriorityIcon(subject.priority),
                                    color: priorityColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPriorityLabel(subject.priority).split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: priorityColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (subject.description != null && subject.description!.isNotEmpty)
                          Text(
                            subject.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stats row
              Row(
                children: [
                  // Study hours
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${subject.studyHoursPerWeek}h/week',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Topics count
                  if (subject.topics != null && subject.topics!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.list, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${subject.topics!.length} topics',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),

                  // Action buttons
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editSubject(subject),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _deleteSubject(subject),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}