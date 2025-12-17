import 'package:flutter/material.dart';

import '../../models/fee_model.dart';
import '../../models/payment_model.dart';
import '../../services/fee_service.dart';
import '../../services/payment_service.dart';

class StudentFeesScreen extends StatefulWidget {
  const StudentFeesScreen({super.key});

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen> {
  final _paymentService = PaymentService();
  final _feeService = FeeService();

  List<Payment> _payments = [];
  List<Fee> _fees = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeesAndPayments();
  }

  Future<void> _loadFeesAndPayments() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final uid = _paymentService.supabase.auth.currentUser?.id;
      if (uid == null) {
        setState(() {
          _error = 'User not authenticated';
          _loading = false;
        });
        return;
      }

      final payments = await _paymentService.fetchPaymentsByStudent(uid);
      final fees = await _feeService.fetchAllFees();

      if (!mounted) return;
      setState(() {
        _payments = payments;
        _fees = fees;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load fees: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFeesAndPayments,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees & Payments'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFeesAndPayments),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeesAndPayments,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNewFeesSection(),
              const SizedBox(height: 24),
              _buildPaymentSummarySection(),
              const SizedBox(height: 24),
              _buildPaymentHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewFeesSection() {
    if (_fees.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.receipt_long, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'New Fees',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(child: Text('No fees available')),
            ],
          ),
        ),
      );
    }

    final currentFee = _fees.first;
    final currentPayment = _payments.isNotEmpty ? _payments.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.receipt_long, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Current Fee',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Month', currentFee.month),
            const SizedBox(height: 12),
            _buildDetailRow('Amount', 'Rs. ${currentFee.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            if (currentPayment != null)
              _buildDetailRow(
                'Status',
                currentPayment.status ? 'Paid' : 'Pending',
                statusColor: currentPayment.status ? Colors.green : Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummarySection() {
    final totalFees = _payments.fold<double>(0, (sum, p) => sum + p.amount);
    final paidAmount = _payments
        .where((p) => p.status)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final pendingAmount = _payments
        .where((p) => !p.status)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total',
            'Rs. ${totalFees.toStringAsFixed(2)}',
            Colors.blue,
            Icons.payment,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Paid',
            'Rs. ${paidAmount.toStringAsFixed(2)}',
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Pending',
            'Rs. ${pendingAmount.toStringAsFixed(2)}',
            Colors.orange,
            Icons.pending,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.history, color: Colors.purple, size: 24),
            SizedBox(width: 8),
            Text(
              'Payment History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_payments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No payment history')),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              return _buildPaymentHistoryCard(_payments[index]);
            },
          ),
      ],
    );
  }

  Widget _buildPaymentHistoryCard(Payment payment) {
    final statusColor = payment.status ? Colors.green : Colors.orange;
    final statusLabel = payment.status ? 'Paid' : 'Pending';
    final statusIcon =
        payment.status ? Icons.check_circle : Icons.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.month,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (payment.status && payment.paidAt != null)
                      Text(
                        'Paid: ${_formatDate(payment.paidAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Created: ${_formatDate(payment.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
