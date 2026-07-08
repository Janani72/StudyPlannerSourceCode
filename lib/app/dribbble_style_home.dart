import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import 'app_widget.dart';
import 'home_shell.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder_model.dart';
import '../theme/app_theme.dart';

class DribbbleStyleHome extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const DribbbleStyleHome({super.key, required this.parent});

  @override
  State<DribbbleStyleHome> createState() => _DribbbleStyleHomeState();
}

class _DribbbleStyleHomeState extends State<DribbbleStyleHome> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;

  // ============ PREMIUM VIBRANT COLORS ============
  static const Color _violet = Color(0xFF7C4DFF); // Electric Violet
  static const Color _lavender = Color(0xFFB388FF);
  static const Color _teal = Color(0xFF00E5FF); // Cyber Cyan
  static const Color _mint = Color(0xFF00B894);
  static const Color _gold = Color(0xFFFDCB6E);
  static const Color _rose = Color(0xFFFD79A8);
  static const Color _sunset = Color(0xFFE17055);
  static const Color _coral = Color(0xFFFF6B6B);
  static const Color _charcoal = Color(0xFF2D3436);
  static const Color _primaryBlue = Color(0xFF1A73E8); // Academic Blue

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _generateWeekDays();
  }

  void _generateWeekDays() {
    final now = DateTime.now();
    // Start week from Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekDays = List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      return DateTime(date.year, date.month, date.day);
    });
  }

  int _getTodayStudyMinutes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int minutes = 0;
    for (var record in widget.parent.dailyStudy) {
      if (record.date.year == today.year &&
          record.date.month == today.month &&
          record.date.day == today.day) {
        minutes += record.minutes;
      }
    }
    return minutes;
  }

  int _getWeeklyStudyMinutes() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    int minutes = 0;
    for (var record in widget.parent.dailyStudy) {
      if (record.date.isAfter(weekAgo)) {
        minutes += record.minutes;
      }
    }
    return minutes;
  }

  Color _getColorForSubject(ColorTag colorTag) {
    switch (colorTag) {
      case ColorTag.blue: return const Color(0xFF74B9FF);
      case ColorTag.green: return const Color(0xFF00B894);
      case ColorTag.orange: return const Color(0xFFFDCB6E);
      case ColorTag.purple: return const Color(0xFFA29BFE);
      case ColorTag.red: return const Color(0xFFFF6B6B);
    }
  }

  Color _getColorTagValue(ColorTag tag) {
    return _getColorForSubject(tag);
  }

  Color _getSubjectColorByName(String name) {
    final subject = widget.parent.subjects.firstWhere(
      (s) => s.name.toLowerCase() == name.toLowerCase(),
      orElse: () => SubjectItem(id: '', name: '', color: ColorTag.blue),
    );
    return _getColorForSubject(subject.color);
  }

  List<_Badge> _getBadges() {
    final list = <_Badge>[];
    if (widget.parent.streak >= 3) list.add(_Badge('🔥', '3-day streak'));
    if (widget.parent.streak >= 7) list.add(_Badge('🏆', '7-day streak'));
    if (widget.parent.streak >= 30) list.add(_Badge('💎', '30-day streak'));
    if (widget.parent.tasks.where((t) => t.done).length >= 5) {
      list.add(_Badge('✅', '5 tasks done'));
    }
    if (widget.parent.tasks.where((t) => t.done).length >= 25) {
      list.add(_Badge('⭐', '25 tasks done'));
    }
    if (widget.parent.xp >= 100) list.add(_Badge('🥉', 'Level 2'));
    if (widget.parent.xp >= 500) list.add(_Badge('🥈', 'Level 5+'));
    if (widget.parent.xp >= 1000) list.add(_Badge('🥇', 'Level 10+'));
    return list;
  }

  void _navigateTo(BuildContext context, int index) {
    final homeShell = context.findAncestorStateOfType<HomeShellState>();
    if (homeShell != null) {
      homeShell.navigateTo(index);
    }
  }

  // ============ SCHEDULE PARSERS ============
  List<PlannerItem> _getClassesForDate(DateTime date) {
    return widget.parent.plannerItems.where((item) {
      // Handle recurring check
      if (item.recurring == RecurringType.daily) return true;
      if (item.recurring == RecurringType.weekly) {
        return item.date.weekday == date.weekday;
      }
      return item.date.year == date.year &&
          item.date.month == date.month &&
          item.date.day == date.day;
    }).toList();
  }

  List<StudyTask> _getTasksForDate(DateTime date) {
    return widget.parent.tasks.where((t) {
      if (t.due == null) return false;
      return t.due!.year == date.year &&
          t.due!.month == date.month &&
          t.due!.day == date.day &&
          !t.done;
    }).toList();
  }

  List<ExamItem> _getExamsForDate(DateTime date) {
    return widget.parent.exams.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  List<ReminderItem> _getRemindersForDate(BuildContext context, DateTime date) {
    try {
      final provider = Provider.of<ReminderProvider>(context, listen: false);
      return provider.reminders.where((r) {
        final scheduled = r.scheduledDateTime;
        return scheduled.year == date.year &&
            scheduled.month == date.month &&
            scheduled.day == date.day &&
            !r.isCompleted;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayMinutes = _getTodayStudyMinutes();
    final weeklyMinutes = _getWeeklyStudyMinutes();
    final badges = _getBadges();

    final classes = _getClassesForDate(_selectedDate);
    final tasks = _getTasksForDate(_selectedDate);
    final exams = _getExamsForDate(_selectedDate);
    final reminders = _getRemindersForDate(context, _selectedDate);

    final totalItemsCount = classes.length + tasks.length + exams.length + reminders.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ============ SLIVER HEADER ============
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : AppTheme.primaryColor, // Soft Indigo
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WELCOME BACK,',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.parent.user?.name ?? 'Student',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              radius: 24,
                              child: Text(
                                (widget.parent.user?.name ?? 'S')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Quick Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTopMiniStat(
                              icon: Icons.local_fire_department_rounded,
                              value: '${widget.parent.streak} days',
                              label: 'Streak',
                            ),
                            _buildTopMiniStat(
                              icon: Icons.star_rounded,
                              value: '${widget.parent.xp} XP',
                              label: 'Score',
                            ),
                            _buildTopMiniStat(
                              icon: Icons.timer_rounded,
                              value: '${todayMinutes}m',
                              label: 'Study Today',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ============ HORIZONTAL WEEK STRIP (MyStudyLife style) ============
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'TIMETABLE & DEADLINES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black45,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _weekDays.length,
                      itemBuilder: (ctx, idx) {
                        final date = _weekDays[idx];
                        final isSelected = date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;
                        final isToday = date.day == DateTime.now().day &&
                            date.month == DateTime.now().month &&
                            date.year == DateTime.now().year;

                        final weekdayName = _getWeekdayLetter(date.weekday);

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDate = date);
                          },
                          child: Container(
                            width: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryBlue
                                  : (isToday
                                      ? _primaryBlue.withValues(alpha: 0.1)
                                      : Colors.transparent),
                              borderRadius: BorderRadius.circular(12),
                              border: isToday && !isSelected
                                  ? Border.all(color: _primaryBlue, width: 1)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  weekdayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : (isToday ? _primaryBlue : (isDark ? Colors.white70 : Colors.black54)),
                                  ),
                                ),
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
          ),

          // ============ MAIN DAILY LIST ============
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: totalItemsCount == 0
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            size: 64,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No classes, exams, or tasks scheduled.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Classes Section
                      if (classes.isNotEmpty) ...[
                        _buildSectionHeader('CLASSES & SESSIONS', isDark),
                        ...classes.map((item) => _buildAcademicCard(
                              title: item.title,
                              subtitle: item.subject,
                              type: 'Class',
                              timeStr: 'Scheduled',
                              color: _getSubjectColorByName(item.subject),
                              icon: Icons.school_rounded,
                              isDark: isDark,
                            )),
                        const SizedBox(height: 16),
                      ],

                      // 2. Exams Section
                      if (exams.isNotEmpty) ...[
                        _buildSectionHeader('EXAMS', isDark),
                        ...exams.map((item) => _buildAcademicCard(
                              title: item.title,
                              subtitle: item.subject,
                              type: 'Exam',
                              timeStr: 'Today',
                              color: _coral,
                              icon: Icons.event_note_rounded,
                              isDark: isDark,
                            )),
                        const SizedBox(height: 16),
                      ],

                      // 3. Tasks & Reminders
                      if (tasks.isNotEmpty || reminders.isNotEmpty) ...[
                        _buildSectionHeader('TASKS & REMINDERS', isDark),
                        ...tasks.map((item) => _buildAcademicCard(
                              title: item.title,
                              subtitle: item.subject ?? 'General',
                              type: 'Task',
                              timeStr: 'Due Today',
                              color: _primaryBlue,
                              icon: Icons.checklist_rounded,
                              isDark: isDark,
                              completed: item.done,
                            )),
                        ...reminders.map((item) => _buildAcademicCard(
                              title: item.title,
                              subtitle: item.description,
                              type: 'Reminder',
                              timeStr: '${item.dueTime.hourOfPeriod}:${item.dueTime.minute.toString().padLeft(2, '0')} ${item.dueTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                              color: item.labelColor,
                              icon: Icons.alarm_rounded,
                              isDark: isDark,
                            )),
                      ],

                      // 4. Badges / Achievements Box
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('ACHIEVEMENTS', isDark),
                        Container(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: badges.length,
                            itemBuilder: (ctx, idx) {
                              final badge = badges[idx];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(badge.emoji, style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Text(
                                      badge.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMiniStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildAcademicCard({
    required String title,
    required String subtitle,
    required String type,
    required String timeStr,
    required Color color,
    required IconData icon,
    required bool isDark,
    bool completed = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left hand border strip (MyStudyLife signature styling)
              Container(width: 6, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: completed ? TextDecoration.lineThrough : null,
                          color: completed
                              ? Colors.grey
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWeekdayLetter(int weekday) {
    switch (weekday) {
      case 1: return 'M';
      case 2: return 'T';
      case 3: return 'W';
      case 4: return 'T';
      case 5: return 'F';
      case 6: return 'S';
      case 7: return 'S';
      default: return '';
    }
  }
}

class _Badge {
  final String emoji;
  final String label;
  _Badge(this.emoji, this.label);
}