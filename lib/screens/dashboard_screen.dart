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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
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
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadStats();
                      provider.loadTeachers();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = provider.stats;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (stats != null) ...[
                const Text(
                  'Statistics',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatRow('Total Teachers', stats['totalTeachers'].toString()),
                        _buildStatRow('Active Teachers', stats['activeTeachers'].toString()),
                        _buildStatRow('Inactive Teachers', stats['inactiveTeachers'].toString()),
                        _buildStatRow('Total Students', stats['totalStudents'].toString()),
                        _buildStatRow('Total Classes', stats['totalClasses'].toString()),
                        _buildStatRow('Total Earnings', '\$${stats['totalEarnings'].toStringAsFixed(2)}'),
                        _buildStatRow('Total Admins', stats['totalAdmins'].toString()),
                        _buildStatRow('Super Admins', stats['superAdmins'].toString()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Teachers'),
                subtitle: Text('View and manage all teachers (${provider.teachers.length})'),
                leading: const Icon(Icons.people),
                onTap: () => Navigator.of(context).pushNamed('/teachers'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}