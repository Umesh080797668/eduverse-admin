import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/super_admin_provider.dart';
import '../models/teacher.dart';
import 'teacher_details_screen.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadTeachers();
    });
  }

  Future<void> _toggleActivation(Teacher teacher) async {
    try {
      await context.read<SuperAdminProvider>().toggleTeacherStatus(
        teacher.id,
        teacher.status,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teacher ${teacher.status == 'active' ? 'deactivated' : 'activated'} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Teachers')),
      body: Consumer<SuperAdminProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.loadTeachers(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.teachers.length,
            itemBuilder: (context, index) {
              final teacher = provider.teachers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(teacher.name[0].toUpperCase()),
                  ),
                  title: Text(teacher.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacher.email),
                      Text('ID: ${teacher.teacherId}'),
                      Text('Earnings: \$${teacher.totalEarnings.toStringAsFixed(2)}'),
                      Text('Students: ${teacher.studentCount}, Classes: ${teacher.classCount}'),
                      Text(
                        'Status: ${teacher.status}',
                        style: TextStyle(
                          color: teacher.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: teacher.isActive,
                    onChanged: (value) => _toggleActivation(teacher),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TeacherDetailsScreen(teacher: teacher),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}