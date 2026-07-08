import 'dart:convert';  // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageService {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLoggedIn = 'logged_in';
  static const String _keyUser = 'user';
  static const String _keySubjects = 'subjects';
  static const String _keyTasks = 'tasks';
  static const String _keyAssignments = 'assignments';
  static const String _keyExams = 'exams';
  static const String _keyNotes = 'notes';
  static const String _keyGoals = 'goals';
  static const String _keyPlannerItems = 'planner_items';
  static const String _keyAttendance = 'attendance';
  static const String _keyDailyStudy = 'daily_study';
  static const String _keyStreak = 'streak';
  static const String _keyXp = 'xp';

  // ============== Dark Mode ==============
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // ============== Auth ==============
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, value);
  }

  static Future<LocalUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyUser);
    if (json == null) return null;
    try {
      return LocalUser.fromJson(Map<String, dynamic>.from(jsonDecode(json)));
    } catch (e) {
      return null;
    }
  }

  static Future<void> setUser(LocalUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  // ============== Subjects ==============
  static Future<List<SubjectItem>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keySubjects);
    final list = decodeList(json);
    return list.map((e) => SubjectItem.fromJson(e)).toList();
  }

  static Future<void> setSubjects(List<SubjectItem> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySubjects, encodeList(subjects));
  }

  // ============== Tasks ==============
  static Future<List<StudyTask>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyTasks);
    final list = decodeList(json);
    return list.map((e) => StudyTask.fromJson(e)).toList();
  }

  static Future<void> setTasks(List<StudyTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTasks, encodeList(tasks));
  }

  // ============== Assignments ==============
  static Future<List<AssignmentItem>> getAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyAssignments);
    final list = decodeList(json);
    return list.map((e) => AssignmentItem.fromJson(e)).toList();
  }

  static Future<void> setAssignments(List<AssignmentItem> assignments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAssignments, encodeList(assignments));
  }

  // ============== Exams ==============
  static Future<List<ExamItem>> getExams() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyExams);
    final list = decodeList(json);
    return list.map((e) => ExamItem.fromJson(e)).toList();
  }

  static Future<void> setExams(List<ExamItem> exams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyExams, encodeList(exams));
  }

  // ============== Notes ==============
  static Future<List<NoteItem>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyNotes);
    final list = decodeList(json);
    return list.map((e) => NoteItem.fromJson(e)).toList();
  }

  static Future<void> setNotes(List<NoteItem> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotes, encodeList(notes));
  }

  // ============== Goals ==============
  static Future<List<GoalItem>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyGoals);
    final list = decodeList(json);
    return list.map((e) => GoalItem.fromJson(e)).toList();
  }

  static Future<void> setGoals(List<GoalItem> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoals, encodeList(goals));
  }

  // ============== Planner Items ==============
  static Future<List<PlannerItem>> getPlannerItems() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyPlannerItems);
    final list = decodeList(json);
    return list.map((e) => PlannerItem.fromJson(e)).toList();
  }

  static Future<void> setPlannerItems(List<PlannerItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlannerItems, encodeList(items));
  }

  // ============== Attendance ==============
  static Future<List<AttendanceRecord>> getAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyAttendance);
    final list = decodeList(json);
    return list.map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  static Future<void> setAttendance(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAttendance, encodeList(records));
  }

  // ============== Daily Study ==============
  static Future<List<DailyStudyRecord>> getDailyStudy() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyDailyStudy);
    final list = decodeList(json);
    return list.map((e) => DailyStudyRecord.fromJson(e)).toList();
  }

  static Future<void> setDailyStudy(List<DailyStudyRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDailyStudy, encodeList(records));
  }

  // ============== Streak ==============
  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }

  static Future<void> setStreak(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStreak, value);
  }

  // ============== XP ==============
  static Future<int> getXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyXp) ?? 0;
  }

  static Future<void> setXp(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyXp, value);
  }

  // ============== Clear All Data ==============
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}