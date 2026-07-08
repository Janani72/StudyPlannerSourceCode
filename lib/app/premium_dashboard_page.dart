import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_card.dart';
import '../widgets/premium_dashboard_card.dart';
import '../widgets/premium_header.dart';
import 'app_widget.dart';

class PremiumDashboardPage extends StatelessWidget {
  final SmartStudyPlannerAppState parent;
  const PremiumDashboardPage({super.key, required this.parent});

  int _getLevel(int xp) => (xp ~/ 100) + 1;
  int _getXpToNext(int xp) => 100 - (xp % 100);

  double _getProductivity(SmartStudyPlannerAppState parent) {
    final doneTasks = parent.tasks.where((t) => t.done).length;
    final totalTasks = parent.tasks.isEmpty ? 1 : parent.tasks.length;
    final taskScore = (doneTasks / totalTasks) * 50;
    final studyScore = (parent.streak / 30).clamp(0, 1) * 50;
    return (taskScore + studyScore).clamp(0, 100);
  }

  List<Map<String, dynamic>> _getTodaySchedule(SmartStudyPlannerAppState parent) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTasks = parent.tasks.where((t) {
      if (t.due == null) return false;
      return t.due!.year == today.year &&
          t.due!.month == today.month &&
          t.due!.day == today.day &&
          !t.done;
    }).take(3).toList();

    final schedule = <Map<String, dynamic>>[];

    for (var task in todayTasks) {
      schedule.add({
        'title': task.title,
        'type': 'Task',
        'time': 'Due today',
        'color': AppTheme.primaryColor,
      });
    }

    if (schedule.isEmpty) {
      schedule.add({
        'title': 'No tasks scheduled for today',
        'type': 'Free',
        'time': 'Enjoy your day! 🎉',
        'color': Colors.grey,
      });
    }

    return schedule;
  }

  List<_Badge> _getBadges(SmartStudyPlannerAppState parent) {
    final list = <_Badge>[];
    if (parent.streak >= 3) list.add(_Badge('🔥', '3-day streak'));
    if (parent.streak >= 7) list.add(_Badge('🏆', '7-day streak'));
    if (parent.streak >= 30) list.add(_Badge('💎', '30-day streak'));
    if (parent.tasks.where((t) => t.done).length >= 5) {
      list.add(_Badge('✅', '5 tasks done'));
    }
    if (parent.xp >= 100) list.add(_Badge('🥉', 'Level 2'));
    if (parent.xp >= 500) list.add(_Badge('🥈', 'Level 5+'));
    if (parent.xp >= 1000) list.add(_Badge('🥇', 'Level 10+'));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Smart Study Planner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Welcome back, ${parent.user?.name ?? 'Student'}!',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGradientStart,
                      AppTheme.primaryGradientEnd,
                    ],
                  ),
                ),
                child: const SizedBox(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // XP & Level Card
                PremiumCard(
                  glass: true,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${_getLevel(parent.xp)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level ${_getLevel(parent.xp)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${parent.xp} XP • ${_getXpToNext(parent.xp)} to next level',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ((parent.xp % 100) / 100),
                                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    PremiumDashboardCard(
                      title: 'Pending Tasks',
                      value: '${parent.tasks.where((t) => !t.done).length}',
                      icon: Icons.check_circle_rounded,
                      iconColor: AppTheme.primaryColor,
                      progress: parent.tasks.isEmpty ? 0 :
                      parent.tasks.where((t) => t.done).length / parent.tasks.length,
                      progressColor: AppTheme.primaryColor,
                    ),
                    PremiumDashboardCard(
                      title: 'Study Streak',
                      value: '${parent.streak} days',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.orange,
                      trend: parent.streak > 0 ? '+${parent.streak}' : null,
                      trendColor: Colors.orange,
                    ),
                    PremiumDashboardCard(
                      title: 'Upcoming Exams',
                      value: '${parent.exams.where((e) => e.date.isAfter(DateTime.now())).length}',
                      icon: Icons.event_rounded,
                      iconColor: Colors.red,
                    ),
                    PremiumDashboardCard(
                      title: 'Productivity Score',
                      value: '${_getProductivity(parent).toStringAsFixed(0)}%',
                      icon: Icons.analytics_rounded,
                      iconColor: Colors.green,
                      progress: _getProductivity(parent) / 100,
                      progressColor: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Today's Schedule
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PremiumHeader(
                        title: 'Today\'s Schedule',
                        subtitle: 'Your study plan for today',
                        trailing: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._getTodaySchedule(parent).map((item) => _buildScheduleItem(item)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Actions
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PremiumHeader(
                        title: 'Quick Actions',
                        subtitle: 'Start something new',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildQuickAction(
                            context,
                            icon: Icons.add_task_rounded,
                            label: 'New Task',
                            color: AppTheme.primaryColor,
                          ),
                          _buildQuickAction(
                            context,
                            icon: Icons.timer_rounded,
                            label: 'Pomodoro',
                            color: Colors.orange,
                          ),
                          _buildQuickAction(
                            context,
                            icon: Icons.auto_awesome_rounded,
                            label: 'AI Planner',
                            color: Colors.purple,
                          ),
                          _buildQuickAction(
                            context,
                            icon: Icons.quiz_rounded,
                            label: 'AI Quiz',
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Achievement Badges
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PremiumHeader(
                        title: 'Achievements',
                        subtitle: 'Keep up the great work!',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _getBadges(parent).map((badge) =>
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    badge.icon,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    badge.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ).toList(),
                      ),
                      if (_getBadges(parent).isEmpty)
                        const Text(
                          'No badges yet. Keep studying to unlock achievements! 🚀',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: item['color'] as Color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(
        item['title'] as String,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        item['time'] as String,
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (item['color'] as Color).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          item['type'] as String,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: item['color'] as Color,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge {
  final String icon;
  final String label;
  _Badge(this.icon, this.label);
}