import 'package:flutter/material.dart';
import '../../services/reports_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();

  late Future<int> _totalStudents;
  late Future<double> _occupancyRate;
  late Future<double> _monthlyRevenue;
  late Future<int> _pendingPayments;
  late Future<Map<String, int>> _complaintStats;
  late Future<Map<String, int>> _capacityInfo;
  late Future<double> _pendingAmount;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  void _loadMetrics() {
    setState(() {
      _totalStudents = _reportsService.getTotalStudents();
      _occupancyRate = _reportsService.getRoomOccupancyRate();
      _monthlyRevenue = _reportsService.getTotalMonthlyRevenue();
      _pendingPayments = _reportsService.getPendingPaymentsCount();
      _complaintStats = _reportsService.getComplaintStats();
      _capacityInfo = _reportsService.getRoomCapacityInfo();
      _pendingAmount = _reportsService.getPendingPaymentsAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadMetrics();
          await Future.wait([
            _totalStudents,
            _occupancyRate,
            _monthlyRevenue,
            _pendingPayments,
            _complaintStats,
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Metrics Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMetricCard(
                    title: 'Total Students',
                    future: _totalStudents,
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _buildMetricCard(
                    title: 'Room Occupancy',
                    future: _occupancyRate,
                    icon: Icons.door_sliding_outlined,
                    color: Colors.green,
                    formatter: (value) => '${value.toStringAsFixed(1)}%',
                  ),
                  _buildMetricCard(
                    title: 'Monthly Revenue',
                    future: _monthlyRevenue,
                    icon: Icons.attach_money,
                    color: Colors.orange,
                    formatter: (value) => '\$${value.toStringAsFixed(2)}',
                  ),
                  _buildMetricCard(
                    title: 'Pending Payments',
                    future: _pendingPayments,
                    icon: Icons.payment,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Room Capacity Section
              const Text(
                'Room Capacity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, int>>(
                future: _capacityInfo,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? {};
                  final total = data['totalCapacity'] ?? 0;
                  final current = data['totalOccupancy'] ?? 0;
                  final percentage = total > 0 ? (current / total) * 100 : 0.0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$current / $total beds occupied',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage > 80
                                    ? Colors.red
                                    : percentage > 60
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Pending Payments Section
              const Text(
                'Pending Payments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Count'),
                          FutureBuilder<int>(
                            future: _pendingPayments,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  snapshot.data.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                );
                              }
                              return const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount Due'),
                          FutureBuilder<double>(
                            future: _pendingAmount,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  '\$${snapshot.data!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                );
                              }
                              return const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Complaint Statistics Section
              const Text(
                'Complaint Statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, int>>(
                future: _complaintStats,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final stats = snapshot.data ?? {};
                  final pending = stats['pending'] ?? 0;
                  final inProgress = stats['in_progress'] ?? 0;
                  final resolved = stats['resolved'] ?? 0;
                  final total = stats['total'] ?? 0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Complaints',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                total.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildComplaintStat(
                            'Pending',
                            pending,
                            Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          _buildComplaintStat(
                            'In Progress',
                            inProgress,
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildComplaintStat(
                            'Resolved',
                            resolved,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required Future future,
    required IconData icon,
    required Color color,
    String Function(dynamic)? formatter,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (snapshot.hasError) {
                  return const Text('Error', style: TextStyle(fontSize: 14));
                }
                final value =
                    formatter?.call(snapshot.data) ?? snapshot.data.toString();
                return Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintStat(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
