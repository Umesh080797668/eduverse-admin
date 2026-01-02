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
  List<Map<String, dynamic>> _monthlyEarnings = [];
  bool _earningsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadMonthlyEarnings();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final provider = context.read<SuperAdminProvider>();
    try {
      final students = await provider.getStudentsForTeacher(widget.teacher.id);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    }
  }

  Future<void> _loadMonthlyEarnings() async {
    if (mounted) {
      setState(() => _earningsLoading = true);
    }
    final provider = context.read<SuperAdminProvider>();
    try {
      final earnings = await provider.getMonthlyEarningsForTeacher(widget.teacher.teacherId);
      if (mounted) {
        setState(() {
          _monthlyEarnings = earnings;
          _earningsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _earningsLoading = false);
        // Don't show error snackbar for earnings as it's not critical
        print('Failed to load monthly earnings: $e');
      }
    }
  }

  Future<void> _showSetFreeOptionsDialog() async {
    bool isLifetime = true;
    int? freeDays;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Subscription Free'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose the type of free subscription:'),
              const SizedBox(height: 16),
              RadioListTile<bool>(
                title: const Text('Lifetime Free'),
                subtitle: const Text('Teacher gets unlimited free access'),
                value: true,
                groupValue: isLifetime,
                onChanged: (value) {
                  setState(() => isLifetime = value ?? true);
                },
              ),
              RadioListTile<bool>(
                title: const Text('Time Limited Free'),
                subtitle: const Text('Teacher gets free access for a specific period'),
                value: false,
                groupValue: isLifetime,
                onChanged: (value) {
                  setState(() => isLifetime = value ?? false);
                },
              ),
              if (!isLifetime) ...[
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Number of Free Days',
                    hintText: 'e.g., 30, 60, 90',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    freeDays = int.tryParse(value);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Set Free'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (!isLifetime && (freeDays == null || freeDays! <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number of days'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        final provider = context.read<SuperAdminProvider>();
        await provider.setTeacherSubscriptionFreeWithOptions(
          widget.teacher.id,
          isLifetime: isLifetime,
          freeDays: freeDays,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLifetime
                  ? 'Subscription set to lifetime free successfully'
                  : 'Subscription set to free for $freeDays days successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to refresh the teacher list
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to set subscription free: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showStartSubscriptionDialog() async {
    String selectedPlan = 'monthly';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Start Paid Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose the subscription plan:'),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('Monthly Plan'),
                subtitle: const Text('LKR 1,000 per month'),
                value: 'monthly',
                groupValue: selectedPlan,
                onChanged: (value) {
                  setState(() => selectedPlan = value ?? 'monthly');
                },
              ),
              RadioListTile<String>(
                title: const Text('Yearly Plan'),
                subtitle: const Text('LKR 8,000 per year (25% savings)'),
                value: 'yearly',
                groupValue: selectedPlan,
                onChanged: (value) {
                  setState(() => selectedPlan = value ?? 'yearly');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Start Subscription'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final provider = context.read<SuperAdminProvider>();
        await provider.startTeacherSubscription(widget.teacher.id, selectedPlan);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paid subscription ($selectedPlan) started successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to refresh the teacher list
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start subscription: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teacher.name} - Details'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teacher Info Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: widget.teacher.isActive ? Colors.green : Colors.grey,
                                child: Text(
                                  widget.teacher.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.teacher.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: widget.teacher.isActive ? Colors.green[100] : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.teacher.status.toUpperCase(),
                                        style: TextStyle(
                                          color: widget.teacher.isActive ? Colors.green[800] : Colors.red[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoRow('Email', widget.teacher.email),
                          _buildInfoRow('Teacher ID', widget.teacher.teacherId),
                          if (widget.teacher.phone != null)
                            _buildInfoRow('Phone', widget.teacher.phone!),
                          _buildInfoRow('Subscription', widget.teacher.subscriptionType),
                          _buildInfoRow('Total Earnings', 'LKR ${widget.teacher.totalEarnings.toStringAsFixed(2)}'),
                          _buildInfoRow('Students Count', widget.teacher.studentCount.toString()),
                          _buildInfoRow('Classes Count', widget.teacher.classCount.toString()),
                          _buildInfoRow('Joined', widget.teacher.createdAt.toString().split(' ')[0]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Set Subscription Free Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showSetFreeOptionsDialog(),
                              icon: const Icon(Icons.free_breakfast),
                              label: const Text('Set Subscription Free'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Start Subscription Button (only show if currently free)
                          if (widget.teacher.subscriptionType == 'free')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showStartSubscriptionDialog(),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Paid Subscription'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Earnings Information Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Earnings Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildEarningsInfo(
                            'Total Earnings',
                            'LKR ${widget.teacher.totalEarnings.toStringAsFixed(2)}'
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Monthly Earnings by Class',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_earningsLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_monthlyEarnings.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No earnings data available for this teacher.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._monthlyEarnings.map((classData) => _buildClassEarningsCard(classData)),
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
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No students found for this teacher.'),
                      ),
                    )
                  else
                    ..._students.map((student) => Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (student.email != null) Text('Email: ${student.email}'),
                            if (student.phone != null) Text('Phone: ${student.phone}'),
                            if (student.classId != null)
                              Text('Class: ${student.classId!['name'] ?? 'Unknown'}'),
                            Text('Total Paid: LKR ${student.totalPaid.toStringAsFixed(2)}'),
                            Text('Payments: ${student.paymentCount}'),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassEarningsCard(Map<String, dynamic> classData) {
    final monthlyBreakdown = classData['monthlyBreakdown'] as List<dynamic>? ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    classData['className'] ?? 'Unknown Class',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'LKR ${(classData['totalEarnings'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${classData['studentCount'] ?? 0} students',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.payment, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${classData['paymentCount'] ?? 0} payments',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (monthlyBreakdown.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Monthly Breakdown:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: monthlyBreakdown.map<Widget>((monthData) {
                  final year = monthData['year'] ?? 0;
                  final month = monthData['month'] ?? 0;
                  final amount = monthData['amount'] ?? 0;
                  final paymentCount = monthData['paymentCount'] ?? 0;
                  
                  final monthNames = [
                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                  ];
                  final monthName = month >= 1 && month <= 12 ? monthNames[month - 1] : 'Unknown';
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$monthName $year',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'LKR ${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$paymentCount payments',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}