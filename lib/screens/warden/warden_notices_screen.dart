import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notice_model.dart';
import '../../services/notice_service.dart';

class WardenNoticesScreen extends StatefulWidget {
  const WardenNoticesScreen({super.key});

  @override
  State<WardenNoticesScreen> createState() => _WardenNoticesScreenState();
}

class _WardenNoticesScreenState extends State<WardenNoticesScreen>
    with SingleTickerProviderStateMixin {
  final NoticeService _noticeService = NoticeService();
  late TabController _tabController;

  List<Notice> _boardNotices = [];
  List<Notice> _myNotices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Board = active non-expired
      final board = await _noticeService.fetchActiveNotices();
      // My notices = all notices, RLS will scope to own
      final mine = await _noticeService.fetchAllNotices();
      setState(() {
        _boardNotices = board;
        _myNotices = mine;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Board'),
            Tab(text: 'My Notices'),
          ],
        ),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildBoard(), _buildMine()],
            ),
    );
  }

  Widget _buildBoard() {
    if (_boardNotices.isEmpty) {
      return const Center(child: Text('No active notices'));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _boardNotices.length,
        itemBuilder: (context, index) {
          final n = _boardNotices[index];
          final isExpired =
              n.expiresAt != null && n.expiresAt!.isBefore(DateTime.now());
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                Icons.campaign,
                color: isExpired
                    ? Colors.grey
                    : (n.priority > 0 ? Colors.orange : Colors.blue),
              ),
              title: Text(
                n.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(n.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                  if (n.expiresAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        isExpired
                            ? 'Expired'
                            : 'Expires: ${n.expiresAt!.toLocal().toString().split('.')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () => _showDetails(n),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMine() {
    if (_myNotices.isEmpty) {
      return const Center(child: Text('You have not created any notices yet'));
    }
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myNotices.length,
        itemBuilder: (context, index) {
          final n = _myNotices[index];
          final isExpired =
              n.expiresAt != null && n.expiresAt!.isBefore(DateTime.now());
          final canManage = n.createdBy == uid;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                Icons.assignment,
                color: n.isActive ? Colors.green : Colors.grey,
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: n.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      Chip(
                        label: Text(n.isActive ? 'ACTIVE' : 'INACTIVE'),
                        backgroundColor: n.isActive
                            ? Colors.green
                            : Colors.grey,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (n.expiresAt != null)
                        Chip(
                          label: Text(isExpired ? 'EXPIRED' : 'EXPIRES'),
                          backgroundColor: isExpired
                              ? Colors.red
                              : Colors.orange,
                          labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _showCreateDialog(editing: n);
                        } else if (value == 'toggle') {
                          await _noticeService.toggleNoticeStatus(
                            n.id,
                            !n.isActive,
                          );
                          _loadData();
                        } else if (value == 'delete') {
                          final ok = await _confirmDelete();
                          if (ok == true) {
                            await _noticeService.deleteNotice(n.id);
                            _loadData();
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text('Activate/Deactivate'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    )
                  : null,
              onTap: () => _showDetails(n),
            ),
          );
        },
      ),
    );
  }

  void _showDetails(Notice n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(n.title),
        content: SingleChildScrollView(child: Text(n.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog({Notice? editing}) async {
    final titleController = TextEditingController(text: editing?.title ?? '');
    final contentController = TextEditingController(
      text: editing?.content ?? '',
    );
    bool isActive = editing?.isActive ?? true;
    int priority = editing?.priority ?? 0;
    DateTime? expiresAt = editing?.expiresAt;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editing == null ? 'Create Notice' : 'Edit Notice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priority'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: priority,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Normal')),
                        DropdownMenuItem(value: 1, child: Text('High')),
                        DropdownMenuItem(value: 2, child: Text('Urgent')),
                      ],
                      onChanged: (v) => setState(() => priority = v ?? 0),
                    ),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      onChanged: (v) => setState(() => isActive = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Active'),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiry Date (Optional)'),
                  subtitle: Text(
                    expiresAt != null
                        ? expiresAt!.toLocal().toString().split('.')[0]
                        : 'No expiry',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => expiresAt = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: expiresAt ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                expiresAt ?? DateTime.now(),
                              ),
                            );
                            if (time != null) {
                              setState(() {
                                expiresAt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ],
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
            FilledButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty)
                  return;
                try {
                  if (editing == null) {
                    await _noticeService.createNotice(
                      title: titleController.text,
                      content: contentController.text,
                      isActive: isActive,
                      priority: priority,
                      expiresAt: expiresAt,
                    );
                  } else {
                    await _noticeService.updateNotice(
                      id: editing.id,
                      title: titleController.text,
                      content: contentController.text,
                      isActive: isActive,
                      priority: priority,
                      expiresAt: expiresAt,
                    );
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: Text(editing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notice?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
