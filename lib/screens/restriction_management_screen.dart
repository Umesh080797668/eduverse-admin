import 'package:flutter/material.dart';
import '../services/restriction_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RestrictionManagementScreen extends StatefulWidget {
  const RestrictionManagementScreen({Key? key}) : super(key: key);

  @override
  State<RestrictionManagementScreen> createState() => _RestrictionManagementScreenState();
}

class _RestrictionManagementScreenState extends State<RestrictionManagementScreen> with SingleTickerProviderStateMixin {
  final RestrictionService _restrictionService = RestrictionService();
  late TabController _tabController;
  List<dynamic> _teachers = [];
  List<dynamic> _students = [];
  bool _isLoadingTeachers = true;
  bool _isLoadingStudents = true;
  String? _errorTeachers;
  String? _errorStudents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Check if user is logged in and has admin data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn || authProvider.adminId == null) {
        print('DEBUG: User not logged in or admin data missing, redirecting to login');
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTeachers(),
      _loadStudents(),
    ]);
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
      _errorTeachers = null;
    });

    try {
      print('DEBUG: Loading teachers...');
      final teachers = await _restrictionService.getAllTeachers();
      print('DEBUG: Teachers loaded successfully: ${teachers.length} teachers');
      setState(() {
        _teachers = teachers;
        _isLoadingTeachers = false;
      });
    } catch (e) {
      print('DEBUG: Error loading teachers: $e');
      setState(() {
        _errorTeachers = e.toString();
        _isLoadingTeachers = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _errorStudents = null;
    });

    try {
      final students = await _restrictionService.getAllStudents();
      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _errorStudents = e.toString();
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _restrictTeacher(String teacherId, String name) async {
    final reason = await _showReasonDialog('Restrict Teacher', 'Enter reason for restricting $name');
    if (reason == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminId = authProvider.adminId;
      print('DEBUG: AuthProvider adminId: $adminId');
      print('DEBUG: AuthProvider adminData: ${authProvider.adminData}');
      print('DEBUG: AuthProvider isLoggedIn: ${authProvider.isLoggedIn}');

      if (adminId == null) {
        print('DEBUG: Admin ID is null, showing error dialog');
        _showErrorDialog('Admin ID not found. Please log out and log back in.');
        return;
      }

      print('DEBUG: Calling restrictTeacher with teacherId: $teacherId, adminId: $adminId, reason: $reason');
      await _restrictionService.restrictTeacher(
        teacherId: teacherId,
        adminId: adminId,
        reason: reason,
      );

      _showSuccessDialog('Teacher restricted successfully');
      _loadTeachers();
    } catch (e) {
      print('DEBUG: Error restricting teacher: $e');
      _showErrorDialog('Failed to restrict teacher: $e');
    }
  }

  Future<void> _unrestrictTeacher(String teacherId) async {
    final confirm = await _showConfirmDialog('Unrestrict Teacher', 'Are you sure you want to unrestrict this teacher?');
    if (!confirm) return;

    try {
      await _restrictionService.unrestrictTeacher(teacherId);
      _showSuccessDialog('Teacher unrestricted successfully');
      _loadTeachers();
    } catch (e) {
      _showErrorDialog('Failed to unrestrict teacher: $e');
    }
  }

  Future<void> _restrictStudent(String studentId, String name) async {
    final reason = await _showReasonDialog('Restrict Student', 'Enter reason for restricting $name');
    if (reason == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminId = authProvider.adminId;

      if (adminId == null) {
        _showErrorDialog('Admin ID not found. Please log out and log back in.');
        return;
      }

      await _restrictionService.restrictStudent(
        studentId: studentId,
        adminId: adminId,
        reason: reason,
      );

      _showSuccessDialog('Student restricted successfully');
      _loadStudents();
    } catch (e) {
      _showErrorDialog('Failed to restrict student: $e');
    }
  }

  Future<void> _unrestrictStudent(String studentId) async {
    final confirm = await _showConfirmDialog('Unrestrict Student', 'Are you sure you want to unrestrict this student?');
    if (!confirm) return;

    try {
      await _restrictionService.unrestrictStudent(studentId);
      _showSuccessDialog('Student unrestricted successfully');
      _loadStudents();
    } catch (e) {
      _showErrorDialog('Failed to unrestrict student: $e');
    }
  }

  Future<String?> _showReasonDialog(String title, String message) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restriction Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Teachers', icon: Icon(Icons.school)),
            Tab(text: 'Students', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeachersTab(),
          _buildStudentsTab(),
        ],
      ),
    );
  }

  Widget _buildTeachersTab() {
    if (_isLoadingTeachers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorTeachers != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorTeachers'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeachers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_teachers.isEmpty) {
      return const Center(child: Text('No teachers found'));
    }

    return RefreshIndicator(
      onRefresh: _loadTeachers,
      child: ListView.builder(
        itemCount: _teachers.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final teacher = _teachers[index];
          final isRestricted = teacher['isRestricted'] ?? false;
          final name = teacher['name'] ?? 'Unknown';
          final email = teacher['email'] ?? '';
          final teacherId = teacher['teacherId'] ?? '';
          final id = teacher['_id'];

          return Card(
            key: Key('teacher-card-${id}'),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              key: Key('teacher-tile-${id}'),
              leading: CircleAvatar(
                backgroundColor: isRestricted ? Colors.red : Colors.green,
                child: Icon(
                  isRestricted ? Icons.block : Icons.check_circle,
                  color: Colors.white,
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email),
                  if (teacherId.isNotEmpty) Text('ID: $teacherId'),
                  if (isRestricted && teacher['restrictionReason'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${teacher['restrictionReason']}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  if (isRestricted) {
                    _unrestrictTeacher(id);
                  } else {
                    _restrictTeacher(id, name);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRestricted ? Colors.green : Colors.red,
                ),
                child: Text(isRestricted ? 'Unrestrict' : 'Restrict'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentsTab() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorStudents != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorStudents'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return const Center(child: Text('No students found'));
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        itemCount: _students.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final student = _students[index];
          final isRestricted = student['isRestricted'] ?? false;
          final name = student['name'] ?? 'Unknown';
          final email = student['email'] ?? '';
          final studentId = student['studentId'] ?? '';
          final id = student['_id'];
          final classInfo = student['classId'];
          final className = classInfo != null ? classInfo['name'] ?? '' : '';

          return Card(
            key: Key('student-card-${id}'),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              key: Key('student-tile-${id}'),
              leading: CircleAvatar(
                backgroundColor: isRestricted ? Colors.red : Colors.green,
                child: Icon(
                  isRestricted ? Icons.block : Icons.check_circle,
                  color: Colors.white,
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (email.isNotEmpty) Text(email),
                  if (studentId.isNotEmpty) Text('ID: $studentId'),
                  if (className.isNotEmpty) Text('Class: $className'),
                  if (isRestricted && student['restrictionReason'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${student['restrictionReason']}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  if (isRestricted) {
                    _unrestrictStudent(id);
                  } else {
                    _restrictStudent(id, name);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRestricted ? Colors.green : Colors.red,
                ),
                child: Text(isRestricted ? 'Unrestrict' : 'Restrict'),
              ),
            ),
          );
        },
      ),
    );
  }
}
