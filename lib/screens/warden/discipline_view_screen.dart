import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_warning_model.dart';
import '../../models/misconduct_report_model.dart';
import '../../services/student_warning_service.dart';
import '../../services/misconduct_report_service.dart';

class DisciplineViewScreen extends StatefulWidget {
  const DisciplineViewScreen({Key? key}) : super(key: key);

  @override
  State<DisciplineViewScreen> createState() => _DisciplineViewScreenState();
}

class _DisciplineViewScreenState extends State<DisciplineViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _warningService = StudentWarningService();
  final _reportService = MisconductReportService();
  
  Map<String, List<StudentWarning>> _studentWarnings = {};
  Map<String, List<MisconductReport>> _studentReports = {};
  bool _loading = false;
  
  String _selectedStudentId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final warnings = await _warningService.fetchAllWarnings();
      final reports = await _reportService.fetchAllReports();
      
      // Group by student
      final warningsMap = <String, List<StudentWarning>>{};
      final reportsMap = <String, List<MisconductReport>>{};
      
      for (var warning in warnings) {
        if (!warningsMap.containsKey(warning.studentId)) {
          warningsMap[warning.studentId] = [];
        }
        warningsMap[warning.studentId]!.add(warning);
      }
      
      for (var report in reports) {
        if (!reportsMap.containsKey(report.studentId)) {
          reportsMap[report.studentId] = [];
        }
        reportsMap[report.studentId]!.add(report);
      }
      
      setState(() {
        _studentWarnings = warningsMap;
        _studentReports = reportsMap;
        _selectedStudentId = warningsMap.keys.firstOrNull ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading discipline data: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
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
        title: const Text('Student Discipline History'),
        backgroundColor: Colors.indigo,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Warnings'),
            Tab(text: 'Misconduct Reports'),
          ],
        ),
      ),
      floatingActionButton: _selectedStudentId.isNotEmpty
          ? FloatingActionButton(
              onPressed: _tabController.index == 0
                  ? _showIssueWarningDialog
                  : _showCreateReportDialog,
              backgroundColor: Colors.indigo,
              child: Icon(_tabController.index == 0 ? Icons.warning : Icons.report),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _studentWarnings.isEmpty && _studentReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No discipline records'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Student selector dropdown
                    if (_studentWarnings.isNotEmpty || _studentReports.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: DropdownButton<String>(
                          hint: const Text('Select Student'),
                          value: _selectedStudentId.isNotEmpty ? _selectedStudentId : null,
                          isExpanded: true,
                          items: {
                            ..._studentWarnings.keys,
                            ..._studentReports.keys,
                          }
                              .toList()
                              .map((studentId) => DropdownMenuItem(
                                    value: studentId,
                                    child: Text('Student: ${studentId.substring(0, 8)}...'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedStudentId = value ?? '');
                          },
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Warnings tab
                          _buildWarningsView(),
                          // Reports tab
                          _buildReportsView(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showIssueWarningDialog() {
    final reasonController = TextEditingController();
    String selectedSeverity = 'minor';
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Warning'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: $_selectedStudentId', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  hintText: 'Enter reason for warning...',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Severity', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<String>(
                  value: selectedSeverity,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'minor', child: Text('Minor')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'severe', child: Text('Severe')),
                  ],
                  onChanged: (value) => setState(() => selectedSeverity = value ?? 'minor'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Expiry Date (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    (context as Element).markNeedsBuild();
                    expiryDate = picked;
                  }
                },
                child: Text(
                  expiryDate != null
                      ? expiryDate.toString().split(' ')[0]
                      : 'Select Date',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final wardenId = await _getWardenId();
                if (wardenId == null) throw Exception('Warden not authenticated');

                await _warningService.issueWarning(
                  studentId: _selectedStudentId,
                  issuedBy: wardenId,
                  reason: reasonController.text,
                  severity: selectedSeverity,
                  expiresAt: expiryDate,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Warning issued successfully')),
                  );
                  Navigator.pop(context);
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Issue Warning'),
          ),
        ],
      ),
    );
  }

  void _showCreateReportDialog() {
    final incidentTypeController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedSeverity = 'moderate';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Misconduct Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: $_selectedStudentId', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Incident Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: incidentTypeController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  hintText: 'E.g., Unauthorized absence, Noise complaint...',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  hintText: 'Provide detailed description of the incident...',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Severity', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<String>(
                  value: selectedSeverity,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'minor', child: Text('Minor')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'severe', child: Text('Severe')),
                  ],
                  onChanged: (value) => setState(() => selectedSeverity = value ?? 'moderate'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final wardenId = await _getWardenId();
                if (wardenId == null) throw Exception('Warden not authenticated');

                await _reportService.createReport(
                  studentId: _selectedStudentId,
                  reportedBy: wardenId,
                  incidentType: incidentTypeController.text,
                  description: descriptionController.text,
                  severity: selectedSeverity,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report created successfully')),
                  );
                  Navigator.pop(context);
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create Report'),
          ),
        ],
      ),
    );
  }

  Future<String?> _getWardenId() async {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (e) {
      return null;
    }
  }

  Widget _buildWarningsView() {
    if (_selectedStudentId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Select a student to view warnings'),
          ],
        ),
      );
    }

    final warnings = _studentWarnings[_selectedStudentId] ?? [];
    final activeWarnings = warnings.where((w) => w.isActive).toList();
    final inactiveWarnings = warnings.where((w) => !w.isActive).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          if (activeWarnings.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Warnings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...activeWarnings.map((warning) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  warning.severity.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor: _getSeverityColor(warning.severity),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  warning.reason,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Issued by: ${warning.issuedBy.substring(0, 8)}...',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Date: ${warning.createdAt.toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (warning.expiresAt != null)
                            Text(
                              'Expires: ${warning.expiresAt.toString().split(' ')[0]}',
                              style: const TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
          if (inactiveWarnings.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inactive Warnings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...inactiveWarnings.map((warning) => Card(
                    color: Colors.grey[100],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: const Text(
                                  'INACTIVE',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  warning.reason,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Issued: ${warning.createdAt.toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
          if (warnings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  const Text('No warnings for this student'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportsView() {
    if (_selectedStudentId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Select a student to view misconduct reports'),
          ],
        ),
      );
    }

    final reports = _studentReports[_selectedStudentId] ?? [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: reports.isEmpty
            ? Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.verified, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  const Text('No misconduct reports for this student'),
                ],
              )
            : Column(
                children: reports
                    .map((report) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    report.severity.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  backgroundColor: _getSeverityColor(report.severity),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    report.status.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  backgroundColor: _getStatusColor(report.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              report.incidentType,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(report.description),
                            const SizedBox(height: 8),
                            Text(
                              'Reported: ${report.createdAt.toString().split(' ')[0]}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (report.adminRemarks != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Admin Remarks:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.adminRemarks ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (report.actionTaken != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Action Taken:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.actionTaken ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ))
                    .toList(),
              ),
      ),
    );
  }
}
