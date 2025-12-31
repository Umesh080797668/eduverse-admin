import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/super_admin_provider.dart';
import '../models/teacher.dart';
import '../models/student.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherDetailsScreen({super.key, required this.teacher});

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await context.read<SuperAdminProvider>().getStudentsForTeacher(widget.teacher.id);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teacher.name} - Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Teacher Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Name', widget.teacher.name),
                        _buildInfoRow('Email', widget.teacher.email),
                        _buildInfoRow('Teacher ID', widget.teacher.teacherId),
                        if (widget.teacher.phone != null)
                          _buildInfoRow('Phone', widget.teacher.phone!),
                        _buildInfoRow('Status', widget.teacher.status.toUpperCase()),
                        _buildInfoRow('Subscription', widget.teacher.subscriptionType),
                        _buildInfoRow('Total Earnings', '\$${widget.teacher.totalEarnings.toStringAsFixed(2)}'),
                        _buildInfoRow('Students Count', widget.teacher.studentCount.toString()),
                        _buildInfoRow('Classes Count', widget.teacher.classCount.toString()),
                        _buildInfoRow('Joined', widget.teacher.createdAt.toString().split(' ')[0]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Students Section
                Text(
                  'Students (${_students.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                if (_students.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No students found for this teacher.'),
                    ),
                  )
                else
                  ..._students.map((student) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(student.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (student.email != null) Text('Email: ${student.email}'),
                          if (student.phone != null) Text('Phone: ${student.phone}'),
                          if (student.classId != null)
                            Text('Class: ${student.classId!['name'] ?? 'Unknown'}'),
                          Text('Total Paid: \$${student.totalPaid.toStringAsFixed(2)}'),
                          Text('Payments: ${student.paymentCount}'),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}