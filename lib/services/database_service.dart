import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_schedule.dart';
import '../models/workout_session.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  DatabaseService() {
    _db.settings = const Settings(persistenceEnabled: true);
  }

  // Schedules (Folders)
  Future<void> saveSchedule(WorkoutSchedule schedule) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('schedules')
        .doc(schedule.id)
        .set(schedule.toMap());
  }

  Stream<List<WorkoutSchedule>> getSchedules() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('schedules')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutSchedule.fromMap(doc.data()))
            .toList());
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('schedules')
        .doc(scheduleId)
        .delete();
  }

  // Sessions
  Future<void> saveSession(WorkoutSession session) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('sessions')
        .doc(session.id)
        .set(session.toMap());
  }

  Stream<List<WorkoutSession>> getSessions() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('sessions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutSession.fromMap(doc.data()))
            .toList());
  }

  Future<WorkoutSession?> getLastSessionForTemplate(String templateId) async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('sessions')
        .where('templateId', isEqualTo: templateId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return WorkoutSession.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  // User Profile
  Future<void> saveUserProfile(String uid, String name, String email) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Bulk Actions
  Future<void> clearAllSchedules() async {
    final snapshots = await _db.collection('users').doc(_uid).collection('schedules').get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> clearAllSessions() async {
    final snapshots = await _db.collection('users').doc(_uid).collection('sessions').get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteSessionsForToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snapshots = await _db
        .collection('users')
        .doc(_uid)
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .get();
    
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  // Active Session Persistence
  Future<void> saveActiveSession(WorkoutSession session) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('active_session')
        .doc('current')
        .set(session.toMap());
  }

  Future<WorkoutSession?> getActiveSession() async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('active_session')
        .doc('current')
        .get();

    if (doc.exists && doc.data() != null) {
      return WorkoutSession.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> clearActiveSession() async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('active_session')
        .doc('current')
        .delete();
  }

  // Analytics
  Stream<List<WorkoutSession>> getSessionsInDateRange(DateTime start, DateTime end) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutSession.fromMap(doc.data()))
            .toList());
  }
}
