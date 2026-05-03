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
    notifyListeners();

    _dbService.getLastSessionForTemplate(template.id).then((session) {
      _lastSession = session;
      notifyListeners();
    });
  }

  void endSession() {
    if (_activeSession != null) {
      _dbService.saveSession(_activeSession!);
      _activeSession = null;
      _lastSession = null;
      stopTimer();
      notifyListeners();
    }
  }

  void cancelSession() {
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
      
      startTimer(90);
      notifyListeners();
    }
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

  Stream<List<WorkoutSchedule>> getSchedules() => _dbService.getSchedules();
  Stream<List<WorkoutSession>> getSessionHistory() => _dbService.getSessions();

  Future<void> deleteSchedule(String scheduleId) async {
    await _dbService.deleteSchedule(scheduleId);
    notifyListeners();
  }

  Future<void> updateSchedule(String scheduleId, {String? name, String? description}) async {
    final schedules = await _dbService.getSchedules().first;
    final scheduleIndex = schedules.indexWhere((s) => s.id == scheduleId);
    if (scheduleIndex != -1) {
      final updatedSchedule = schedules[scheduleIndex].copyWith(
        name: name,
        description: description,
      );
      await _dbService.saveSchedule(updatedSchedule);
      notifyListeners();
    }
  }
}
