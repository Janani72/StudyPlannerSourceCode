import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models.dart';
import '../ui_helpers.dart';
import 'app_widget.dart';

class StudyPlannerPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const StudyPlannerPage({super.key, required this.parent});

  @override
  State<StudyPlannerPage> createState() => _StudyPlannerPageState();
}

class _StudyPlannerPageState extends State<StudyPlannerPage> {
  // View mode: weekly or monthly
  bool _isWeeklyView = true;
  DateTime _currentDate = DateTime.now();

  // Selected day for details
  DateTime? _selectedDate;

  // Drag and drop state
  bool _isDragging = false;
  int? _draggedIndex;

  // Filter
  String _searchQuery = '';
  String? _selectedSubject;

  // ============ GET DAYS ============
  DateTime get _startOfWeek {
    final now = _currentDate;
    return now.subtract(Duration(days: now.weekday - 1));
  }

  List<DateTime> get _weekDays {
    final start = _startOfWeek;
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  int get _daysInMonth {
    return DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
  }

  DateTime get _firstDayOfMonth {
    return DateTime(_currentDate.year, _currentDate.month, 1);
  }

  // ============ GET PLANNER ITEMS ============
  List<PlannerItem> get _allItems {
    return widget.parent.plannerItems;
  }

  List<PlannerItem> _getItemsForDay(DateTime day) {
    return _allItems.where((p) {
      // Exact match
      if (_sameDay(p.date, day)) return true;

      // Recurring
      if (p.recurring == RecurringType.daily) return true;
      if (p.recurring == RecurringType.weekly && p.date.weekday == day.weekday) {
        return true;
      }
      if (p.recurring == RecurringType.monthly && p.date.day == day.day) {
        return true;
      }

      return false;
    }).toList();
  }

  List<PlannerItem> _getFilteredItemsForDay(DateTime day) {
    var items = _getItemsForDay(day);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) =>
      item.title.toLowerCase().contains(query) ||
          item.subject.toLowerCase().contains(query)
      ).toList();
    }

    // Subject filter
    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      items = items.where((item) =>
      item.subject == _selectedSubject
      ).toList();
    }

    return items;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============ SUBJECTS LIST ============
  List<String> get _allSubjects {
    return _allItems.map((p) => p.subject).toSet().toList();
  }

  // ============ CREATE STUDY PLAN ============
  Future<void> _createStudyPlan() async {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    DateTime selectedDate = _selectedDate ?? DateTime.now();
    RecurringType recurring = RecurringType.none;

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create Study Plan'),
        content: StatefulBuilder(
          builder: (ctx, setS) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Plan Title *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setS(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RecurringType>(
                    value: recurring,
                    items: RecurringType.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Row(
                          children: [
                            Icon(_getRecurringIcon(r)),
                            const SizedBox(width: 8),
                            Text(_getRecurringLabel(r)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setS(() => recurring = v ?? RecurringType.none),
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat),
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
              if (titleCtrl.text.trim().isEmpty || subjectCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all required fields')),
                );
                return;
              }

              final newPlan = PlannerItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text.trim(),
                subject: subjectCtrl.text.trim(),
                date: selectedDate,
                recurring: recurring,
              );

              widget.parent.plannerItems.add(newPlan);
              widget.parent.saveAll();
              setState(() {});
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Study plan created!')),
              );
            },
            child: const Text('Create Plan'),
          ),
        ],
      ),
    );
  }

  // ============ EDIT STUDY PLAN ============
  Future<void> _editStudyPlan(PlannerItem plan) async {
    final titleCtrl = TextEditingController(text: plan.title);
    final subjectCtrl = TextEditingController(text: plan.subject);
    DateTime selectedDate = plan.date;
    RecurringType recurring = plan.recurring;

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Study Plan'),
        content: StatefulBuilder(
          builder: (ctx, setS) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Plan Title *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setS(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RecurringType>(
                    value: recurring,
                    items: RecurringType.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Row(
                          children: [
                            Icon(_getRecurringIcon(r)),
                            const SizedBox(width: 8),
                            Text(_getRecurringLabel(r)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setS(() => recurring = v ?? RecurringType.none),
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat),
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
              if (titleCtrl.text.trim().isEmpty || subjectCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all required fields')),
                );
                return;
              }

              final index = widget.parent.plannerItems.indexOf(plan);
              widget.parent.plannerItems[index] = PlannerItem(
                id: plan.id,
                title: titleCtrl.text.trim(),
                subject: subjectCtrl.text.trim(),
                date: selectedDate,
                recurring: recurring,
              );
              widget.parent.saveAll();
              setState(() {});
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Study plan updated!')),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // ============ DELETE STUDY PLAN ============
  Future<void> _deleteStudyPlan(PlannerItem plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Study Plan'),
        content: Text('Are you sure you want to delete "${plan.title}"?'),
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
      widget.parent.plannerItems.remove(plan);
      widget.parent.saveAll();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Study plan deleted')),
      );
    }
  }

  // ============ TOGGLE COMPLETION ============
  void _toggleComplete(PlannerItem plan) {
    setState(() {
      plan.completed = !plan.completed;
    });
    widget.parent.saveAll();
  }

  // ============ HELPER METHODS ============
  String _getRecurringLabel(RecurringType type) {
    switch (type) {
      case RecurringType.daily: return 'Daily 🔄';
      case RecurringType.weekly: return 'Weekly 📅';
      case RecurringType.monthly: return 'Monthly 📆';
      default: return 'Once';
    }
  }

  IconData _getRecurringIcon(RecurringType type) {
    switch (type) {
      case RecurringType.daily: return Icons.repeat;
      case RecurringType.weekly: return Icons.repeat_on;
      case RecurringType.monthly: return Icons.repeat_one;
      default: return Icons.check;
    }
  }

  Color _getPriorityColor(String subject) {
    // Find subject in parent subjects
    final subjectItem = widget.parent.subjects.firstWhere(
          (s) => s.name == subject,
      orElse: () => SubjectItem(id: '', name: '', color: ColorTag.blue),
    );

    switch (subjectItem.color) {
      case ColorTag.red: return Colors.red;
      case ColorTag.orange: return Colors.orange;
      case ColorTag.green: return Colors.green;
      case ColorTag.purple: return Colors.purple;
      default: return Colors.blue;
    }
  }

  // ============ WEEKLY VIEW ============
  Widget _buildWeeklyView() {
    final days = _weekDays;

    return Column(
      children: [
        _buildWeekNavigation(),
        const SizedBox(height: 12),

        // Days header
        Row(
          children: days.map((day) {
            final isToday = _sameDay(day, DateTime.now());
            final items = _getFilteredItemsForDay(day);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = day);
                  _showDayDetails(day, items);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.indigo.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getDayName(day.weekday),
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday ? Colors.indigo : Colors.grey[600],
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isToday ? FontWeight.bold : null,
                          color: isToday ? Colors.indigo : null,
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${items.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Items for selected day - FIXED SECTION
        if (_selectedDate != null) ...[
          _buildDayItems(_selectedDate!, _getFilteredItemsForDay(_selectedDate!)),
        ] else ...[
          // Show today's items by default
          Builder(
            builder: (context) {
              final today = DateTime.now();
              if (_weekDays.any((d) => _sameDay(d, today))) {
                return _buildDayItems(today, _getFilteredItemsForDay(today));
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],

        const Spacer(),

        _buildAddButton(),
      ],
    );
  }

  // ============ MONTHLY VIEW ============
  Widget _buildMonthlyView() {
    final daysInMonth = _daysInMonth;
    final firstDay = _firstDayOfMonth;
    final startOffset = firstDay.weekday - 1;

    return Column(
      children: [
        _buildMonthNavigation(),
        const SizedBox(height: 12),

        // Weekday headers
        Row(
          children: const [
            Expanded(child: Text('Mon', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(child: Text('Tue', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(child: Text('Wed', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(child: Text('Thu', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(child: Text('Fri', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(child: Text('Sat', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(child: Text('Sun', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.9,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startOffset) {
                return const SizedBox();
              }
              final day = i - startOffset + 1;
              final date = DateTime(
                firstDay.year,
                firstDay.month,
                day,
              );
              final items = _getFilteredItemsForDay(date);
              final isToday = _sameDay(date, DateTime.now());
              final completed = items.where((p) => p.completed).length;
              final total = items.length;

              return GestureDetector(
                onTap: () {
                  if (items.isNotEmpty) {
                    setState(() => _selectedDate = date);
                    _showDayDetails(date, items);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: items.isNotEmpty
                        ? (isToday
                        ? Colors.indigo.withValues(alpha: 0.2)
                        : Colors.indigo.withValues(alpha: 0.08))
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: Colors.indigo, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : null,
                          color: isToday ? Colors.indigo : null,
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$items',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        if (total > 0) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 20,
                            height: 3,
                            decoration: BoxDecoration(
                              color: completed == total ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        _buildAddButton(),
      ],
    );
  }

  // ============ DAY DETAILS ============
  Widget _buildDayItems(DateTime day, List<PlannerItem> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No study plans for ${_formatDate(day)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '📚 ${_formatDate(day)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildPlanTile(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ PLAN TILE ============
  Widget _buildPlanTile(PlannerItem item) {
    final color = _getPriorityColor(item.subject);

    return ListTile(
      leading: Checkbox(
        value: item.completed,
        onChanged: (_) => _toggleComplete(item),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          decoration: item.completed ? TextDecoration.lineThrough : null,
          color: item.completed ? Colors.grey : null,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.subject,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (item.recurring != RecurringType.none)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getRecurringIcon(item.recurring), size: 10),
                  const SizedBox(width: 2),
                  Text(
                    _getRecurringLabel(item.recurring),
                    style: const TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _editStudyPlan(item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            onPressed: () => _deleteStudyPlan(item),
          ),
        ],
      ),
      onTap: () => _editStudyPlan(item),
    );
  }

  // ============ SHOW DAY DETAILS ============
  void _showDayDetails(DateTime day, List<PlannerItem> items) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📚 ${_formatDate(day)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
            const Divider(),
            if (items.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No study plans for this day'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _buildPlanTile(items[i]),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  setState(() => _selectedDate = day);
                  _createStudyPlan();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Plan for This Day'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ NAVIGATION ============
  Widget _buildWeekNavigation() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = _currentDate.subtract(const Duration(days: 7));
            });
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        Expanded(
          child: Text(
            'Week of ${_formatWeekRange()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = _currentDate.add(const Duration(days: 7));
            });
          },
          icon: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
            });
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        Expanded(
          child: Text(
            _getMonthName(_currentDate.month),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
            });
          },
          icon: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }

  // ============ ADD BUTTON ============
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _createStudyPlan,
          icon: const Icon(Icons.add),
          label: const Text('Create Study Plan'),
        ),
      ),
    );
  }

  // ============ FORMATTERS ============
  String _getDayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  String _getMonthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${_getDayName(date.weekday)} ${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _formatWeekRange() {
    final start = _startOfWeek;
    final end = start.add(const Duration(days: 6));
    return '${start.day} ${_getMonthName(start.month)} - ${end.day} ${_getMonthName(end.month)}';
  }

  // ============ FILTER DIALOG ============
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Study Plans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Subject'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              hint: const Text('All Subjects'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Subjects')),
                ..._allSubjects.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedSubject = value);
                Navigator.pop(sheetCtx);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedSubject = null;
                    _searchQuery = '';
                  });
                  Navigator.pop(sheetCtx);
                },
                child: const Text('Clear All Filters'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============ MAIN BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        actions: [
          IconButton(
            icon: Icon(_isWeeklyView ? Icons.view_week : Icons.calendar_view_month),
            onPressed: () => setState(() => _isWeeklyView = !_isWeeklyView),
            tooltip: _isWeeklyView ? 'Switch to Monthly' : 'Switch to Weekly',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search study plans...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _isWeeklyView ? _buildWeeklyView() : _buildMonthlyView(),
      ),
    );
  }
}