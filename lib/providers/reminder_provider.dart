import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  late Box _reminderBox;
  List<ReminderItem> _reminders = [];
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<ReminderItem> get reminders => _reminders;

  // Statistics
  int get totalCount => _reminders.length;
  int get completedCount => _reminders.where((r) => r.isCompleted).length;
  int get pendingCount => _reminders.where((r) => !r.isCompleted).length;
  int get overdueCount => _reminders.where((r) => r.isOverdue).length;
  
  double get completionPercentage {
    if (_reminders.isEmpty) return 0.0;
    return (completedCount / totalCount) * 100.0;
  }

  // Filtered views
  List<ReminderItem> get todayReminders {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return _reminders.where((r) {
      final scheduled = r.scheduledDateTime;
      return scheduled.isAfter(todayStart) && scheduled.isBefore(todayEnd) && !r.isCompleted;
    }).toList();
  }

  List<ReminderItem> get upcomingReminders {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return _reminders.where((r) {
      final scheduled = r.scheduledDateTime;
      return scheduled.isAfter(todayEnd) && !r.isCompleted;
    }).toList();
  }

  List<ReminderItem> get completedRemindersList {
    return _reminders.where((r) => r.isCompleted).toList();
  }

  List<ReminderItem> get overdueRemindersList {
    return _reminders.where((r) => r.isOverdue).toList();
  }

  ReminderProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    _reminderBox = await Hive.openBox('reminders_box');
    _loadReminders();
    _initialized = true;
    notifyListeners();
  }

  void _loadReminders() {
    final List<ReminderItem> loaded = [];
    for (var key in _reminderBox.keys) {
      final raw = _reminderBox.get(key);
      if (raw != null) {
        try {
          // Parse dynamic map safely
          final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(raw as Map);
          loaded.add(ReminderItem.fromJson(jsonMap));
        } catch (e) {
          debugPrint('Error loading reminder key $key: $e');
        }
      }
    }
    
    // Sort initially by date/time ascending
    loaded.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    _reminders = loaded;
  }

  Future<void> addReminder(ReminderItem item) async {
    await _reminderBox.put(item.id, item.toJson());
    _loadReminders();
    await NotificationService.scheduleReminderNotifications(item);
    notifyListeners();
  }

  Future<void> updateReminder(ReminderItem item) async {
    await _reminderBox.put(item.id, item.toJson());
    _loadReminders();
    await NotificationService.scheduleReminderNotifications(item);
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    await _reminderBox.delete(id);
    _loadReminders();
    await NotificationService.cancelReminderNotifications(id);
    notifyListeners();
  }

  Future<void> toggleCompletion(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final oldItem = _reminders[index];
      final newItem = oldItem.copyWith(
        isCompleted: !oldItem.isCompleted,
        completedAt: !oldItem.isCompleted ? DateTime.now() : null,
        snoozedUntil: null, // Clear snooze on manual complete/incomplete
      );
      
      await _reminderBox.put(newItem.id, newItem.toJson());
      _loadReminders();
      
      if (newItem.isCompleted) {
        await NotificationService.cancelReminderNotifications(newItem.id);
      } else {
        await NotificationService.scheduleReminderNotifications(newItem);
      }
      notifyListeners();
    }
  }

  Future<void> snoozeReminder(String id, Duration duration) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final oldItem = _reminders[index];
      final newSnoozeTime = DateTime.now().add(duration);
      final newItem = oldItem.copyWith(
        snoozedUntil: newSnoozeTime,
      );
      
      await _reminderBox.put(newItem.id, newItem.toJson());
      _loadReminders();
      await NotificationService.scheduleReminderNotifications(newItem);
      notifyListeners();
    }
  }

  Future<void> duplicateReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final original = _reminders[index];
      final duplicate = original.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${original.title} (Copy)',
        isCompleted: false,
        completedAt: null,
        snoozedUntil: null,
      );
      await addReminder(duplicate);
    }
  }
}
