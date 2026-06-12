import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_schedule.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class WorkoutProvider with ChangeNotifier, WidgetsBindingObserver {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final _uuid = const Uuid();
  SharedPreferences? _prefs;

  WorkoutSession? _activeSession;
  WorkoutSession? get activeSession => _activeSession;

  WorkoutSession? _lastSession;
  WorkoutSession? get lastSession => _lastSession;

  int _timerSeconds = 0;
  int get timerSeconds => _timerSeconds;
  Timer? _timer;
  DateTime? _timerEndTime;

  bool get isTimerRunning => _timerSeconds > 0;

  bool _allGifsCollapsed = false;
  bool get allGifsCollapsed => _allGifsCollapsed;

  bool _allSetsCollapsed = false;
  bool get allSetsCollapsed => _allSetsCollapsed;

  bool get hasActiveSessionProgress => _activeSession?.exercises.any((e) => e.completedSets.isNotEmpty) ?? false;

  Stream<List<WorkoutSchedule>>? _schedules;
  Stream<List<WorkoutSchedule>> get schedules => _schedules ?? const Stream.empty();

  Stream<List<WorkoutSession>>? _sessionHistory;
  Stream<List<WorkoutSession>> get sessionHistory => _sessionHistory ?? const Stream.empty();
  
  Stream<double>? _dailyVolumeStream;
  Stream<double>? _weeklyVolumeStream;

  StreamSubscription<User?>? _authSubscription;

  WorkoutProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (FirebaseAuth.instance.currentUser != null) {
      _schedules = _dbService.getSchedules();
      _sessionHistory = _dbService.getSessions();
      await _loadActiveSession();
    }
    _initAuthListener();
    _resumeTimer();
  }

  void _initAuthListener() {
    _authSubscription = AuthService().user.listen((user) {
      _refreshStreams();
    });
  }

  Future<void> _refreshStreams() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _schedules = _dbService.getSchedules();
      _sessionHistory = _dbService.getSessions();
      _dailyVolumeStream = null;
      _weeklyVolumeStream = null;
      await _loadActiveSession();
    } else {
      _schedules = null;
      _sessionHistory = null;
      _dailyVolumeStream = null;
      _weeklyVolumeStream = null;
      _activeSession = null;
      _lastSession = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeTimer();
    }
  }

  Future<void> _loadActiveSession() async {
    // Ensure prefs are loaded
    _prefs ??= await SharedPreferences.getInstance();

    // Try local storage first for speed
    final localData = _prefs?.getString('active_session');
    if (localData != null) {
      try {
        final session = WorkoutSession.fromMap(jsonDecode(localData));
        _activeSession = session;
        
        // Only show notification if there's actual progress
        if (_activeSession!.exercises.any((e) => e.completedSets.isNotEmpty)) {
          _notificationService.showWorkoutInProgressNotification(_activeSession!.name);
          FlutterBackgroundService().startService();
        }
        
        notifyListeners();
        
        // Also fetch last session for this template if logged in
        if (FirebaseAuth.instance.currentUser != null) {
          _dbService.getLastSessionForTemplate(_activeSession!.templateId).then((session) {
            _lastSession = session;
            notifyListeners();
          });
        }
        return;
      } catch (e) {
        debugPrint('Error loading local session: $e');
        _prefs?.remove('active_session'); // Clear corrupt data
      }
    }

    // Fallback to Firestore - only if logged in
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final session = await _dbService.getActiveSession();
        if (session != null) {
          _activeSession = session;
          await _saveSessionLocally();
          if (_activeSession!.exercises.any((e) => e.completedSets.isNotEmpty)) {
            _notificationService.showWorkoutInProgressNotification(_activeSession!.name);
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error fetching active session: $e');
      }
    }
  }

  Future<void> _saveSessionLocally() async {
    if (_activeSession != null) {
      await _prefs?.setString('active_session', jsonEncode(_activeSession!.toJson()));
    } else {
      await _prefs?.remove('active_session');
    }
  }

  Future<void> startSession(WorkoutTemplate template, String scheduleName) async {
    _activeSession = WorkoutSession(
      id: _uuid.v4(),
      templateId: template.id,
      scheduleName: scheduleName,
      name: template.name,
      date: DateTime.now(),
      exercises: template.exercises.map((e) => e.copyWith(completedSets: [])).toList(),
    );
    
    _lastSession = null;
    // We don't save to DB or locally until there's actual progress
    notifyListeners();

    _dbService.getLastSessionForTemplate(template.id).then((session) {
      _lastSession = session;
      notifyListeners();
    });
  }

  Future<void> endSession() async {
    if (_activeSession != null) {
      await _dbService.saveSession(_activeSession!);
      await _dbService.clearActiveSession();
      _activeSession = null;
      _lastSession = null;
      await _saveSessionLocally();
      stopTimer();
      _notificationService.cancelWorkoutNotification();
      FlutterBackgroundService().invoke('stopService');
      notifyListeners();
    }
  }

  Future<void> cancelSession() async {
    await _dbService.clearActiveSession();
    _activeSession = null;
    _lastSession = null;
    await _saveSessionLocally();
    stopTimer();
    _notificationService.cancelWorkoutNotification();
    FlutterBackgroundService().invoke('stopService');
    notifyListeners();
  }

  Future<void> logSet(String exerciseId, int reps, double weight, {String repsUnit = 'reps', String weightUnit = 'kg'}) async {
    if (_activeSession == null) return;

    final exerciseIndex = _activeSession!.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex != -1) {
      final exercise = _activeSession!.exercises[exerciseIndex];
      final isFirstSet = !hasActiveSessionProgress;

      final newSet = WorkoutSet(
        id: _uuid.v4(),
        reps: reps,
        repsUnit: repsUnit,
        weight: weight,
        weightUnit: weightUnit,
        timestamp: DateTime.now(),
      );

      final updatedSets = List<WorkoutSet>.from(exercise.completedSets)..add(newSet);
      _activeSession!.exercises[exerciseIndex] = exercise.copyWith(completedSets: updatedSets);
      
      await _dbService.saveActiveSession(_activeSession!);
      await _saveSessionLocally();
      
      if (isFirstSet) {
        _notificationService.showWorkoutInProgressNotification(_activeSession!.name);
        FlutterBackgroundService().startService();
      }
      
      startTimer(90);
      notifyListeners();
    }
  }

  Future<void> addExerciseToActiveSession(String name, String category, int sets, int reps) async {
    if (_activeSession == null) return;

    final newExercise = Exercise(
      id: _uuid.v4(),
      name: name,
      category: category,
      targetReps: List.generate(sets, (index) => reps),
      completedSets: [],
    );

    final updatedExercises = List<Exercise>.from(_activeSession!.exercises)..add(newExercise);
    _activeSession = _activeSession!.copyWith(exercises: updatedExercises);
    
    await _dbService.saveActiveSession(_activeSession!);
    await _saveSessionLocally();
    notifyListeners();
  }

  Future<void> removeExerciseFromActiveSession(String exerciseId) async {
    if (_activeSession == null) return;

    final updatedExercises = List<Exercise>.from(_activeSession!.exercises)
      ..removeWhere((e) => e.id == exerciseId);
    _activeSession = _activeSession!.copyWith(exercises: updatedExercises);
    
    await _dbService.saveActiveSession(_activeSession!);
    await _saveSessionLocally();
    notifyListeners();
  }

  DateTime? _lastVolumeUpdateDate;

  // Volume Analytics
  Stream<double> getDailyVolume() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_dailyVolumeStream != null && _lastVolumeUpdateDate == today) {
      return _dailyVolumeStream!;
    }
    
    if (FirebaseAuth.instance.currentUser == null) return const Stream.empty();
    
    _lastVolumeUpdateDate = today;
    final endOfDay = today.add(const Duration(days: 1));

    _dailyVolumeStream = _dbService.getSessionsInDateRange(today, endOfDay).map((sessions) {
      return sessions.fold(0.0, (sum, session) => sum + session.totalVolume);
    });
    return _dailyVolumeStream!;
  }

  Stream<double> getWeeklyVolume() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
    
    if (_weeklyVolumeStream != null && _lastVolumeUpdateDate == today) {
      return _weeklyVolumeStream!;
    }

    if (FirebaseAuth.instance.currentUser == null) return const Stream.empty();

    _lastVolumeUpdateDate = today;
    final endOfWeek = firstDayOfWeek.add(const Duration(days: 7));

    _weeklyVolumeStream = _dbService.getSessionsInDateRange(firstDayOfWeek, endOfWeek).map((sessions) {
      return sessions.fold(0.0, (sum, session) => sum + session.totalVolume);
    });
    return _weeklyVolumeStream!;
  }

  void startTimer(int seconds) {
    _timer?.cancel();
    _timerSeconds = seconds;
    _timerEndTime = DateTime.now().add(Duration(seconds: seconds));
    _prefs?.setString('timer_end_time', _timerEndTime!.toIso8601String());
    
    _notificationService.showRestTimerNotification(seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        _timerSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _timer = null;
        _timerSeconds = 0;
        _timerEndTime = null;
        _prefs?.remove('timer_end_time');
        // Do NOT cancel the notification here so it stays on screen
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void _resumeTimer() {
    final endTimeStr = _prefs?.getString('timer_end_time');
    if (endTimeStr != null) {
      final endTime = DateTime.parse(endTimeStr);
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        _timerEndTime = endTime;
        _timerSeconds = remaining;
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_timerSeconds > 0) {
            _timerSeconds--;
            notifyListeners();
          } else {
            stopTimer();
          }
        });
        notifyListeners();
      } else {
        _prefs?.remove('timer_end_time');
        _timerSeconds = 0;
        notifyListeners();
      }
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _timerSeconds = 0;
    _timerEndTime = null;
    _prefs?.remove('timer_end_time');
    _notificationService.cancelRestTimerNotification();
    notifyListeners();
  }

  void toggleAllGifsCollapsed() {
    _allGifsCollapsed = !_allGifsCollapsed;
    notifyListeners();
  }

  void toggleAllSetsCollapsed() {
    _allSetsCollapsed = !_allSetsCollapsed;
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    await _dbService.deleteSession(sessionId);
    notifyListeners();
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _dbService.deleteSchedule(scheduleId);
    notifyListeners();
  }

  Future<void> updateSchedule(String scheduleId, {String? name, String? description}) async {
    final schedulesList = await _dbService.getSchedules().first;
    final scheduleIndex = schedulesList.indexWhere((s) => s.id == scheduleId);
    if (scheduleIndex != -1) {
      final updatedSchedule = schedulesList[scheduleIndex].copyWith(
        name: name,
        description: description,
      );
      await _dbService.saveSchedule(updatedSchedule);
      notifyListeners();
    }
  }

  Future<void> resetToday() async {
    // 1. Delete all completed sessions for today from Firestore
    await _dbService.deleteSessionsForToday();

    // 2. Clear active session from Firestore regardless of local state
    // This ensures that "ghost" sessions in Firestore are also cleared
    await _dbService.clearActiveSession();

    // 3. Clear local state if it was from today
    if (_activeSession != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_activeSession!.date.isAfter(today) || _activeSession!.date.isAtSameMomentAs(today)) {
        _activeSession = null;
        _lastSession = null;
        await _saveSessionLocally();
        stopTimer();
        _notificationService.cancelWorkoutNotification();
        FlutterBackgroundService().invoke('stopService');
      }
    } else {
      // Even if no active session in memory, ensure local storage is cleared 
      // just in case it had a stale session from today
      await _prefs?.remove('active_session');
    }

    // 4. Force refresh of volume streams
    _dailyVolumeStream = null;
    _weeklyVolumeStream = null;
    _lastVolumeUpdateDate = null;

    notifyListeners();
  }
}
