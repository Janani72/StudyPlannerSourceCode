import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_widget.dart';

class AnalyticsPage extends StatelessWidget {
  final SmartStudyPlannerAppState parent;
  const AnalyticsPage({super.key, required this.parent});

  Future<void> _exportPdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Smart Study Planner — Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('User: ${parent.user?.name ?? "Student"}'),
          pw.Text('Email: ${parent.user?.email ?? ""}'),
          pw.SizedBox(height: 8),
          pw.Text('📚 Subjects: ${parent.subjects.length}'),
          pw.Text('✅ Tasks: ${parent.tasks.length} '
              '(Completed: ${parent.tasks.where((t) => t.done).length})'),
          pw.Text('📋 Assignments: ${parent.assignments.length}'),
          pw.Text('🎓 Exams: ${parent.exams.length}'),
          pw.Text('📝 Notes: ${parent.notes.length}'),
          pw.Text('🎯 Goals: ${parent.goals.length} '
              '(Achieved: ${parent.goals.where((g) => g.done).length})'),
          pw.Text('🔥 Streak: ${parent.streak} days'),
          pw.Text('⭐ Total XP: ${parent.xp}'),
          pw.SizedBox(height: 12),
          pw.Text('📊 Productivity Score: ${_getProductivity().toStringAsFixed(0)}%'),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (PdfPageFormat f) async => pdf.save());
  }

  double _getProductivity() {
    final doneTasks = parent.tasks.where((t) => t.done).length;
    final totalTasks = parent.tasks.isEmpty ? 1 : parent.tasks.length;
    final doneGoals = parent.goals.where((g) => g.done).length;
    final totalGoals = parent.goals.isEmpty ? 1 : parent.goals.length;
    final taskScore = (doneTasks / totalTasks) * 40;
    final goalScore = (doneGoals / totalGoals) * 30;
    final studyScore = (parent.streak / 30).clamp(0, 1) * 30;
    return (taskScore + goalScore + studyScore).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskDone = parent.tasks.where((t) => t.done).length.toDouble();
    final taskPending = (parent.tasks.length - taskDone).clamp(0, double.infinity).toDouble();
    final productivity = _getProductivity();
    final totalSubjects = parent.subjects.length;
    final totalTasks = parent.tasks.length;
    final totalAssignments = parent.assignments.length;
    final totalExams = parent.exams.length;
    final totalNotes = parent.notes.length;
    final totalGoals = parent.goals.length;
    final achievedGoals = parent.goals.where((g) => g.done).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ============ PREMIUM HEADER ============
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F7FA),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Analytics',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      const Color(0xFF2D2D2D),
                      const Color(0xFF1A1A1A),
                    ]
                        : [
                      const Color(0xFFE8ECEF),
                      const Color(0xFFDEE2E6),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ============ CONTENT ============
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ============ PRODUCTIVITY SCORE CARD ============
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF2D2D2D),
                      ]
                          : [
                        Colors.white,
                        const Color(0xFFF8FAFC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4F8CFF),
                                    Color(0xFF6366F1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Productivity Score',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    'Based on tasks, goals, and study consistency',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${productivity.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: productivity >= 70
                                          ? const Color(0xFF10B981)
                                          : (productivity >= 40
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: productivity / 100,
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.grey.shade200,
                                      minHeight: 8,
                                      color: productivity >= 70
                                          ? const Color(0xFF10B981)
                                          : (productivity >= 40
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: productivity >= 70
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : (productivity >= 40
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    productivity >= 70
                                        ? Icons.emoji_events_rounded
                                        : (productivity >= 40
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded),
                                    color: productivity >= 70
                                        ? const Color(0xFF10B981)
                                        : (productivity >= 40
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444)),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    productivity >= 70
                                        ? 'Excellent!'
                                        : (productivity >= 40
                                        ? 'Keep Going!'
                                        : 'Needs Focus'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: productivity >= 70
                                          ? const Color(0xFF10B981)
                                          : (productivity >= 40
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFEF4444)),
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
                ),
                const SizedBox(height: 20),

                // ============ STATS GRID ============
                Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        context,
                        label: 'Subjects',
                        value: '$totalSubjects',
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF4F8CFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatsCard(
                        context,
                        label: 'Tasks',
                        value: '$totalTasks',
                        icon: Icons.task_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        context,
                        label: 'Assignments',
                        value: '$totalAssignments',
                        icon: Icons.assignment_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatsCard(
                        context,
                        label: 'Exams',
                        value: '$totalExams',
                        icon: Icons.event_rounded,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        context,
                        label: 'Notes',
                        value: '$totalNotes',
                        icon: Icons.sticky_note_2_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatsCard(
                        context,
                        label: 'Goals Achieved',
                        value: '$achievedGoals / $totalGoals',
                        icon: Icons.flag_rounded,
                        color: const Color(0xFFEC4899),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ============ TASK COMPLETION CHART ============
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF2D2D2D),
                      ]
                          : [
                        Colors.white,
                        const Color(0xFFF8FAFC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF34D399),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.pie_chart_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Task Completion Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: taskDone == 0 ? 1 : taskDone,
                                  title: '✅ Done',
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  color: const Color(0xFF10B981),
                                  radius: 60,
                                ),
                                PieChartSectionData(
                                  value: taskPending == 0 ? 1 : taskPending,
                                  title: '⏳ Pending',
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  color: const Color(0xFFF59E0B),
                                  radius: 60,
                                ),
                              ],
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(
                              color: const Color(0xFF10B981),
                              label: 'Completed (${taskDone.toInt()})',
                            ),
                            const SizedBox(width: 24),
                            _buildLegendItem(
                              color: const Color(0xFFF59E0B),
                              label: 'Pending (${taskPending.toInt()})',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ============ CATEGORY BAR CHART ============
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF2D2D2D),
                      ]
                          : [
                        Colors.white,
                        const Color(0xFFF8FAFC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4F8CFF),
                                    Color(0xFF6366F1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Items by Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(
                                    toY: totalSubjects.toDouble(),
                                    color: const Color(0xFF4F8CFF),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(
                                    toY: totalTasks.toDouble(),
                                    color: const Color(0xFF10B981),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ]),
                                BarChartGroupData(x: 2, barRods: [
                                  BarChartRodData(
                                    toY: totalAssignments.toDouble(),
                                    color: const Color(0xFFF59E0B),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ]),
                                BarChartGroupData(x: 3, barRods: [
                                  BarChartRodData(
                                    toY: totalExams.toDouble(),
                                    color: const Color(0xFFEF4444),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ]),
                                BarChartGroupData(x: 4, barRods: [
                                  BarChartRodData(
                                    toY: totalNotes.toDouble(),
                                    color: const Color(0xFF8B5CF6),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ]),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      const labels = ['Subjects', 'Tasks', 'Assign', 'Exams', 'Notes'];
                                      final i = v.toInt();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          i >= 0 && i < labels.length ? labels[i] : '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.shade200,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ============ EXPORT BUTTON ============
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF2D2D2D),
                      ]
                          : [
                        Colors.white,
                        const Color(0xFFF8FAFC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _exportPdf(context),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text(
                          '📄 Export Full Report as PDF',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF4F8CFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
      BuildContext context, {
        required String label,
        required String value,
        required IconData icon,
        required Color color,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF1A1A2E),
            const Color(0xFF2D2D2D),
          ]
              : [
            Colors.white,
            const Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}