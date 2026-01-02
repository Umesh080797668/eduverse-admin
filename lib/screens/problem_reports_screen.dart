import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ProblemReportsScreen extends StatefulWidget {
  const ProblemReportsScreen({super.key});

  @override
  State<ProblemReportsScreen> createState() => _ProblemReportsScreenState();
}

class _ProblemReportsScreenState extends State<ProblemReportsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _problemReports = [];
  List<dynamic> _featureRequests = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllReports();
    // Start polling for real-time updates (every 30 seconds)
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadReportsSilently();
    });
  }

  Future<void> _loadReportsSilently() async {
    try {
      final problems = await ApiService.getProblemReports();
      final features = await ApiService.getFeatureRequests();
      
      if (mounted) {
        final previousProblemCount = _problemReports.length;
        final previousFeatureCount = _featureRequests.length;
        
        // Check for new problem reports
        if (problems.length > previousProblemCount) {
          final newCount = problems.length - previousProblemCount;
          await NotificationService().showProblemReportNotification(newCount);
        }
        
        // Check for new feature requests
        if (features.length > previousFeatureCount) {
          final newCount = features.length - previousFeatureCount;
          await NotificationService().showFeatureRequestNotification(newCount);
        }
        
        setState(() {
          _problemReports = problems;
          _featureRequests = features;
        });
      }
    } catch (e) {
      // Silently handle polling errors
      print('Reports polling error: $e');
    }
  }

  Future<void> _loadAllReports() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final problems = await ApiService.getProblemReports();
      final features = await ApiService.getFeatureRequests();
      
      setState(() {
        _problemReports = problems;
        _featureRequests = features;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Requests'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.report_problem),
              text: 'Problems (${_problemReports.length})',
            ),
            Tab(
              icon: const Icon(Icons.lightbulb_outline),
              text: 'Features (${_featureRequests.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_error',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadAllReports,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProblemReportsList(),
                    _buildFeatureRequestsList(),
                  ],
                ),
    );
  }

  Widget _buildProblemReportsList() {
    if (_problemReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_problem, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No problem reports found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _problemReports.length,
      itemBuilder: (context, index) {
        final report = _problemReports[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.report_problem, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Problem Report',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildUserTypeBadge(report['userType']),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(report['createdAt']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow('User Email', report['userEmail']),
                if (report['teacherId'] != null)
                  _buildDetailRow('Teacher ID', report['teacherId']),
                if (report['studentId'] != null)
                  _buildDetailRow('Student ID', report['studentId']),
                if (report['appVersion'] != null)
                  _buildDetailRow('App Version', report['appVersion']),
                if (report['device'] != null)
                  _buildDetailRow('Device', report['device']),
                const SizedBox(height: 12),
                const Text(
                  'Issue Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report['issueDescription'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRequestsList() {
    if (_featureRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No feature requests found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Sort feature requests by bid price (highest first)
    final sortedRequests = List<dynamic>.from(_featureRequests);
    sortedRequests.sort((a, b) {
      final priceA = (a['bidPrice'] ?? 0).toDouble();
      final priceB = (b['bidPrice'] ?? 0).toDouble();
      return priceB.compareTo(priceA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedRequests.length,
      itemBuilder: (context, index) {
        final request = sortedRequests[index];
        final bidPrice = (request['bidPrice'] ?? 0).toDouble();
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Feature Request',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildUserTypeBadge(request['userType']),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(request['createdAt']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bid: LKR ${bidPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('User Email', request['userEmail']),
                if (request['teacherId'] != null)
                  _buildDetailRow('Teacher ID', request['teacherId']),
                if (request['studentId'] != null)
                  _buildDetailRow('Student ID', request['studentId']),
                if (request['appVersion'] != null)
                  _buildDetailRow('App Version', request['appVersion']),
                if (request['device'] != null)
                  _buildDetailRow('Device', request['device']),
                const SizedBox(height: 12),
                const Text(
                  'Feature Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request['featureDescription'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserTypeBadge(String? userType) {
    if (userType == null) return const SizedBox.shrink();
    
    final color = userType == 'teacher' ? Colors.blue : Colors.purple;
    final icon = userType == 'teacher' ? Icons.school : Icons.person;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            userType.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}