import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/teacher.dart';
import '../models/student.dart';

class SuperAdminProvider with ChangeNotifier {
  List<Teacher> _teachers = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;
  Timer? _statsPollingTimer;
  Timer? _teachersPollingTimer;
  Timer? _countsPollingTimer;
  bool _isPollingStats = false;
  bool _isPollingTeachers = false;
  bool _isPollingCounts = false;
  int _newProblemReportsCount = 0;
  int _newPaymentProofsCount = 0;

  List<Teacher> get teachers => _teachers;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPollingStats => _isPollingStats;
  bool get isPollingTeachers => _isPollingTeachers;
  bool get isPollingCounts => _isPollingCounts;
  int get newProblemReportsCount => _newProblemReportsCount;
  int get newPaymentProofsCount => _newPaymentProofsCount;

  Future<void> loadTeachers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getSuperAdminTeachers();
      _teachers = data.map((json) => Teacher.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startTeachersPolling({int intervalSeconds = 60}) {
    if (_isPollingTeachers) return; // Already polling

    _isPollingTeachers = true;
    _teachersPollingTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      try {
        final data = await ApiService.getSuperAdminTeachers();
        final newTeachers = data.map((json) => Teacher.fromJson(json)).toList();

        // Check if teachers data has changed
        bool hasChanged = newTeachers.length != _teachers.length;
        if (!hasChanged) {
          for (int i = 0; i < newTeachers.length; i++) {
            if (newTeachers[i].status != _teachers[i].status ||
                newTeachers[i].totalEarnings != _teachers[i].totalEarnings) {
              hasChanged = true;
              break;
            }
          }
        }

        if (hasChanged) {
          _teachers = newTeachers;
          notifyListeners();
        }
      } catch (e) {
        // Silently handle polling errors
        print('Teachers polling error: $e');
      }
    });
    print('Started teachers polling every $intervalSeconds seconds');
  }

  void stopTeachersPolling() {
    _isPollingTeachers = false;
    _teachersPollingTimer?.cancel();
    _teachersPollingTimer = null;
    print('Stopped teachers polling');
  }

  Future<void> loadStats() async {
    try {
      _stats = await ApiService.getSuperAdminStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void startStatsPolling({int intervalSeconds = 30}) {
    if (_isPollingStats) return; // Already polling

    _isPollingStats = true;
    _statsPollingTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      try {
        final newStats = await ApiService.getSuperAdminStats();
        if (_stats != newStats) { // Only notify if data changed
          _stats = newStats;
          notifyListeners();
        }
      } catch (e) {
        // Silently handle polling errors to avoid disrupting UI
        print('Stats polling error: $e');
      }
    });
    print('Started stats polling every $intervalSeconds seconds');
  }

  void stopStatsPolling() {
    _isPollingStats = false;
    _statsPollingTimer?.cancel();
    _statsPollingTimer = null;
    print('Stopped stats polling');
  }

  void startCountsPolling({int intervalSeconds = 60}) {
    if (_isPollingCounts) return; // Already polling

    _isPollingCounts = true;
    _countsPollingTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      try {
        await loadProblemReportsCount();
        await loadPaymentProofsCount();
      } catch (e) {
        // Silently handle polling errors
        print('Counts polling error: $e');
      }
    });
    print('Started counts polling every $intervalSeconds seconds');
  }

  void stopCountsPolling() {
    _isPollingCounts = false;
    _countsPollingTimer?.cancel();
    _countsPollingTimer = null;
    print('Stopped counts polling');
  }

  Future<void> toggleTeacherStatus(String teacherId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    try {
      await ApiService.toggleTeacherStatus(teacherId, newStatus);
      // Update local state
      final teacherIndex = _teachers.indexWhere((t) => t.id == teacherId);
      if (teacherIndex != -1) {
        _teachers[teacherIndex] = Teacher(
          id: _teachers[teacherIndex].id,
          teacherId: _teachers[teacherIndex].teacherId,
          name: _teachers[teacherIndex].name,
          email: _teachers[teacherIndex].email,
          phone: _teachers[teacherIndex].phone,
          status: newStatus,
          profilePicture: _teachers[teacherIndex].profilePicture,
          companyIds: _teachers[teacherIndex].companyIds,
          subscriptionType: _teachers[teacherIndex].subscriptionType,
          subscriptionStartDate: _teachers[teacherIndex].subscriptionStartDate,
          subscriptionExpiryDate: _teachers[teacherIndex].subscriptionExpiryDate,
          totalEarnings: _teachers[teacherIndex].totalEarnings,
          studentCount: _teachers[teacherIndex].studentCount,
          classCount: _teachers[teacherIndex].classCount,
          createdAt: _teachers[teacherIndex].createdAt,
          updatedAt: _teachers[teacherIndex].updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setTeacherSubscriptionFree(String teacherId) async {
    try {
      await ApiService.setTeacherSubscriptionFree(teacherId);
      // Update local state to reflect free subscription
      final teacherIndex = _teachers.indexWhere((t) => t.id == teacherId);
      if (teacherIndex != -1) {
        _teachers[teacherIndex] = Teacher(
          id: _teachers[teacherIndex].id,
          teacherId: _teachers[teacherIndex].teacherId,
          name: _teachers[teacherIndex].name,
          email: _teachers[teacherIndex].email,
          phone: _teachers[teacherIndex].phone,
          status: _teachers[teacherIndex].status,
          profilePicture: _teachers[teacherIndex].profilePicture,
          companyIds: _teachers[teacherIndex].companyIds,
          subscriptionType: 'free', // Set to free
          subscriptionStartDate: DateTime.now(), // Set current date as start
          subscriptionExpiryDate: DateTime.now().add(const Duration(days: 365 * 100)), // Set far future date
          totalEarnings: _teachers[teacherIndex].totalEarnings,
          studentCount: _teachers[teacherIndex].studentCount,
          classCount: _teachers[teacherIndex].classCount,
          createdAt: _teachers[teacherIndex].createdAt,
          updatedAt: _teachers[teacherIndex].updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setTeacherSubscriptionFreeWithOptions(String teacherId, {
    bool isLifetime = true,
    int? freeDays,
  }) async {
    try {
      await ApiService.setTeacherSubscriptionFreeWithOptions(
        teacherId,
        isLifetime: isLifetime,
        freeDays: freeDays,
      );

      // Update local state to reflect free subscription
      final teacherIndex = _teachers.indexWhere((t) => t.id == teacherId);
      if (teacherIndex != -1) {
        final expiryDate = isLifetime
            ? DateTime.now().add(const Duration(days: 365 * 100)) // Far future for lifetime
            : DateTime.now().add(Duration(days: freeDays ?? 30)); // Default 30 days if not specified

        _teachers[teacherIndex] = Teacher(
          id: _teachers[teacherIndex].id,
          teacherId: _teachers[teacherIndex].teacherId,
          name: _teachers[teacherIndex].name,
          email: _teachers[teacherIndex].email,
          phone: _teachers[teacherIndex].phone,
          status: _teachers[teacherIndex].status,
          profilePicture: _teachers[teacherIndex].profilePicture,
          companyIds: _teachers[teacherIndex].companyIds,
          subscriptionType: 'free',
          subscriptionStartDate: DateTime.now(),
          subscriptionExpiryDate: expiryDate,
          totalEarnings: _teachers[teacherIndex].totalEarnings,
          studentCount: _teachers[teacherIndex].studentCount,
          classCount: _teachers[teacherIndex].classCount,
          createdAt: _teachers[teacherIndex].createdAt,
          updatedAt: _teachers[teacherIndex].updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> startTeacherSubscription(String teacherId, String subscriptionType) async {
    try {
      await ApiService.startTeacherSubscription(teacherId, subscriptionType);

      // Update local state to reflect paid subscription
      final teacherIndex = _teachers.indexWhere((t) => t.id == teacherId);
      if (teacherIndex != -1) {
        final expiryDate = subscriptionType == 'yearly'
            ? DateTime.now().add(const Duration(days: 365))
            : DateTime.now().add(const Duration(days: 30));

        _teachers[teacherIndex] = Teacher(
          id: _teachers[teacherIndex].id,
          teacherId: _teachers[teacherIndex].teacherId,
          name: _teachers[teacherIndex].name,
          email: _teachers[teacherIndex].email,
          phone: _teachers[teacherIndex].phone,
          status: _teachers[teacherIndex].status,
          profilePicture: _teachers[teacherIndex].profilePicture,
          companyIds: _teachers[teacherIndex].companyIds,
          subscriptionType: subscriptionType,
          subscriptionStartDate: DateTime.now(),
          subscriptionExpiryDate: expiryDate,
          totalEarnings: _teachers[teacherIndex].totalEarnings,
          studentCount: _teachers[teacherIndex].studentCount,
          classCount: _teachers[teacherIndex].classCount,
          createdAt: _teachers[teacherIndex].createdAt,
          updatedAt: _teachers[teacherIndex].updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Student>> getStudentsForTeacher(String teacherId) async {
    try {
      final data = await ApiService.getStudentsForTeacherSuperAdmin(teacherId);
      final students = data['students'] as List;
      return students.map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyEarningsForTeacher(String teacherId) async {
    try {
      return await ApiService.getMonthlyEarningsForTeacher(teacherId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Return empty list instead of throwing to handle gracefully
      return [];
    }
  }

  Future<Map<String, dynamic>> getEarningsForTeacher(String teacherId) async {
    try {
      return await ApiService.getEarningsForTeacher(teacherId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadProblemReportsCount() async {
    try {
      final reports = await ApiService.getProblemReports();
      final prefs = await SharedPreferences.getInstance();
      final lastSeenCount = prefs.getInt('last_seen_problem_reports') ?? 0;
      
      _newProblemReportsCount = reports.length - lastSeenCount;
      if (_newProblemReportsCount < 0) _newProblemReportsCount = 0;
      
      notifyListeners();
    } catch (e) {
      print('Error loading problem reports count: $e');
    }
  }

  Future<void> loadPaymentProofsCount() async {
    try {
      final proofs = await ApiService.getPaymentProofs();
      final prefs = await SharedPreferences.getInstance();
      final lastSeenCount = prefs.getInt('last_seen_payment_proofs') ?? 0;
      
      _newPaymentProofsCount = proofs.length - lastSeenCount;
      if (_newPaymentProofsCount < 0) _newPaymentProofsCount = 0;
      
      notifyListeners();
    } catch (e) {
      print('Error loading payment proofs count: $e');
    }
  }

  Future<void> markProblemReportsAsSeen() async {
    _newProblemReportsCount = 0;
    notifyListeners();
  }

  Future<void> markPaymentProofsAsSeen() async {
    _newPaymentProofsCount = 0;
    notifyListeners();
  }
}