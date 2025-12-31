import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/super_admin_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadStats();
      context.read<SuperAdminProvider>().loadTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.loadStats();
                      provider.loadTeachers();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = provider.stats;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Super Admin Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Monitor and manage your attendance system',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (stats != null) ...[
                  const Text(
                    'Statistics Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        'Total Teachers',
                        stats['totalTeachers'].toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Active Teachers',
                        stats['activeTeachers'].toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Inactive Teachers',
                        stats['inactiveTeachers'].toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                      _buildStatCard(
                        'Total Students',
                        stats['totalStudents'].toString(),
                        Icons.school,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Total Classes',
                        stats['totalClasses'].toString(),
                        Icons.class_,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        'Total Earnings',
                        'LKR ${stats['totalEarnings'].toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.teal,
                      ),
                      _buildStatCard(
                        'Total Admins',
                        stats['totalAdmins'].toString(),
                        Icons.admin_panel_settings,
                        Colors.indigo,
                      ),
                      _buildStatCard(
                        'Super Admins',
                        stats['superAdmins'].toString(),
                        Icons.supervisor_account,
                        Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
                const Text(
                  'Management Tools',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.people, color: Colors.white),
                    ),
                    title: const Text(
                      'Teachers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'View and manage all teachers (${provider.teachers.length})',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.of(context).pushNamed('/teachers'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.report_problem, color: Colors.white),
                    ),
                    title: const Text(
                      'Problem Reports',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'View problem reports from teachers',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.of(context).pushNamed('/problem-reports'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.payment, color: Colors.white),
                    ),
                    title: const Text(
                      'Payment Proofs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Review payment proofs and activate accounts',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.of(context).pushNamed('/payment-proofs'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(
                (color.r * 255).round().clamp(0, 255),
                (color.g * 255).round().clamp(0, 255),
                (color.b * 255).round().clamp(0, 255),
                0.1,
              ),
              Color.fromRGBO(
                (color.r * 255).round().clamp(0, 255),
                (color.g * 255).round().clamp(0, 255),
                (color.b * 255).round().clamp(0, 255),
                0.05,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}