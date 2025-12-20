import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_warning_model.dart';
import '../../models/misconduct_report_model.dart';
import '../../services/student_warning_service.dart';
import '../../services/misconduct_report_service.dart';

class DisciplineManagementScreen extends StatefulWidget {
  const DisciplineManagementScreen({Key? key}) : super(key: key);

  @override
  State<DisciplineManagementScreen> createState() =>
      _DisciplineManagementScreenState();
}

class _DisciplineManagementScreenState extends State<DisciplineManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _warningService = StudentWarningService();
  final _reportService = MisconductReportService();

  List<StudentWarning> _warnings = [];
  List<MisconductReport> _reports = [];
  bool _loadingWarnings = false;
  bool _loadingReports = false;

  String _selectedReportStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWarnings();
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWarnings() async {
    setState(() => _loadingWarnings = true);
    try {
      final warnings = await _warningService.fetchAllWarnings();
      setState(() => _warnings = warnings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading warnings: $e')));
      }
    } finally {
      setState(() => _loadingWarnings = false);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    try {
      final reports = await _reportService.fetchReportsByStatus(
        _selectedReportStatus,
      );
      setState(() => _reports = reports);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
      }
    } finally {
      setState(() => _loadingReports = false);
    }
  }

  void _showReviewDialog(MisconductReport report) {
    final remarksController = TextEditingController(
      text: report.adminRemarks ?? '',
    );
    final actionController = TextEditingController(
      text: report.actionTaken ?? '',
    );
    String selectedStatus = report.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Misconduct Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Student ID', report.studentId),
              _buildDetailRow('Incident Type', report.incidentType),
              _buildDetailRow('Severity', report.severity),
              const SizedBox(height: 12),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(report.description),
              ),
              const SizedBox(height: 12),
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'under_review',
                      child: Text('Under Review'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved'),
                    ),
                    DropdownMenuItem(
                      value: 'dismissed',
                      child: Text('Dismissed'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedStatus = value ?? 'pending'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Admin Remarks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  hintText: 'Enter remarks about the incident...',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Action Taken',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: actionController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  hintText: 'Describe the action taken...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              try {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) throw Exception('User not authenticated');

                await _reportService.reviewReport(
                  reportId: report.id,
                  status: selectedStatus,
                  adminId: userId,
                  adminRemarks: remarksController.text.isNotEmpty
                      ? remarksController.text
                      : null,
                  actionTaken: actionController.text.isNotEmpty
                      ? actionController.text
                      : null,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report reviewed successfully'),
                    ),
                  );
                  Navigator.pop(context);
                  _loadReports();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return Colors.yellow;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discipline Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Warnings'),
            Tab(text: 'Misconduct Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Warnings Tab
          _buildWarningsTab(),
          // Reports Tab
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildWarningsTab() {
    return _loadingWarnings
        ? const Center(child: CircularProgressIndicator())
        : _warnings.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No warnings issued yet'),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _warnings.length,
            itemBuilder: (context, index) {
              final warning = _warnings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSeverityColor(warning.severity),
                    child: const Icon(Icons.warning, color: Colors.white),
                  ),
                  title: Text(
                    'Student: ${warning.studentId.substring(0, 8)}...',
                  ),
                  subtitle: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Reason: ${warning.reason}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              warning.severity.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _getSeverityColor(
                              warning.severity,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (warning.isActive)
                            const Chip(
                              label: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Colors.green,
                            )
                          else
                            const Chip(
                              label: Text(
                                'INACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Colors.grey,
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Deactivate'),
                        onTap: () async {
                          try {
                            await _warningService.deactivateWarning(warning.id);
                            _loadWarnings();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () async {
                          try {
                            await _warningService.deleteWarning(warning.id);
                            _loadWarnings();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Pending'),
                  selected: _selectedReportStatus == 'pending',
                  onSelected: (selected) {
                    setState(() => _selectedReportStatus = 'pending');
                    _loadReports();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Under Review'),
                  selected: _selectedReportStatus == 'under_review',
                  onSelected: (selected) {
                    setState(() => _selectedReportStatus = 'under_review');
                    _loadReports();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Resolved'),
                  selected: _selectedReportStatus == 'resolved',
                  onSelected: (selected) {
                    setState(() => _selectedReportStatus = 'resolved');
                    _loadReports();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Dismissed'),
                  selected: _selectedReportStatus == 'dismissed',
                  onSelected: (selected) {
                    setState(() => _selectedReportStatus = 'dismissed');
                    _loadReports();
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loadingReports
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text('No $_selectedReportStatus reports'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getSeverityColor(report.severity),
                          child: const Icon(Icons.report, color: Colors.white),
                        ),
                        title: Text(
                          '${report.incidentType} - ${report.studentId.substring(0, 8)}...',
                        ),
                        subtitle: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              report.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    report.severity.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: _getSeverityColor(
                                    report.severity,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    report.status
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: _getStatusColor(
                                    report.status,
                                  ),
                                ),
                              ],
                            ),
                            if (report.adminRemarks != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Admin: ${report.adminRemarks}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () => _showReviewDialog(report),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
