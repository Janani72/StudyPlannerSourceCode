import 'dart:convert';

enum ColorTag { blue, green, orange, purple, red }

enum RecurringType { none, daily, weekly, monthly }

enum SubjectPriority { low, medium, high, veryHigh }

ColorTag _colorFrom(dynamic value) {
  if (value is int && value >= 0 && value < ColorTag.values.length) {
    return ColorTag.values[value];
  }

  if (value is String) {
    return ColorTag.values.firstWhere(
          (e) => e.name == value,
      orElse: () => ColorTag.blue,
    );
  }

  return ColorTag.blue;
}

RecurringType _recurringFrom(dynamic value) {
  if (value is int && value >= 0 && value < RecurringType.values.length) {
    return RecurringType.values[value];
  }

  if (value is String) {
    return RecurringType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => RecurringType.none,
    );
  }

  return RecurringType.none;
}

// ==================== LOCAL USER ====================
class LocalUser {
  String name;
  String email;
  String password;
  String? uid;
  int xp;
  int streak;
  String? profilePicture;

  LocalUser({
    required this.name,
    required this.email,
    this.password = '',
    this.uid,
    this.xp = 0,
    this.streak = 0,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'uid': uid,
    'xp': xp,
    'streak': streak,
    'profilePicture': profilePicture,
  };

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      name: json['name'] ?? 'Student',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      uid: json['uid'],
      xp: json['xp'] ?? 0,
      streak: json['streak'] ?? 0,
      profilePicture: json['profilePicture'],
    );
  }
}
// ==================== SUBJECT ITEM ====================
class SubjectItem {
  String id;
  String name;
  ColorTag color;
  SubjectPriority priority;
  String? description;
  int studyHoursPerWeek;
  List<String>? topics;

  SubjectItem({
    required this.id,
    required this.name,
    this.color = ColorTag.blue,
    this.priority = SubjectPriority.medium,
    this.description,
    this.studyHoursPerWeek = 2,
    this.topics,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.index,
    'priority': priority.index,
    'description': description,
    'studyHoursPerWeek': studyHoursPerWeek,
    'topics': topics,
  };

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      color: _colorFrom(json['color']),
      priority: SubjectPriority.values[json['priority'] ?? 1],
      description: json['description'],
      studyHoursPerWeek: json['studyHoursPerWeek'] ?? 2,
      topics: json['topics'] != null ? List<String>.from(json['topics']) : null,
    );
  }
}

// ==================== STUDY TASK ====================
class StudyTask {
  String id;
  String title;
  String? description;
  String? subject;
  String? category;
  DateTime? due;
  TaskPriority priority;
  TaskStatus status;
  bool done;
  String? colorLabel;

  StudyTask({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    this.category,
    this.due,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.done = false,
    this.colorLabel,
  });

  // Getters for backward compatibility
  bool get completed => done;
  set completed(bool value) => done = value;
  DateTime? get dueDate => due;
  set dueDate(DateTime? value) => due = value;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'subject': subject,
    'category': category,
    'due': due?.toIso8601String(),
    'priority': priority.index,
    'status': status.index,
    'done': done,
    'colorLabel': colorLabel,
  };

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      description: json['description'],
      subject: json['subject'],
      category: json['category'],
      due: json['due'] == null ? null : DateTime.tryParse(json['due']),
      priority: TaskPriority.values[json['priority'] ?? 1],
      status: TaskStatus.values[json['status'] ?? 0],
      done: json['done'] ?? false,
      colorLabel: json['colorLabel'],
    );
  }
}

// ==================== TASK ENUMS ====================
enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

// ==================== ASSIGNMENT ITEM ====================
class AssignmentItem {
  String id;
  String title;
  String subject;
  DateTime due;

  AssignmentItem({
    required this.id,
    required this.title,
    this.subject = '',
    DateTime? due,
    DateTime? dueDate,
    DateTime? deadline,
  }) : due = due ?? dueDate ?? deadline ?? DateTime.now();

  DateTime get dueDate => due;
  set dueDate(DateTime value) => due = value;

  DateTime get deadline => due;
  set deadline(DateTime value) => due = value;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'due': due.toIso8601String(),
    'dueDate': due.toIso8601String(),
    'deadline': due.toIso8601String(),
  };

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    final dateText = json['due'] ?? json['dueDate'] ?? json['deadline'];

    return AssignmentItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      due: dateText == null ? DateTime.now() : DateTime.tryParse(dateText),
    );
  }
}

// ==================== EXAM ITEM ====================
class ExamItem {
  String id;
  String title;
  String subject;
  DateTime date;

  ExamItem({
    required this.id,
    required this.title,
    this.subject = '',
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'date': date.toIso8601String(),
  };

  factory ExamItem.fromJson(Map<String, dynamic> json) {
    return ExamItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      date: json['date'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['date']) ?? DateTime.now(),
    );
  }
}

// ==================== NOTE ITEM ====================
class NoteItem {
  String id;
  String title;
  String body;
  DateTime createdAt;

  NoteItem({
    required this.id,
    required this.title,
    String? body,
    String? content,
    DateTime? createdAt,
  })  : body = body ?? content ?? '',
        createdAt = createdAt ?? DateTime.now();

  String get content => body;
  set content(String value) => body = value;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'content': body,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      body: json['body'] ?? json['content'] ?? '',
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
    );
  }
}

// ==================== GOAL ITEM ====================
class GoalItem {
  String id;
  String title;
  bool done;

  GoalItem({
    required this.id,
    required this.title,
    bool? done,
    bool? completed,
  }) : done = done ?? completed ?? false;

  bool get completed => done;
  set completed(bool value) => done = value;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'completed': done,
  };

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      done: json['done'],
      completed: json['completed'],
    );
  }
}

// ==================== PLANNER ITEM ====================
class PlannerItem {
  String id;
  String title;
  String subject;
  DateTime date;
  bool completed;
  RecurringType recurring;

  PlannerItem({
    required this.id,
    required this.title,
    this.subject = '',
    required this.date,
    this.completed = false,
    this.recurring = RecurringType.none,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'date': date.toIso8601String(),
    'completed': completed,
    'recurring': recurring.index,
  };

  factory PlannerItem.fromJson(Map<String, dynamic> json) {
    return PlannerItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      date: json['date'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['date']) ?? DateTime.now(),
      completed: json['completed'] ?? false,
      recurring: _recurringFrom(json['recurring']),
    );
  }
}

// ==================== ATTENDANCE RECORD ====================
class AttendanceRecord {
  String id;
  String subject;
  DateTime date;
  bool present;

  AttendanceRecord({
    required this.id,
    this.subject = '',
    required this.date,
    bool? present,
    bool? attended,
  }) : present = present ?? attended ?? true;

  bool get attended => present;
  set attended(bool value) => present = value;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'date': date.toIso8601String(),
    'present': present,
    'attended': present,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      subject: json['subject'] ?? '',
      date: json['date'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['date']) ?? DateTime.now(),
      present: json['present'],
      attended: json['attended'],
    );
  }
}

// ==================== DAILY STUDY RECORD ====================
class DailyStudyRecord {
  DateTime date;
  int minutes;

  DailyStudyRecord({
    required this.date,
    int? minutes,
    int? totalMinutes,
    int? studyMinutes,
  }) : minutes = minutes ?? totalMinutes ?? studyMinutes ?? 0;

  int get totalMinutes => minutes;
  set totalMinutes(int value) => minutes = value;

  int get studyMinutes => minutes;
  set studyMinutes(int value) => minutes = value;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'minutes': minutes,
    'totalMinutes': minutes,
    'studyMinutes': minutes,
  };

  factory DailyStudyRecord.fromJson(Map<String, dynamic> json) {
    return DailyStudyRecord(
      date: json['date'] == null
          ? DateTime.now()
          : DateTime.tryParse(json['date']) ?? DateTime.now(),
      minutes: json['minutes'],
      totalMinutes: json['totalMinutes'],
      studyMinutes: json['studyMinutes'],
    );
  }
}

// ==================== UTILITY FUNCTIONS ====================
Map<String, dynamic> _toMap(dynamic item) {
  if (item is Map<String, dynamic>) return item;
  if (item is Map) return Map<String, dynamic>.from(item);
  return Map<String, dynamic>.from(item.toJson());
}

String encodeList(List<dynamic> list) {
  return jsonEncode(list.map(_toMap).toList());
}

List<Map<String, dynamic>> decodeList(String? source) {
  if (source == null || source.trim().isEmpty) return [];

  final decoded = jsonDecode(source);

  if (decoded is! List) return [];

  return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
}