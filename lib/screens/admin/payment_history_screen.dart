import 'package:flutter/material.dart';
import '../../models/payment_model.dart';
import '../../models/student_model.dart';
import '../../services/payment_service.dart';
import '../../services/student_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  final StudentService _studentService = StudentService();

  List<Payment> _allPayments = [];
  List<Payment> _filteredPayments = [];
  List<Student> _students = [];
  bool _isLoading = true;
  String? _selectedStudentId;
  bool? _selectedStatus; // null = all, true = paid, false = pending

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await _paymentService.fetchAllPayments();
      final students = await _studentService.fetchAllStudents();

      setState(() {
        _allPayments = payments;
        _students = students;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading payments: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredPayments = _allPayments.where((payment) {
      // Filter by student
      if (_selectedStudentId != null &&
          payment.studentId != _selectedStudentId) {
        return false;
      }

      // Filter by status
      if (_selectedStatus != null && payment.status != _selectedStatus) {
        return false;
      }

      return true;
    }).toList();

    // Sort by date descending
    _filteredPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _getStudentName(String studentId) {
    try {
      return _students.firstWhere((s) => s.id == studentId).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _updatePaymentStatus(Payment payment, bool newStatus) async {
    try {
      await _paymentService.updatePaymentStatus(payment.id, newStatus);
      await _loadPayments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment marked as ${newStatus ? 'Paid' : 'Pending'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating payment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                // Student filter
                DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedStudentId,
                  hint: const Text('All Students'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Students'),
                    ),
                    ..._students.map(
                      (student) => DropdownMenuItem<String?>(
                        value: student.id,
                        child: Text(student.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStudentId = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Status filter
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool?>(
                        segments: const [
                          ButtonSegment<bool?>(value: null, label: Text('All')),
                          ButtonSegment<bool?>(
                            value: false,
                            label: Text('Pending'),
                          ),
                          ButtonSegment<bool?>(
                            value: true,
                            label: Text('Paid'),
                          ),
                        ],
                        selected: {_selectedStatus},
                        onSelectionChanged: (Set<bool?> newSelection) {
                          setState(() {
                            _selectedStatus = newSelection.first;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Payment List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                ? Center(
                    child: Text(
                      _allPayments.isEmpty
                          ? 'No payments found'
                          : 'No payments match your filters',
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = _filteredPayments[index];
                      final studentName = _getStudentName(payment.studentId);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(studentName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Month: ${payment.month}'),
                              Text('Amount: Rs. ${payment.amount}'),
                              Text(
                                'Created: ${payment.createdAt.toString().split('.')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (payment.paidAt != null)
                                Text(
                                  'Paid: ${payment.paidAt.toString().split('.')[0]}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: payment.status
                                      ? Colors.green
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  payment.status ? 'Paid' : 'Pending',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            _showPaymentDetails(context, payment);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, Payment payment) {
    final studentName = _getStudentName(payment.studentId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Payment Details - $studentName'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Month:', payment.month),
                _buildDetailRow('Amount:', 'Rs. ${payment.amount}'),
                _buildDetailRow(
                  'Status:',
                  payment.status ? 'Paid' : 'Pending',
                  statusColor: payment.status ? Colors.green : Colors.orange,
                ),
                _buildDetailRow(
                  'Created:',
                  payment.createdAt.toString().split('.')[0],
                ),
                if (payment.paidAt != null)
                  _buildDetailRow(
                    'Paid Date:',
                    payment.paidAt.toString().split('.')[0],
                    statusColor: Colors.green,
                  ),
              ],
            ),
          ),
          actions: [
            if (!payment.status)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updatePaymentStatus(payment, true);
                },
                child: const Text('Mark as Paid'),
              ),
            if (payment.status)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updatePaymentStatus(payment, false);
                },
                child: const Text('Mark as Pending'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (statusColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
