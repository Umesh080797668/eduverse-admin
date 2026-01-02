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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SuperAdminProvider>();
      provider.loadTeachers();
      // Start polling for real-time teacher updates
      provider.startTeachersPolling(intervalSeconds: 45); // Poll every 45 seconds
    });
  }

  @override
  void dispose() {
    // Stop polling when screen is disposed
    context.read<SuperAdminProvider>().stopTeachersPolling();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleActivation(Teacher teacher) async {
    // Stop polling to prevent overriding local changes
    context.read<SuperAdminProvider>().stopTeachersPolling();

    try {
      await context.read<SuperAdminProvider>().toggleTeacherStatus(
        teacher.id,
        teacher.status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teacher ${teacher.status == 'active' ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: teacher.status == 'active' ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Restart polling after a delay to allow server sync
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          context.read<SuperAdminProvider>().startTeachersPolling(intervalSeconds: 45);
        }
      });
    }
  }

  List<Teacher> _getFilteredTeachers(List<Teacher> teachers) {
    return teachers.where((teacher) {
      final matchesSearch = teacher.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           teacher.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           teacher.teacherId.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'all' ||
                           (_statusFilter == 'active' && teacher.isActive) ||
                           (_statusFilter == 'inactive' && !teacher.isActive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Teachers'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search teachers by name, email, or ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Filter by status:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(value: 'active', label: Text('Active')),
                          ButtonSegment(value: 'inactive', label: Text('Inactive')),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _statusFilter = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Teachers List
          Expanded(
            child: Consumer<SuperAdminProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => provider.loadTeachers(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredTeachers = _getFilteredTeachers(provider.teachers);

                if (filteredTeachers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No teachers found matching "$_searchQuery"'
                              : 'No teachers found',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTeachers.length,
                  itemBuilder: (context, index) {
                    final teacher = filteredTeachers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TeacherDetailsScreen(teacher: teacher),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: teacher.isActive ? Colors.green : Colors.grey,
                                child: Text(
                                  teacher.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Teacher Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacher.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      teacher.email,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      'ID: ${teacher.teacherId}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'LKR ${teacher.totalEarnings.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${teacher.studentCount} students',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.class_,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${teacher.classCount} classes',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: teacher.isActive ? Colors.green[100] : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        teacher.status.toUpperCase(),
                                        style: TextStyle(
                                          color: teacher.isActive ? Colors.green[800] : Colors.red[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Toggle
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Switch(
                                    value: teacher.isActive,
                                    onChanged: (value) => _toggleActivation(teacher),
                                    activeTrackColor: Colors.green[200],
                                    thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.green;
                                      }
                                      return Colors.grey;
                                    }),
                                  ),
                                  Text(
                                    teacher.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: teacher.isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}