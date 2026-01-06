import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class PaymentProofsScreen extends StatefulWidget {
  const PaymentProofsScreen({super.key});

  @override
  State<PaymentProofsScreen> createState() => _PaymentProofsScreenState();
}

class _PaymentProofsScreenState extends State<PaymentProofsScreen> {
  List<dynamic> _paymentProofs = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadPaymentProofs();
    // Start polling for real-time payment proof updates
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadPaymentProofsSilently();
    });
  }

  Future<void> _loadPaymentProofsSilently() async {
    try {
      final proofs = await ApiService.getPaymentProofs();
      final previousCount = _paymentProofs.length;
      if (mounted && proofs.length != previousCount) {
        final newProofsCount = proofs.length - previousCount;
        if (newProofsCount > 0) {
          // Show notification for new payment proofs
          await NotificationService().showPaymentProofNotification(newProofsCount);
        }
        setState(() {
          _paymentProofs = proofs;
        });
      }
    } catch (e) {
      // Silently handle polling errors
      print('Payment proofs polling error: $e');
    }
  }

  Future<void> _loadPaymentProofs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final proofs = await ApiService.getPaymentProofs();
      
      // Update shared preferences with current count
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_seen_payment_proofs', proofs.length);
      
      setState(() {
        _paymentProofs = proofs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewPaymentProof(String proofId, String action, String adminEmail) async {
    try {
      await ApiService.reviewPaymentProof(proofId, action, adminEmail, null);
      _loadPaymentProofs(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment proof ${action}d successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to $action payment proof: $e')),
      );
    }
  }

  void _showReviewDialog(dynamic proof) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = authProvider.adminEmail ?? 'admin@example.com';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Payment Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${proof['userEmail']}'),
            Text('Type: ${proof['subscriptionType']}'),
            Text('Amount: ${proof['amount']}'),
            const SizedBox(height: 16),
            const Text('Payment Proof:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Image.network(
                    proof['paymentProofUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('Failed to load image'));
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image URL: ${proof['paymentProofUrl']}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _reviewPaymentProof(proof['_id'], 'reject', adminEmail);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _reviewPaymentProof(proof['_id'], 'approve', adminEmail);
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Proofs'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentProofs,
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
                        onPressed: _loadPaymentProofs,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _paymentProofs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No payment proofs found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _paymentProofs.length,
                      itemBuilder: (context, index) {
                        final proof = _paymentProofs[index];
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
                                    Icon(
                                      proof['status'] == 'pending'
                                          ? Icons.pending
                                          : proof['status'] == 'approved'
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                      color: proof['status'] == 'pending'
                                          ? Colors.orange
                                          : proof['status'] == 'approved'
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Payment Proof - ${proof['status'].toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(proof['createdAt']),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow('User Email', proof['userEmail']),
                                _buildDetailRow('Subscription Type', proof['subscriptionType']),
                                _buildDetailRow('Amount', proof['amount']),
                                if (proof['status'] != 'pending') ...[
                                  _buildDetailRow('Reviewed By', proof['reviewedBy'] ?? 'N/A'),
                                  _buildDetailRow('Reviewed At', proof['reviewedAt'] != null ? _formatDate(proof['reviewedAt']) : 'N/A'),
                                ],
                                const SizedBox(height: 12),
                                if (proof['status'] == 'pending')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showReviewDialog(proof),
                                          icon: const Icon(Icons.visibility),
                                          label: const Text('Review'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (proof['status'] == 'approved')
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Payment Approved',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.cancel,
                                          color: Colors.red.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Payment Rejected',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (proof['reviewNotes'] != null && proof['reviewNotes'].isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  proof['reviewNotes'],
                                                  style: TextStyle(
                                                    color: Colors.red.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
            width: 120,
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

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      // Handle the new date object format from backend
      if (dateValue is Map) {
        // If it's an object with dateString, use that
        if (dateValue['dateString'] != null) {
          return dateValue['dateString'];
        }
        // If it has isoString, parse it
        if (dateValue['isoString'] != null) {
          final date = DateTime.parse(dateValue['isoString']);
          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
        }
      }
      // Fallback: if it's a string, parse it
      if (dateValue is String) {
        final date = DateTime.parse(dateValue);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
      }
      return dateValue.toString();
    } catch (e) {
      return dateValue.toString();
    }
  }
}