import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_theme.dart';

class ReminderCard extends StatelessWidget {
  final ReminderItem reminder;
  final VoidRefCallback? onEdit;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onEdit,
  });

  IconData _getCategoryIcon(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.study:
        return Icons.menu_book_rounded;
      case ReminderCategory.assignment:
        return Icons.assignment_rounded;
      case ReminderCategory.exam:
        return Icons.event_note_rounded;
      case ReminderCategory.classSession:
        return Icons.school_rounded;
      case ReminderCategory.personal:
        return Icons.person_rounded;
      case ReminderCategory.other:
        return Icons.alarm_rounded;
    }
  }

  String _getCategoryLabel(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.study:
        return 'Study';
      case ReminderCategory.assignment:
        return 'Assignment';
      case ReminderCategory.exam:
        return 'Exam';
      case ReminderCategory.classSession:
        return 'Class';
      case ReminderCategory.personal:
        return 'Personal';
      case ReminderCategory.other:
        return 'Other';
    }
  }

  String _getPriorityLabel(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.high:
        return 'HIGH';
      case ReminderPriority.medium:
        return 'MED';
      case ReminderPriority.low:
        return 'LOW';
    }
  }

  Color _getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.high:
        return const Color(0xFFFF5252);
      case ReminderPriority.medium:
        return const Color(0xFFFFA726);
      case ReminderPriority.low:
        return const Color(0xFF29B6F6);
    }
  }

  String _getRepeatLabel(RepeatType repeat) {
    switch (repeat) {
      case RepeatType.oneTime:
        return 'One-time';
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekdays:
        return 'Weekdays';
      case RepeatType.weekly:
        return 'Weekly';
      case RepeatType.monthly:
        return 'Monthly';
      case RepeatType.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = reminder.labelColor;
    final scheduledDate = reminder.scheduledDateTime;
    final timeStr = '${reminder.dueTime.hourOfPeriod}:${reminder.dueTime.minute.toString().padLeft(2, '0')} ${reminder.dueTime.period == DayPeriod.am ? 'AM' : 'PM'}';
    final dateStr = '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
    final provider = Provider.of<ReminderProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left side vertical stripe (MyStudyLife style)
              Container(
                width: 8,
                color: catColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Category, Priority, and Checkbox
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(reminder.category),
                            size: 16,
                            color: catColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getCategoryLabel(reminder.category),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(reminder.priority).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getPriorityLabel(reminder.priority),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(reminder.priority),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Completion Switch
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: reminder.isCompleted,
                              activeColor: AppTheme.successColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                provider.toggleCompletion(reminder.id);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Title & Description
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                          color: reminder.isCompleted
                              ? Colors.grey
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (reminder.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Due Date, Time, Repeat Option
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 4),
                          Text(
                            '$dateStr at $timeStr',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.repeat_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 4),
                          Text(
                            _getRepeatLabel(reminder.repeat),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      // Attachment indication
                      if (reminder.attachmentPath != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.attach_file_rounded, size: 14, color: catColor),
                            const SizedBox(width: 4),
                            Text(
                              'Attachment included',
                              style: TextStyle(
                                fontSize: 11,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!reminder.isCompleted) ...[
                            // Snooze action popup menu
                            PopupMenuButton<Duration>(
                              icon: const Icon(Icons.snooze_rounded, size: 20),
                              tooltip: 'Snooze',
                              onSelected: (duration) {
                                provider.snoozeReminder(reminder.id, duration);
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: Duration(minutes: 5),
                                  child: Text('5 minutes'),
                                ),
                                const PopupMenuItem(
                                  value: Duration(minutes: 10),
                                  child: Text('10 minutes'),
                                ),
                                const PopupMenuItem(
                                  value: Duration(minutes: 30),
                                  child: Text('30 minutes'),
                                ),
                                const PopupMenuItem(
                                  value: Duration(hours: 1),
                                  child: Text('1 hour'),
                                ),
                              ],
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            tooltip: 'Duplicate',
                            onPressed: () {
                              provider.duplicateReminder(reminder.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            tooltip: 'Edit',
                            onPressed: onEdit,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            color: Colors.redAccent,
                            tooltip: 'Delete',
                            onPressed: () {
                              provider.deleteReminder(reminder.id);
                            },
                          ),
                        ],
                      ),
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
}

typedef VoidRefCallback = void Function();
