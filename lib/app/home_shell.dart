import 'package:flutter/material.dart';
import 'app_widget.dart';
import '../theme/app_theme.dart';
import 'dribbble_style_home.dart';
import 'calendar_page.dart';
import 'subjects_page.dart';
import 'tasks_page.dart';
import 'assignments_page.dart';
import 'exams_page.dart';
import 'notes_page.dart';
import 'goals_page.dart';
import 'analytics_page.dart';
import 'settings_page.dart';
import '../features.dart';
import 'ai_planner_page.dart';
import 'ai_quiz_page.dart';
import 'ai_summarizer_page.dart';
import 'study_planner_page.dart';
import 'profile_page.dart';
import 'reminders_page.dart';

class HomeShell extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const HomeShell({super.key, required this.parent});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int idx = 0;

  String createId() => DateTime.now().millisecondsSinceEpoch.toString();

  void showMsg(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> saveAndRefresh() async {
    await widget.parent.saveAll();
    if (mounted) setState(() {});
  }

  void navigateTo(int index) {
    setState(() => idx = index);
  }

  List<NavItem> get navItems => [
    NavItem('Home', Icons.dashboard_rounded, DribbbleStyleHome(parent: widget.parent)),
    NavItem('Calendar', Icons.calendar_month_rounded, CalendarPage(parent: widget.parent)),
    NavItem('Subjects', Icons.menu_book_rounded, SubjectsPage(parent: widget.parent)),
    NavItem('Tasks', Icons.checklist_rounded, TasksPage(parent: widget.parent)),
    NavItem('Reminders', Icons.alarm_rounded, RemindersPage(parent: widget.parent)),
    // ✅ CHANGED: 'Assign' → 'Assignments'
    NavItem('Assignments', Icons.assignment_rounded, AssignmentsPage(parent: widget.parent)),
    NavItem('Exams', Icons.event_note_rounded, ExamsPage(parent: widget.parent)),
    NavItem('Notes', Icons.sticky_note_2_rounded, NotesPage(parent: widget.parent)),
    NavItem('Goals', Icons.flag_rounded, GoalsPage(parent: widget.parent)),
    // ✅ CHANGED: 'Stats' → 'Statistics'
    NavItem('Statistics', Icons.analytics_rounded, AnalyticsPage(parent: widget.parent)),
    NavItem('Weekly', Icons.view_week_rounded, WeeklyPlannerPage(
      planner: widget.parent.plannerItems,
      onChanged: saveAndRefresh,
      createId: createId,
      showMsg: showMsg,
    )),
    NavItem('Monthly', Icons.calendar_view_month_rounded, MonthlyPlannerPage(
      planner: widget.parent.plannerItems,
      onChanged: saveAndRefresh,
      createId: createId,
      showMsg: showMsg,
    )),
    NavItem('Timers', Icons.timer_rounded, const TimersPage()),
    NavItem('Attendance', Icons.fact_check_rounded, AttendancePage(
      attendance: widget.parent.attendance,
      dailyStudy: widget.parent.dailyStudy,
      onChanged: saveAndRefresh,
      showMsg: showMsg,
    )),
    NavItem('Reports', Icons.insights_rounded, ReportsPage(
      dailyStudy: widget.parent.dailyStudy,
      tasks: widget.parent.tasks,
      goals: widget.parent.goals,
      xp: widget.parent.xp,
      streak: widget.parent.streak,
    )),
    NavItem('Progress', Icons.trending_up_rounded, SubjectProgressPage(
      subjects: widget.parent.subjects,
      tasks: widget.parent.tasks,
      assignments: widget.parent.assignments,
    )),
    NavItem('Profile', Icons.person_rounded, ProfilePage(parent: widget.parent)),
    NavItem('Settings', Icons.settings_rounded, SettingsPage(parent: widget.parent)),
    NavItem('AI Planner', Icons.psychology_rounded, AIPlannerPage(parent: widget.parent)),
    NavItem('AI Quiz', Icons.quiz_rounded, const AIQuizPage()),
    NavItem('AI Summarizer', Icons.summarize_rounded, const AISummarizerPage()),
    NavItem('Study Planner', Icons.calendar_month_rounded, StudyPlannerPage(parent: widget.parent)),
  ];

  @override
  Widget build(BuildContext context) {
    final items = navItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(items[idx].label),
        actions: [
          IconButton(
            icon: Icon(
              widget.parent.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              widget.parent.toggleDark(!widget.parent.dark);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryLight,
                      AppTheme.secondaryColor,
                    ],
                  ),
                ),
                child: UserAccountsDrawerHeader(
                  accountName: Text(
                    widget.parent.user?.name ?? 'Student',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  accountEmail: Text(
                    widget.parent.user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      (widget.parent.user?.name ?? 'S')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final isSelected = i == idx;
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        setState(() => idx = i);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: Color(0xFFFF6B6B)),
                ),
                onTap: widget.parent.onLogout,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: items[idx].page,
    );
  }
}

class NavItem {
  final String label;
  final IconData icon;
  final Widget page;

  NavItem(this.label, this.icon, this.page);
}