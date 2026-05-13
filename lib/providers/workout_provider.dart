import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_schedule.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
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

  late final Stream<List<WorkoutSchedule>> schedules;
  late final Stream<List<WorkoutSession>> sessionHistory;
  
  Stream<double>? _dailyVolumeStream;
  Stream<double>? _weeklyVolumeStream;

  WorkoutProvider() {
    WidgetsBinding.instance.addObserver(this);
    schedules = _dbService.getSchedules();
    sessionHistory = _dbService.getSessions();
    _initPrefsAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeTimer();
    }
  }

  Future<void> _initPrefsAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadActiveSession();
    _resumeTimer();
  }

  Future<void> _loadActiveSession() async {
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
        
        // Also fetch last session for this template
        _dbService.getLastSessionForTemplate(_activeSession!.templateId).then((session) {
          _lastSession = session;
          notifyListeners();
        });
        return;
      } catch (e) {
        debugPrint('Error loading local session: $e');
      }
    }

    // Fallback to Firestore
    final session = await _dbService.getActiveSession();
    if (session != null) {
      _activeSession = session;
      _saveSessionLocally();
      if (_activeSession!.exercises.any((e) => e.completedSets.isNotEmpty)) {
        _notificationService.showWorkoutInProgressNotification(_activeSession!.name);
      }
      notifyListeners();
    }
  }

  void _saveSessionLocally() {
    if (_activeSession != null) {
      _prefs?.setString('active_session', jsonEncode(_activeSession!.toJson()));
    } else {
      _prefs?.remove('active_session');
    }
  }

  void startSession(WorkoutTemplate template, String scheduleName) {
    _activeSession = WorkoutSession(
      id: _uuid.v4(),
      templateId: template.id,
      scheduleName: scheduleName,
      name: template.name,
      date: DateTime.now(),
      exercises: template.exercises.map((e) => e.copyWith(completedSets: [])).toList(),
    );
    
    _lastSession = null;
    _dbService.saveActiveSession(_activeSession!);
    // We don't save locally or show notification until the first set is logged
    notifyListeners();

    _dbService.getLastSessionForTemplate(template.id).then((session) {
      _lastSession = session;
      notifyListeners();
    });
  }

  void endSession() {
    if (_activeSession != null) {
      _dbService.saveSession(_activeSession!);
      _dbService.clearActiveSession();
      _activeSession = null;
      _lastSession = null;
      _saveSessionLocally();
      stopTimer();
      _notificationService.cancelWorkoutNotification();
      FlutterBackgroundService().invoke('stopService');
      notifyListeners();
    }
  }

  void cancelSession() {
    _dbService.clearActiveSession();
    _activeSession = null;
    _lastSession = null;
    _saveSessionLocally();
    stopTimer();
    _notificationService.cancelWorkoutNotification();
    FlutterBackgroundService().invoke('stopService');
    notifyListeners();
  }

  void logSet(String exerciseId, int reps, double weight) {
    if (_activeSession == null) return;

    final exerciseIndex = _activeSession!.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex != -1) {
      final exercise = _activeSession!.exercises[exerciseIndex];
      final isFirstSet = !hasActiveSessionProgress;

      final newSet = WorkoutSet(
        id: _uuid.v4(),
        reps: reps,
        weight: weight,
        timestamp: DateTime.now(),
      );

      final updatedSets = List<WorkoutSet>.from(exercise.completedSets)..add(newSet);
      _activeSession!.exercises[exerciseIndex] = exercise.copyWith(completedSets: updatedSets);
      
      _dbService.saveActiveSession(_activeSession!);
      _saveSessionLocally();
      
      if (isFirstSet) {
        _notificationService.showWorkoutInProgressNotification(_activeSession!.name);
        FlutterBackgroundService().startService();
      }
      
      startTimer(90);
      notifyListeners();
    }
  }

  // Volume Analytics
  Stream<double> getDailyVolume() {
    if (_dailyVolumeStream != null) return _dailyVolumeStream!;
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    _dailyVolumeStream = _dbService.getSessionsInDateRange(startOfDay, endOfDay).map((sessions) {
      return sessions.fold(0.0, (sum, session) => sum + session.totalVolume);
    });
    return _dailyVolumeStream!;
  }

  Stream<double> getWeeklyVolume() {
    if (_weeklyVolumeStream != null) return _weeklyVolumeStream!;

    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    _weeklyVolumeStream = _dbService.getSessionsInDateRange(startOfWeek, endOfWeek).map((sessions) {
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

    // 2. If the active session was started today, clear it too
    if (_activeSession != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_activeSession!.date.isAfter(today) || _activeSession!.date.isAtSameMomentAs(today)) {
        await _dbService.clearActiveSession();
        _activeSession = null;
        _lastSession = null;
        _saveSessionLocally();
        stopTimer();
        _notificationService.cancelWorkoutNotification();
        FlutterBackgroundService().invoke('stopService');
      }
    }

    notifyListeners();
  }
}
