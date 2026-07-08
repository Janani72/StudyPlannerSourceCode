import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'ui_helpers.dart';

class TimerService {
  static const _todayKey = 'study_seconds_today';
  static const _dateKey = 'study_date';

  static Future<void> addStudySeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_dateKey) ?? today;

    int current = prefs.getInt(_todayKey) ?? 0;

    if (lastDate != today) {
      current = 0;
      await prefs.setString(_dateKey, today);
    }

    current += seconds;
    await prefs.setInt(_todayKey, current);
  }

  static Future<int> getStudySecondsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_dateKey) ?? today;

    if (lastDate != today) return 0;
    return prefs.getInt(_todayKey) ?? 0;
  }
}

// ===================== TIMERS PAGE =====================
class TimersPage extends StatefulWidget {
  const TimersPage({super.key});

  @override
  State<TimersPage> createState() => _TimersPageState();
}

class _TimersPageState extends State<TimersPage>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  int studyTodaySeconds = 0;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
    loadStudy();
  }

  Future<void> loadStudy() async {
    final value = await TimerService.getStudySecondsToday();
    setState(() => studyTodaySeconds = value);
  }

  Future<void> trackTime(int seconds) async {
    await TimerService.addStudySeconds(seconds);
    await loadStudy();
  }

  String formatTime(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SectionHeader('Timers & Sessions'),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.timelapse, color: Colors.indigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Today studied: ${formatTime(studyTodaySeconds)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: controller,
              tabs: const [
                Tab(text: 'Pomodoro'),
                Tab(text: 'Session'),
                Tab(text: 'Stopwatch'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: controller,
                children: [
                  PomodoroTab(onTrack: trackTime),
                  SessionTab(onTrack: trackTime),
                  StopwatchTab(onTrack: trackTime),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== POMODORO TAB =====================
class PomodoroTab extends StatefulWidget {
  final Future<void> Function(int seconds) onTrack;
  const PomodoroTab({super.key, required this.onTrack});

  @override
  State<PomodoroTab> createState() => _PomodoroTabState();
}

class _PomodoroTabState extends State<PomodoroTab> {
  int studyMinutes = 25;
  int breakMinutes = 5;
  int remaining = 25 * 60;
  bool running = false;
  bool isBreak = false;
  Timer? timer;

  void start() {
    if (running) return;
    setState(() => running = true);

    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (remaining > 0) {
        setState(() => remaining--);
        if (!isBreak) {
          await widget.onTrack(1);
        }
      } else {
        timer?.cancel();
        setState(() {
          running = false;
          isBreak = !isBreak;
          remaining = (isBreak ? breakMinutes : studyMinutes) * 60;
        });
        // Show notification when timer completes
        _showTimerCompleteNotification();
      }
    });
  }

  void _showTimerCompleteNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBreak ? '🎉 Break time! Take a rest.' : '🎯 Focus session complete!',
        ),
        backgroundColor: isBreak ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void pause() {
    timer?.cancel();
    setState(() => running = false);
  }

  void reset() {
    timer?.cancel();
    setState(() {
      isBreak = false;
      remaining = studyMinutes * 60;
      running = false;
    });
  }

  void setCustom(int s, int b) {
    timer?.cancel();
    setState(() {
      studyMinutes = s;
      breakMinutes = b;
      isBreak = false;
      remaining = s * 60;
      running = false;
    });
  }

  String format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        AppCard(
          child: Column(
            children: [
              Text(
                isBreak ? '☕ Break' : '🎯 Focus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isBreak ? Colors.orange : Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                format(remaining),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: running ? pause : start,
                      icon: Icon(running ? Icons.pause : Icons.play_arrow),
                      label: Text(running ? 'Pause' : 'Start'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚡ Presets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetButton('25 / 5', () => setCustom(25, 5), Colors.blue),
                  _buildPresetButton('50 / 10', () => setCustom(50, 10), Colors.green),
                  _buildPresetButton('15 / 3', () => setCustom(15, 3), Colors.orange),
                  _buildPresetButton('🎨 Custom', () async {
                    final result = await showDialog<List<int>>(
                      context: context,
                      builder: (_) => const CustomTimeDialog(),
                    );
                    if (result != null) {
                      setCustom(result[0], result[1]);
                    }
                  }, Colors.purple),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              Icon(
                isBreak ? Icons.coffee : Icons.bolt,
                color: isBreak ? Colors.orange : Colors.indigo,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBreak
                      ? 'Break time! Relax for $breakMinutes minutes'
                      : 'Focus time! Study for $studyMinutes minutes',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onPressed, Color color) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}

// ===================== CUSTOM TIME DIALOG =====================
class CustomTimeDialog extends StatefulWidget {
  const CustomTimeDialog({super.key});

  @override
  State<CustomTimeDialog> createState() => _CustomTimeDialogState();
}

class _CustomTimeDialogState extends State<CustomTimeDialog> {
  final study = TextEditingController(text: '30');
  final breakC = TextEditingController(text: '5');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎨 Custom Pomodoro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: study,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Study minutes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.timer),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: breakC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Break minutes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.coffee),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final s = int.tryParse(study.text) ?? 25;
            final b = int.tryParse(breakC.text) ?? 5;
            if (s > 0 && b > 0) {
              Navigator.pop(context, [s, b]);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter valid numbers')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ===================== SESSION TAB =====================
class SessionTab extends StatefulWidget {
  final Future<void> Function(int seconds) onTrack;
  const SessionTab({super.key, required this.onTrack});

  @override
  State<SessionTab> createState() => _SessionTabState();
}

class _SessionTabState extends State<SessionTab> {
  int seconds = 0;
  bool running = false;
  Timer? timer;

  void start() {
    if (running) return;
    setState(() => running = true);

    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      setState(() => seconds++);
      await widget.onTrack(1);
    });
  }

  void pause() {
    timer?.cancel();
    setState(() => running = false);
  }

  void reset() {
    timer?.cancel();
    setState(() {
      seconds = 0;
      running = false;
    });
  }

  String format(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        AppCard(
          child: Column(
            children: [
              const Text(
                '📚 Study Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                format(seconds),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: running ? pause : start,
                      icon: Icon(running ? Icons.pause : Icons.play_arrow),
                      label: Text(running ? 'Pause' : 'Start'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),  // ✅ CORRECT - use label
                    ),
                  ),
                ],
              ),
              if (seconds > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Great job! Keep going! 💪',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== STOPWATCH TAB =====================
class StopwatchTab extends StatefulWidget {
  final Future<void> Function(int seconds) onTrack;
  const StopwatchTab({super.key, required this.onTrack});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> {
  int seconds = 0;
  bool running = false;
  Timer? timer;

  void start() {
    if (running) return;
    setState(() => running = true);

    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      setState(() => seconds++);
      await widget.onTrack(1);
    });
  }

  void pause() {
    timer?.cancel();
    setState(() => running = false);
  }

  void reset() {
    timer?.cancel();
    setState(() {
      seconds = 0;
      running = false;
    });
  }

  String format(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        AppCard(
          child: Column(
            children: [
              const Text(
                '⏱️ Stopwatch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                format(seconds),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: running ? pause : start,
                      icon: Icon(running ? Icons.pause : Icons.play_arrow),
                      label: Text(running ? 'Pause' : 'Start'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),  // ✅ CORRECT
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (seconds > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Time: ${format(seconds)}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== WEEKLY PLANNER PAGE =====================
class WeeklyPlannerPage extends StatefulWidget {
  final List<PlannerItem> planner;
  final Future<void> Function() onChanged;
  final String Function() createId;
  final Function(String) showMsg;

  const WeeklyPlannerPage({
    super.key,
    required this.planner,
    required this.onChanged,
    required this.createId,
    required this.showMsg,
  });

  @override
  State<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends State<WeeklyPlannerPage> {
  final title = TextEditingController();
  final subject = TextEditingController();
  DateTime selectedDate = DateTime.now();
  RecurringType recurring = RecurringType.none;

  DateTime startOfWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  List<DateTime> getWeekDays() {
    final start = startOfWeek();
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  List<PlannerItem> itemsForDay(DateTime day) {
    return widget.planner.where((p) {
      if (_sameDay(p.date, day)) return true;
      if (p.recurring == RecurringType.daily) return true;
      if (p.recurring == RecurringType.weekly &&
          p.date.weekday == day.weekday) {
        return true;
      }
      if (p.recurring == RecurringType.monthly && p.date.day == day.day) {
        return true;
      }
      return false;
    }).toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> addItem() async {
    if (title.text.trim().isEmpty || subject.text.trim().isEmpty) {
      widget.showMsg('Please fill all fields');
      return;
    }

    widget.planner.add(
      PlannerItem(
        id: widget.createId(),
        title: title.text.trim(),
        subject: subject.text.trim(),
        date: selectedDate,
        recurring: recurring,
      ),
    );

    title.clear();
    subject.clear();
    recurring = RecurringType.none;
    await widget.onChanged();
    setState(() {});
    widget.showMsg('✅ Planner item added');
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final days = getWeekDays();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SectionHeader('📅 Weekly Planner'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: days.map((day) {
                  final items = itemsForDay(day);
                  final isToday = _sameDay(day, DateTime.now());
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_dayName(day.weekday)} ${day.day}/${day.month}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.indigo : null,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '${items.length} items',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          const Text(
                            'No items',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ...items.map(
                              (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: item.completed,
                              onChanged: (_) async {
                                item.completed = !item.completed;
                                await widget.onChanged();
                                setState(() {});
                                widget.showMsg(
                                  item.completed ? '✅ Completed!' : '↩️ Unmarked',
                                );
                              },
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                decoration: item.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.completed ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Text(
                              '${item.subject} • ${_getRecurringLabel(item.recurring)}',
                              style: TextStyle(
                                color: item.completed ? Colors.grey : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.recurring != RecurringType.none)
                                  Icon(
                                    _getRecurringIcon(item.recurring),
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () async {
                                    widget.planner.remove(item);
                                    await widget.onChanged();
                                    setState(() {});
                                    widget.showMsg('🗑️ Deleted');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: subject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${selectedDate.day}/${selectedDate.month}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<RecurringType>(
                    value: recurring,
                    items: RecurringType.values
                        .map(
                          (r) => DropdownMenuItem(
                        value: r,
                        child: Row(
                          children: [
                            Icon(_getRecurringIcon(r), size: 16),
                            const SizedBox(width: 8),
                            Text(_getRecurringLabel(r)),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => recurring = val);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Recurring',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add to Weekly Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  String _getRecurringLabel(RecurringType type) {
    switch (type) {
      case RecurringType.daily:
        return 'Daily 🔄';
      case RecurringType.weekly:
        return 'Weekly 📅';
      case RecurringType.monthly:
        return 'Monthly 📆';
      default:
        return 'Once';
    }
  }

  IconData _getRecurringIcon(RecurringType type) {
    switch (type) {
      case RecurringType.daily:
        return Icons.repeat;
      case RecurringType.weekly:
        return Icons.repeat_on;
      case RecurringType.monthly:
        return Icons.repeat_one;
      default:
        return Icons.check;
    }
  }
}

// ===================== MONTHLY PLANNER PAGE =====================
class MonthlyPlannerPage extends StatefulWidget {
  final List<PlannerItem> planner;
  final Future<void> Function() onChanged;
  final String Function() createId;
  final Function(String) showMsg;

  const MonthlyPlannerPage({
    super.key,
    required this.planner,
    required this.onChanged,
    required this.createId,
    required this.showMsg,
  });

  @override
  State<MonthlyPlannerPage> createState() => _MonthlyPlannerPageState();
}

class _MonthlyPlannerPageState extends State<MonthlyPlannerPage> {
  DateTime current = DateTime.now();

  List<PlannerItem> itemsForDay(DateTime day) {
    return widget.planner.where((p) {
      if (_sameDay(p.date, day)) return true;
      if (p.recurring == RecurringType.daily) return true;
      if (p.recurring == RecurringType.weekly &&
          p.date.weekday == day.weekday) {
        return true;
      }
      if (p.recurring == RecurringType.monthly && p.date.day == day.day) {
        return true;
      }
      return false;
    }).toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int getCompletedCount(DateTime day) {
    return itemsForDay(day).where((p) => p.completed).length;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(current.year, current.month + 1, 0).day;
    final firstDay = DateTime(current.year, current.month, 1);
    final startOffset = firstDay.weekday - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SectionHeader('📆 Monthly Planner'),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      current = DateTime(current.year, current.month - 1);
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Expanded(
                  child: Text(
                    '${_monthName(current.month)} ${current.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      current = DateTime(current.year, current.month + 1);
                    });
                  },
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Weekday headers
            Row(
              children: const [
                Expanded(child: Text('Mon', textAlign: TextAlign.center)),
                Expanded(child: Text('Tue', textAlign: TextAlign.center)),
                Expanded(child: Text('Wed', textAlign: TextAlign.center)),
                Expanded(child: Text('Thu', textAlign: TextAlign.center)),
                Expanded(child: Text('Fri', textAlign: TextAlign.center)),
                Expanded(child: Text('Sat', textAlign: TextAlign.center)),
                Expanded(child: Text('Sun', textAlign: TextAlign.center)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
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
                  final items = itemsForDay(date);
                  final isToday = _sameDay(date, DateTime.now());
                  final completed = getCompletedCount(date);
                  final total = items.length;

                  return GestureDetector(
                    onTap: () {
                      if (items.isEmpty) {
                        widget.showMsg('No items for this day');
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        builder: (_) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (items.isEmpty)
                                  const Text('No items for this day'),
                                ...items.map(
                                      (e) => ListTile(
                                    leading: Icon(
                                      e.completed
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: e.completed
                                          ? Colors.green
                                          : null,
                                    ),
                                    title: Text(
                                      e.title,
                                      style: TextStyle(
                                        decoration: e.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${e.subject} • ${_getRecurringLabel(e.recurring)}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () async {
                                        widget.planner.remove(e);
                                        await widget.onChanged();
                                        setState(() {});
                                        Navigator.pop(_);
                                        widget.showMsg('🗑️ Deleted');
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
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
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            if (total > 0) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: completed == total
                                      ? Colors.green
                                      : Colors.orange,
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
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  String _getRecurringLabel(RecurringType type) {
    switch (type) {
      case RecurringType.daily:
        return 'Daily 🔄';
      case RecurringType.weekly:
        return 'Weekly 📅';
      case RecurringType.monthly:
        return 'Monthly 📆';
      default:
        return 'Once';
    }
  }
}

// ===================== ATTENDANCE PAGE =====================
class AttendancePage extends StatefulWidget {
  final List<AttendanceRecord> attendance;
  final List<DailyStudyRecord> dailyStudy;
  final Future<void> Function() onChanged;
  final Function(String) showMsg;

  const AttendancePage({
    super.key,
    required this.attendance,
    required this.dailyStudy,
    required this.onChanged,
    required this.showMsg,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoMarkAttendance();
    });
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _autoMarkAttendance() async {
    final now = DateTime.now();
    bool updated = false;

    // Check past 7 days (including today)
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final targetDate = DateTime(date.year, date.month, date.day);

      // Check if we already have a record for this day
      final hasRecord = widget.attendance.any((a) => _sameDate(a.date, targetDate));
      if (!hasRecord) {
        bool isPresent = false;

        if (i == 0) {
          // Today is always marked as Present since they opened the app!
          isPresent = true;
        } else {
          // Past days: present if they logged any study minutes
          final studied = widget.dailyStudy.any((s) =>
              _sameDate(s.date, targetDate) && s.minutes > 0);
          isPresent = studied;
        }

        widget.attendance.add(
          AttendanceRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            date: targetDate,
            present: isPresent,
          ),
        );
        updated = true;
      }
    }

    if (updated) {
      // Sort attendance chronologically so it shows nicely
      widget.attendance.sort((a, b) => a.date.compareTo(b.date));
      await widget.onChanged();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.attendance.length;
    final present = widget.attendance.where((a) => a.present).length;
    final percent = total == 0 ? 0 : ((present / total) * 100).toStringAsFixed(1);

    final todayRecord = widget.attendance.where(
          (a) => _sameDate(a.date, selectedDate),
    );

    final isPresent = todayRecord.isNotEmpty && todayRecord.first.present;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SectionHeader('Attendance Tracker'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  Text(
                    'Attendance: $present/$total ($percent%)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pickDate,
                          child: Text(
                            'Inspect Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Attendance is auto-tracked based on your study activity.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (todayRecord.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Status for inspected day: ${isPresent ? "Present" : "Absent"}',
                      style: TextStyle(
                        color: isPresent ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: widget.attendance.reversed
                    .map(
                      (a) => Card(
                    child: ListTile(
                      leading: Icon(
                        a.present ? Icons.check_circle : Icons.cancel,
                        color: a.present ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        '${a.date.day}/${a.date.month}/${a.date.year}',
                      ),
                      subtitle: Text(a.present ? 'Present' : 'Absent'),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== REPORTS PAGE =====================
class ReportsPage extends StatelessWidget {
  final List<DailyStudyRecord> dailyStudy;
  final List<StudyTask> tasks;
  final List<GoalItem> goals;
  final int xp;
  final int streak;

  const ReportsPage({
    super.key,
    required this.dailyStudy,
    required this.tasks,
    required this.goals,
    required this.xp,
    required this.streak,
  });

  int weeklyMinutes() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    int min = 0;
    for (final d in dailyStudy) {
      if (d.date.isAfter(weekAgo)) min += d.minutes;
    }
    return min;
  }

  int monthlyMinutes() {
    final now = DateTime.now();
    int min = 0;
    for (final d in dailyStudy) {
      if (d.date.year == now.year && d.date.month == now.month) {
        min += d.minutes;
      }
    }
    return min;
  }

  double goalCompletionPercent() {
    if (goals.isEmpty) return 0;
    final done = goals.where((g) => g.done).length;
    return (done / goals.length) * 100;
  }

  double taskCompletionPercent() {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.done).length;
    return (done / tasks.length) * 100;
  }

  double productivityScore() {
    final goal = goalCompletionPercent();
    final task = taskCompletionPercent();
    final time = (weeklyMinutes() / 600).clamp(0, 1) * 100;
    return ((goal + task + time) / 3);
  }

  @override
  Widget build(BuildContext context) {
    final wk = weeklyMinutes();
    final mn = monthlyMinutes();
    final score = productivityScore().toStringAsFixed(1);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('Reports'),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Study',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('$wk minutes studied in last 7 days'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Study',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('$mn minutes studied this month'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Goal Completion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('${goalCompletionPercent().toStringAsFixed(1)}%'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Task Completion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('${taskCompletionPercent().toStringAsFixed(1)}%'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productivity Score',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('$score / 100'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'XP Points',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('$xp XP earned'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Study Streak',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('$streak days in a row'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== SUBJECT PROGRESS PAGE =====================
class SubjectProgressPage extends StatelessWidget {
  final List<SubjectItem> subjects;
  final List<StudyTask> tasks;
  final List<AssignmentItem> assignments;

  const SubjectProgressPage({
    super.key,
    required this.subjects,
    required this.tasks,
    required this.assignments,
  });

  double progressFor(String subjectName) {
    final relatedTasks =
    tasks.where((t) => t.title.contains(subjectName)).toList();
    final relatedAssignments =
    assignments.where((a) => a.subject == subjectName).toList();

    final total = relatedTasks.length + relatedAssignments.length;
    if (total == 0) return 0;

    final done = relatedTasks.where((t) => t.done).length +
        relatedAssignments.where((a) => a.due.isBefore(DateTime.now())).length;

    return (done / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('Subject-wise Progress'),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            const AppCard(child: Text('No subjects added yet')),
          ...subjects.map((s) {
            final p = progressFor(s.name);
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: p / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 6),
                  Text('${p.toStringAsFixed(1)}% completed'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}