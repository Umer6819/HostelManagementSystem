import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notice_model.dart';
import '../models/student_warning_model.dart';
import '../services/notice_service.dart';
import '../services/student_warning_service.dart';
import 'student/student_profile_screen.dart';
import 'student/student_fees_screen.dart';
import 'student/student_complaints_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen>
    with SingleTickerProviderStateMixin {
  final NoticeService _noticeService = NoticeService();
  final StudentWarningService _warningService = StudentWarningService();
  late TabController _tabController;
  List<Notice> _notices = [];
  List<StudentWarning> _warnings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotices() async {
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final notices = await _noticeService.fetchActiveNotices();
      final warnings = uid != null
          ? await _warningService.fetchStudentWarnings(uid)
          : <StudentWarning>[];
      setState(() {
        _notices = notices;
        _warnings = warnings;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load notices: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Announcements'),
            Tab(text: 'My Profile'),
            Tab(text: 'Fees & Payments'),
            Tab(text: 'Complaints'),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNotices,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _loading && _tabController.index == 0
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnnouncementsTab(),
                const StudentProfileScreen(),
                const StudentFeesScreen(),
                const StudentComplaintsScreen(),
              ],
            ),
    );
  }

  Widget _buildAnnouncementsTab() {
    final hasWarnings = _warnings.isNotEmpty;
    final hasNotices = _notices.isNotEmpty;
    if (!hasWarnings && !hasNotices) {
      return const Center(child: Text('No announcements or warnings'));
    }
    return RefreshIndicator(
      onRefresh: _loadNotices,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _warnings.length + _notices.length,
        itemBuilder: (context, index) {
          if (index < _warnings.length) {
            return _buildWarningCard(_warnings[index]);
          }
          final noticeIndex = index - _warnings.length;
          final notice = _notices[noticeIndex];
          final isExpired =
              notice.expiresAt != null &&
              notice.expiresAt!.isBefore(DateTime.now());
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: notice.priority > 0
                    ? Colors.orange
                    : Colors.blue,
                child: const Icon(Icons.campaign, color: Colors.white),
              ),
              title: Text(
                notice.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notice.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notice.expiresAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        isExpired
                            ? 'Expired'
                            : 'Expires: ${notice.expiresAt!.toLocal().toString().split('.')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () => _showNoticeDetails(notice),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWarningCard(StudentWarning warning) {
    final severityColor = _getSeverityColor(warning.severity);
    final severityIcon = _getSeverityIcon(warning.severity);
    final isExpired =
        warning.expiresAt != null &&
        warning.expiresAt!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: severityColor.withValues(alpha: 0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severityColor,
          child: Icon(severityIcon, color: Colors.white),
        ),
        title: Text(
          '⚠ Warning: ${warning.reason}',
          style: TextStyle(fontWeight: FontWeight.bold, color: severityColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Severity: ${warning.severity.toUpperCase()}',
              style: TextStyle(
                color: severityColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Issued: ${_formatDate(warning.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (warning.expiresAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isExpired
                      ? 'Expired'
                      : 'Expires: ${_formatDate(warning.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'minor':
      default:
        return Colors.yellow[700]!;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Icons.error;
      case 'moderate':
        return Icons.warning;
      case 'minor':
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  void _showNoticeDetails(Notice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notice.title),
        content: SingleChildScrollView(child: Text(notice.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
