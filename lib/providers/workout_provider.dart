import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout_schedule.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class WorkoutProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid();

  WorkoutSession? _activeSession;
  WorkoutSession? get activeSession => _activeSession;

  WorkoutSession? _lastSession;
  WorkoutSession? get lastSession => _lastSession;

  int _timerSeconds = 0;
  int get timerSeconds => _timerSeconds;
  Timer? _timer;

  bool get isTimerRunning => _timer != null;

  bool _allGifsCollapsed = false;
  bool get allGifsCollapsed => _allGifsCollapsed;

  bool _allSetsCollapsed = false;
  bool get allSetsCollapsed => _allSetsCollapsed;

  late final Stream<List<WorkoutSchedule>> schedules;
  late final Stream<List<WorkoutSession>> sessionHistory;
  
  Stream<double>? _dailyVolumeStream;
  Stream<double>? _weeklyVolumeStream;

  WorkoutProvider() {
    schedules = _dbService.getSchedules();
    sessionHistory = _dbService.getSessions();
    _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    final session = await _dbService.getActiveSession();
    if (session != null) {
      _activeSession = session;
      notifyListeners();
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
      stopTimer();
      notifyListeners();
    }
  }

  void cancelSession() {
    _dbService.clearActiveSession();
    _activeSession = null;
    _lastSession = null;
    stopTimer();
    notifyListeners();
  }

  void logSet(String exerciseId, int reps, double weight) {
    if (_activeSession == null) return;

    final exerciseIndex = _activeSession!.exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex != -1) {
      final exercise = _activeSession!.exercises[exerciseIndex];
      final newSet = WorkoutSet(
        id: _uuid.v4(),
        reps: reps,
        weight: weight,
        timestamp: DateTime.now(),
      );

      final updatedSets = List<WorkoutSet>.from(exercise.completedSets)..add(newSet);
      _activeSession!.exercises[exerciseIndex] = exercise.copyWith(completedSets: updatedSets);
      
      _dbService.saveActiveSession(_activeSession!);
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        _timerSeconds--;
        notifyListeners();
      } else {
        stopTimer();
      }
    });
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _timerSeconds = 0;
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
    await _dbService.deleteSessionsForToday();
    notifyListeners();
  }
}
