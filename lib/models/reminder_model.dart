import 'package:flutter/material.dart';

enum ReminderCategory {
  study,
  assignment,
  exam,
  classSession,
  personal,
  other
}

enum ReminderPriority {
  high,
  medium,
  low
}

enum RepeatType {
  oneTime,
  daily,
  weekdays,
  weekly,
  monthly,
  custom
}

class ReminderItem {
  final String id;
  final String title;
  final String description;
  final ReminderCategory category;
  final DateTime dueDate;
  final TimeOfDay dueTime;
  final ReminderPriority priority;
  final Color labelColor;
  final String? attachmentPath;
  final RepeatType repeat;
  final int preDueMinutes; // e.g. 5, 15, 30, 60
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? snoozedUntil;

  ReminderItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dueDate,
    required this.dueTime,
    required this.priority,
    required this.labelColor,
    this.attachmentPath,
    required this.repeat,
    required this.preDueMinutes,
    this.isCompleted = false,
    this.completedAt,
    this.snoozedUntil,
  });

  DateTime get scheduledDateTime {
    final base = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      dueTime.hour,
      dueTime.minute,
    );
    if (snoozedUntil != null && snoozedUntil!.isAfter(DateTime.now())) {
      return snoozedUntil!;
    }
    return base;
  }

  bool get isOverdue {
    if (isCompleted) return false;
    return scheduledDateTime.isBefore(DateTime.now());
  }

  ReminderItem copyWith({
    String? id,
    String? title,
    String? description,
    ReminderCategory? category,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    ReminderPriority? priority,
    Color? labelColor,
    String? attachmentPath,
    RepeatType? repeat,
    int? preDueMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? snoozedUntil,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      labelColor: labelColor ?? this.labelColor,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      repeat: repeat ?? this.repeat,
      preDueMinutes: preDueMinutes ?? this.preDueMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'dueDate': dueDate.toIso8601String(),
      'dueHour': dueTime.hour,
      'dueMinute': dueTime.minute,
      'priority': priority.name,
      'labelColorValue': labelColor.value,
      'attachmentPath': attachmentPath,
      'repeat': repeat.name,
      'preDueMinutes': preDueMinutes,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'snoozedUntil': snoozedUntil?.toIso8601String(),
    };
  }

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: ReminderCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ReminderCategory.other,
      ),
      dueDate: DateTime.parse(json['dueDate'] as String),
      dueTime: TimeOfDay(
        hour: json['dueHour'] as int? ?? 12,
        minute: json['dueMinute'] as int? ?? 0,
      ),
      priority: ReminderPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => ReminderPriority.medium,
      ),
      labelColor: Color(json['labelColorValue'] as int? ?? 0xFF7C4DFF),
      attachmentPath: json['attachmentPath'] as String?,
      repeat: RepeatType.values.firstWhere(
        (r) => r.name == json['repeat'],
        orElse: () => RepeatType.oneTime,
      ),
      preDueMinutes: json['preDueMinutes'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.parse(json['snoozedUntil'] as String)
          : null,
    );
  }
}
