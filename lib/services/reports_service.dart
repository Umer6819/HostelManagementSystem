import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsService {
  final supabase = Supabase.instance.client;

  // Fetch total number of students
  Future<int> getTotalStudents() async {
    final response = await supabase
        .from('students')
        .select('id', const FetchOptions(count: CountOption.exact));
    return response.count ?? 0;
  }

  // Fetch total number of rooms
  Future<int> getTotalRooms() async {
    final response = await supabase
        .from('rooms')
        .select('id', const FetchOptions(count: CountOption.exact));
    return response.count ?? 0;
  }

  // Calculate room occupancy rate (percentage of beds occupied)
  Future<double> getRoomOccupancyRate() async {
    final capacityInfo = await getRoomCapacityInfo();
    final totalCapacity = capacityInfo['totalCapacity'] ?? 0;
    final totalOccupied = capacityInfo['totalOccupancy'] ?? 0;
    if (totalCapacity == 0) return 0.0;
    return (totalOccupied / totalCapacity) * 100;
  }

  // Fetch total capacity and current occupancy
  Future<Map<String, int>> getRoomCapacityInfo() async {
    final rooms = await supabase.from('rooms').select('capacity, occupied');
    int totalCapacity = 0;
    int totalOccupancy = 0;
    for (final room in rooms as List) {
      totalCapacity += (room['capacity'] as int? ?? 0);
      totalOccupancy += (room['occupied'] as int? ?? 0);
    }
    return {'totalCapacity': totalCapacity, 'totalOccupancy': totalOccupancy};
  }

  // Fetch total revenue from payments (sum of fee amounts for paid payments)
  Future<double> getTotalMonthlyRevenue({int? month, int? year}) async {
    var query = supabase
        .from('payments')
        .select('fees(amount)')
        .eq('status', true);

    if (month != null && year != null) {
      // Filter by month/year if provided
      final startDate = DateTime(year, month, 1).toIso8601String();
      final endDate = DateTime(year, month + 1, 1).toIso8601String();
      query = query.gte('created_at', startDate).lt('created_at', endDate);
    }

    final response = await query;
    double total = 0.0;
    for (final payment in response as List) {
      final feeData = payment['fees'];
      if (feeData != null && feeData is Map) {
        total += (feeData['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  // Fetch count of pending payments
  Future<int> getPendingPaymentsCount() async {
    final response = await supabase
        .from('payments')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('status', false);
    return response.count ?? 0;
  }

  // Fetch total pending payment amount
  Future<double> getPendingPaymentsAmount() async {
    final response = await supabase
        .from('payments')
        .select('fees(amount)')
        .eq('status', false);
    double total = 0.0;
    for (final payment in response as List) {
      final feeData = payment['fees'];
      if (feeData != null && feeData is Map) {
        total += (feeData['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  // Fetch complaint statistics
  Future<Map<String, int>> getComplaintStats() async {
    final response = await supabase.from('complaints').select('status');

    int pending = 0;
    int inProgress = 0;
    int resolved = 0;

    for (final complaint in response as List) {
      final status = complaint['status'] as String?;
      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'resolved':
          resolved++;
          break;
      }
    }

    return {
      'pending': pending,
      'in_progress': inProgress,
      'resolved': resolved,
      'total': pending + inProgress + resolved,
    };
  }

  // Fetch monthly revenue trend (last 6 months)
  Future<List<Map<String, dynamic>>> getMonthlyRevenueTrend() async {
    final now = DateTime.now();
    final trends = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final revenue = await getTotalMonthlyRevenue(
        month: date.month,
        year: date.year,
      );
      trends.add({
        'month': _monthName(date.month),
        'revenue': revenue,
        'date': date,
      });
    }

    return trends;
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
