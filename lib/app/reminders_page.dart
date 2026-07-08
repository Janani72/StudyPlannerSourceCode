import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';
import '../widgets/reminder_card.dart';
import '../theme/app_theme.dart';
import 'reminder_form_page.dart';
import 'app_widget.dart';

class RemindersPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;

  const RemindersPage({super.key, required this.parent});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  
  String _searchQuery = '';
  ReminderCategory? _categoryFilter;
  ReminderPriority? _priorityFilter;
  String _sortBy = 'date'; // 'date', 'priority', 'newest'

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<ReminderItem> _filterAndSort(List<ReminderItem> list) {
    var filtered = list.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _categoryFilter == null || item.category == _categoryFilter;
      final matchesPriority = _priorityFilter == null || item.priority == _priorityFilter;
      return matchesSearch && matchesCategory && matchesPriority;
    }).toList();

    if (_sortBy == 'date') {
      filtered.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    } else if (_sortBy == 'priority') {
      filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index)); // High (0) first
    } else if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    return filtered;
  }

  Widget _buildEmptyState(String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off_rounded,
            size: 80,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ReminderProvider>(
        builder: (context, provider, _) {
          if (!provider.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final todayFiltered = _filterAndSort(provider.todayReminders);
          final upcomingFiltered = _filterAndSort(provider.upcomingReminders);
          final completedFiltered = _filterAndSort(provider.completedRemindersList);
          final overdueFiltered = _filterAndSort(provider.overdueRemindersList);

          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Overview Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Completed',
                                value: '${provider.completedCount}/${provider.totalCount}',
                                icon: Icons.check_circle_rounded,
                                color: AppTheme.successColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Overdue',
                                value: '${provider.overdueCount}',
                                icon: Icons.error_outline_rounded,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Linear Progress Indicator
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Completion Rate',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${provider.completionPercentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: provider.completionPercentage > 50
                                          ? AppTheme.successColor
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: provider.completionPercentage / 100,
                                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                color: provider.completionPercentage > 50
                                    ? AppTheme.successColor
                                    : AppTheme.primaryColor,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search and Filter controls
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Search Reminders',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.sort_rounded),
                              tooltip: 'Sort by',
                              onSelected: (val) {
                                setState(() => _sortBy = val);
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'date', child: Text('Sort by Due Date')),
                                const PopupMenuItem(value: 'priority', child: Text('Sort by Priority')),
                                const PopupMenuItem(value: 'newest', child: Text('Sort by Newest')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Dropdown filter row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<ReminderCategory?>(
                                value: _categoryFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Category Filter',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                                  ...ReminderCategory.values.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() => _categoryFilter = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<ReminderPriority?>(
                                value: _priorityFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Priority Filter',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Priorities')),
                                  ...ReminderPriority.values.map((pri) {
                                    return DropdownMenuItem(
                                      value: pri,
                                      child: Text(pri.name.toUpperCase()),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() => _priorityFilter = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  toolbarHeight: 0,
                  bottom: TabBar(
                    controller: _tabCtrl,
                    indicatorColor: AppTheme.primaryColor,
                    labelColor: AppTheme.primaryColor,
                    tabs: const [
                      Tab(text: 'Today'),
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Overdue'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabCtrl,
                children: [
                  // 1. Today Tab
                  todayFiltered.isEmpty
                      ? _buildEmptyState('No reminders due today! 🎉')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: todayFiltered.length,
                          itemBuilder: (ctx, idx) => ReminderCard(
                            reminder: todayFiltered[idx],
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReminderFormPage(existingReminder: todayFiltered[idx]),
                              ),
                            ),
                          ),
                        ),

                  // 2. Upcoming Tab
                  upcomingFiltered.isEmpty
                      ? _buildEmptyState('No upcoming reminders.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: upcomingFiltered.length,
                          itemBuilder: (ctx, idx) => ReminderCard(
                            reminder: upcomingFiltered[idx],
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReminderFormPage(existingReminder: upcomingFiltered[idx]),
                              ),
                            ),
                          ),
                        ),

                  // 3. Overdue Tab
                  overdueFiltered.isEmpty
                      ? _buildEmptyState('Great! No overdue reminders.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: overdueFiltered.length,
                          itemBuilder: (ctx, idx) => ReminderCard(
                            reminder: overdueFiltered[idx],
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReminderFormPage(existingReminder: overdueFiltered[idx]),
                              ),
                            ),
                          ),
                        ),

                  // 4. Completed Tab
                  completedFiltered.isEmpty
                      ? _buildEmptyState('Completed reminders appear here.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: completedFiltered.length,
                          itemBuilder: (ctx, idx) => ReminderCard(
                            reminder: completedFiltered[idx],
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReminderFormPage(existingReminder: completedFiltered[idx]),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReminderFormPage()),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          );
        },
      );
  }
}
