import 'dart:convert';
import 'package:flutter/material.dart';
import '../models.dart';
import '../storage_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'home_shell.dart';
import 'landing_page.dart';

class SmartStudyPlannerAppCore extends StatefulWidget {
  const SmartStudyPlannerAppCore({super.key});

  @override
  State<SmartStudyPlannerAppCore> createState() => SmartStudyPlannerAppState();
}

class SmartStudyPlannerAppState extends State<SmartStudyPlannerAppCore> {
  bool dark = false;
  bool loggedIn = false;
  LocalUser? user;
  bool loading = true;

  // Data
  List<SubjectItem> subjects = [];
  List<StudyTask> tasks = [];
  List<AssignmentItem> assignments = [];
  List<ExamItem> exams = [];
  List<NoteItem> notes = [];
  List<GoalItem> goals = [];
  List<PlannerItem> plannerItems = [];
  List<AttendanceRecord> attendance = [];
  List<DailyStudyRecord> dailyStudy = [];
  int streak = 0;
  int xp = 0;

  @override
  void initState() {
    super.initState();
    loadApp();
  }

  Future<void> loadApp() async {
    dark = await StorageService.getDarkMode();

    // Use AuthService for login state
    loggedIn = await AuthService.isLoggedIn();
    user = await AuthService.getCurrentUser();

    // Instant cache-first loading from local storage
    await _loadFromLocalStorage();
    streak = await StorageService.getStreak();
    xp = await StorageService.getXp();

    // Dismiss the full screen loader instantly
    setState(() => loading = false);

    // Fetch and sync Firestore in the background
    final uid = AuthService.currentUid;
    if (loggedIn && uid != null) {
      _fetchAndSyncFirestore(uid);
    }
  }

  Future<void> _fetchAndSyncFirestore(String uid) async {
    try {
      final results = await Future.wait([
        FirestoreService.getCollection<SubjectItem>(
          uid: uid,
          collectionName: 'subjects',
          fromJson: SubjectItem.fromJson,
        ),
        FirestoreService.getCollection<StudyTask>(
          uid: uid,
          collectionName: 'tasks',
          fromJson: StudyTask.fromJson,
        ),
        FirestoreService.getCollection<AssignmentItem>(
          uid: uid,
          collectionName: 'assignments',
          fromJson: AssignmentItem.fromJson,
        ),
        FirestoreService.getCollection<ExamItem>(
          uid: uid,
          collectionName: 'exams',
          fromJson: ExamItem.fromJson,
        ),
        FirestoreService.getCollection<NoteItem>(
          uid: uid,
          collectionName: 'notes',
          fromJson: NoteItem.fromJson,
        ),
        FirestoreService.getCollection<GoalItem>(
          uid: uid,
          collectionName: 'goals',
          fromJson: GoalItem.fromJson,
        ),
        FirestoreService.getCollection<PlannerItem>(
          uid: uid,
          collectionName: 'planner_items',
          fromJson: PlannerItem.fromJson,
        ),
        FirestoreService.getCollection<AttendanceRecord>(
          uid: uid,
          collectionName: 'attendance',
          fromJson: AttendanceRecord.fromJson,
        ),
        FirestoreService.getCollection<DailyStudyRecord>(
          uid: uid,
          collectionName: 'daily_study',
          fromJson: DailyStudyRecord.fromJson,
        ),
      ]);

      final fetchedSubjects = results[0] as List<SubjectItem>;
      final fetchedTasks = results[1] as List<StudyTask>;
      final fetchedAssignments = results[2] as List<AssignmentItem>;
      final fetchedExams = results[3] as List<ExamItem>;
      final fetchedNotes = results[4] as List<NoteItem>;
      final fetchedGoals = results[5] as List<GoalItem>;
      final fetchedPlannerItems = results[6] as List<PlannerItem>;
      final fetchedAttendance = results[7] as List<AttendanceRecord>;
      final fetchedDailyStudy = results[8] as List<DailyStudyRecord>;

      // If remote database is empty (new signup), sync local collections to cloud.
      // Otherwise, overwrite local memory and cache database files with remote data.
      if (fetchedSubjects.isEmpty && fetchedTasks.isEmpty && fetchedAssignments.isEmpty && fetchedNotes.isEmpty) {
        await _syncAllToFirestore(uid);
      } else {
        subjects = fetchedSubjects;
        tasks = fetchedTasks;
        assignments = fetchedAssignments;
        exams = fetchedExams;
        notes = fetchedNotes;
        goals = fetchedGoals;
        plannerItems = fetchedPlannerItems;
        attendance = fetchedAttendance;
        dailyStudy = fetchedDailyStudy;

        await _saveToLocalStorage();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Firestore background database sync error: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    subjects = await StorageService.getSubjects();
    tasks = await StorageService.getTasks();
    assignments = await StorageService.getAssignments();
    exams = await StorageService.getExams();
    notes = await StorageService.getNotes();
    goals = await StorageService.getGoals();
    plannerItems = await StorageService.getPlannerItems();
    attendance = await StorageService.getAttendance();
    dailyStudy = await StorageService.getDailyStudy();
  }

  Future<void> _saveToLocalStorage() async {
    await Future.wait([
      StorageService.setSubjects(subjects),
      StorageService.setTasks(tasks),
      StorageService.setAssignments(assignments),
      StorageService.setExams(exams),
      StorageService.setNotes(notes),
      StorageService.setGoals(goals),
      StorageService.setPlannerItems(plannerItems),
      StorageService.setAttendance(attendance),
      StorageService.setDailyStudy(dailyStudy),
    ]);
  }

  Future<void> _syncAllToFirestore(String uid) async {
    await Future.wait([
      FirestoreService.syncCollection<SubjectItem>(
        uid: uid,
        collectionName: 'subjects',
        items: subjects,
        getId: (item) => item.id,
        toJson: (item) => item.toJson(),
      ),
      FirestoreService.syncCollection<StudyTask>(
        uid: uid,
        collectionName: 'tasks',
        items: tasks,
        getId: (item) => item.id,
        toJson: (item) => item.toJson(),
      ),
      FirestoreService.syncCollection<AssignmentItem>(
        uid: uid,
        collectionName: 'assignments',
        items: assignments,
        getId: (item) => item.id,
        toJson: (item) => item.toJson(),
      ),
      FirestoreService.syncCollection<ExamItem>(
        uid: uid,
        collectionName: 'exams',
        items: exams,
        getId: (item) => item.id,
        toJson: (item) => item.toJson(),
      ),
      FirestoreService.syncCollection<NoteItem>(
        uid: uid,
        collectionName: 'notes',
        items: notes,
        getId: (item) => item.id,
        toJson: (item) => item.toJson(),
      ),
      FirestoreService.syncCollection<GoalItem>(
        uid: uid,
        collectionName: 'goals',
        items: goals,
        getId: (item) => item.id,
        toJson: (item) => item.toJson(),
      ),
      FirestoreService.syncCollection<PlannerItem>(
        uid: uid,
        collectionName: 'planner_items',
        items: plannerItems,
        getId: (item) => item.id,
        toJson: (item) => item.toJson(),
      ),
      FirestoreService.syncCollection<AttendanceRecord>(
        uid: uid,
        collectionName: 'attendance',
        items: attendance,
        getId: (item) => item.id,
        toJson: (item) => item.toJson(),
      ),
      FirestoreService.syncCollection<DailyStudyRecord>(
        uid: uid,
        collectionName: 'daily_study',
        items: dailyStudy,
        getId: (item) => item.date.toIso8601String().substring(0, 10),
        toJson: (item) => item.toJson(),
      ),
    ]);
  }

  Future<void> saveAndRefresh() async {
    await _saveToLocalStorage();
    await Future.wait([
      StorageService.setStreak(streak),
      StorageService.setXp(xp),
    ]);

    final uid = AuthService.currentUid;
    if (loggedIn && uid != null) {
      _syncAllToFirestore(uid).catchError((e) {
        debugPrint('Firestore database sync failed: $e');
      });
    }

    setState(() {});
  }

  Future<void> saveAll() async {
    await saveAndRefresh();
  }

  void toggleTheme(bool v) async {
    setState(() => dark = v);
    await StorageService.setDarkMode(v);
  }

  void toggleDark(bool v) {
    toggleTheme(v);
  }

  void onLogin(LocalUser u) async {
    setState(() {
      user = u;
      loggedIn = true;
      loading = true;
    });
    await loadApp();
  }

  void onLogout() async {
    await AuthService.logout();
    setState(() {
      loggedIn = false;
      user = null;
      loading = true;
    });
    await loadApp();
  }

  void addXp(int amount) {
    setState(() => xp += amount);
    StorageService.setXp(xp);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Study Planner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: loading
          ? const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      )
          : (loggedIn
          ? HomeShell(parent: this)
          : LandingPage(onLogin: onLogin)),
    );
  }
}