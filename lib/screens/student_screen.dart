import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import '../services/notice_service.dart';
import 'student/student_profile_screen.dart';
import 'student/student_fees_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen>
    with SingleTickerProviderStateMixin {
  final NoticeService _noticeService = NoticeService();
  late TabController _tabController;
  List<Notice> _notices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final items = await _noticeService.fetchActiveNotices();
      setState(() => _notices = items);
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
              ],
            ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return _notices.isEmpty
        ? const Center(child: Text('No announcements'))
        : RefreshIndicator(
            onRefresh: _loadNotices,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notices.length,
              itemBuilder: (context, index) {
                final notice = _notices[index];
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
