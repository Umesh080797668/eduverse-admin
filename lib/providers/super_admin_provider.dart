import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/teacher.dart';
import '../models/student.dart';

class SuperAdminProvider with ChangeNotifier {
  List<Teacher> _teachers = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  List<Teacher> get teachers => _teachers;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  Future<void> loadStats() async {
    try {
      _stats = await ApiService.getSuperAdminStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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
}