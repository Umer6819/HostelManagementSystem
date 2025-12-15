import 'package:flutter/material.dart';
import '../../models/hostel_rule_model.dart';
import '../../models/notice_model.dart';
import '../../services/hostel_rule_service.dart';
import '../../services/notice_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HostelRuleService _ruleService = HostelRuleService();
  final NoticeService _noticeService = NoticeService();

  List<HostelRule> _rules = [];
  List<Notice> _notices = [];
  bool _isLoading = true;

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
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _ruleService.fetchAllRules(),
        _noticeService.fetchAllNotices(),
      ]);
      setState(() {
        _rules = results[0] as List<HostelRule>;
        _notices = results[1] as List<Notice>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hostel Rules'),
            Tab(text: 'Notice Board'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildRulesTab(), _buildNoticesTab()],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showRuleDialog();
          } else {
            _showNoticeDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRulesTab() {
    if (_rules.isEmpty) {
      return const Center(child: Text('No hostel rules yet'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _rules.length,
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex--;
          final rule = _rules.removeAt(oldIndex);
          _rules.insert(newIndex, rule);

          // Update priorities
          for (int i = 0; i < _rules.length; i++) {
            await _ruleService.updateRule(
              id: _rules[i].id,
              priority: _rules.length - i,
            );
          }
          await _loadData();
        },
        itemBuilder: (context, index) {
          final rule = _rules[index];
          return Card(
            key: ValueKey(rule.id),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
              title: Text(
                rule.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: rule.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(
                rule.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: rule.isActive,
                    onChanged: (value) async {
                      await _ruleService.toggleRuleStatus(rule.id, value);
                      await _loadData();
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showRuleDialog(rule: rule);
                      } else if (value == 'delete') {
                        final confirm = await _showDeleteConfirm();
                        if (confirm == true) {
                          await _ruleService.deleteRule(rule.id);
                          await _loadData();
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              onTap: () => _showRuleDetailsDialog(rule),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticesTab() {
    if (_notices.isEmpty) {
      return const Center(child: Text('No notices yet'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notices.length,
        itemBuilder: (context, index) {
          final notice = _notices[index];
          final isExpired =
              notice.expiresAt != null &&
              notice.expiresAt!.isBefore(DateTime.now());

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                isExpired ? Icons.warning : Icons.campaign,
                color: isExpired
                    ? Colors.grey
                    : notice.isActive
                    ? Colors.blue
                    : Colors.grey,
              ),
              title: Text(
                notice.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: notice.isActive && !isExpired
                      ? null
                      : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notice.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notice.expiresAt != null)
                    Text(
                      'Expires: ${notice.expiresAt!.toLocal().toString().split('.')[0]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? Colors.red : Colors.orange,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: notice.isActive,
                    onChanged: (value) async {
                      await _noticeService.toggleNoticeStatus(notice.id, value);
                      await _loadData();
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showNoticeDialog(notice: notice);
                      } else if (value == 'delete') {
                        final confirm = await _showDeleteConfirm();
                        if (confirm == true) {
                          await _noticeService.deleteNotice(notice.id);
                          await _loadData();
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              onTap: () => _showNoticeDetailsDialog(notice),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRuleDialog({HostelRule? rule}) async {
    final titleController = TextEditingController(text: rule?.title ?? '');
    final descController = TextEditingController(text: rule?.description ?? '');
    bool isActive = rule?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(rule == null ? 'Add Rule' : 'Edit Rule'),
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
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
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
                    descController.text.isEmpty) {
                  return;
                }

                try {
                  if (rule == null) {
                    await _ruleService.createRule(
                      title: titleController.text,
                      description: descController.text,
                      isActive: isActive,
                    );
                  } else {
                    await _ruleService.updateRule(
                      id: rule.id,
                      title: titleController.text,
                      description: descController.text,
                      isActive: isActive,
                    );
                  }
                  await _loadData();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(rule == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoticeDialog({Notice? notice}) async {
    final titleController = TextEditingController(text: notice?.title ?? '');
    final contentController = TextEditingController(
      text: notice?.content ?? '',
    );
    bool isActive = notice?.isActive ?? true;
    DateTime? expiresAt = notice?.expiresAt;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(notice == null ? 'Add Notice' : 'Edit Notice'),
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
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
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
                          onPressed: () {
                            setDialogState(() => expiresAt = null);
                          },
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
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                expiresAt ?? DateTime.now(),
                              ),
                            );
                            if (time != null) {
                              setDialogState(() {
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
                    contentController.text.isEmpty) {
                  return;
                }

                try {
                  if (notice == null) {
                    await _noticeService.createNotice(
                      title: titleController.text,
                      content: contentController.text,
                      isActive: isActive,
                      expiresAt: expiresAt,
                    );
                  } else {
                    await _noticeService.updateNotice(
                      id: notice.id,
                      title: titleController.text,
                      content: contentController.text,
                      isActive: isActive,
                      expiresAt: expiresAt,
                    );
                  }
                  await _loadData();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(notice == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRuleDetailsDialog(HostelRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rule.title),
        content: SingleChildScrollView(child: Text(rule.description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNoticeDetailsDialog(Notice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notice.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notice.content),
              const SizedBox(height: 16),
              if (notice.expiresAt != null)
                Text(
                  'Expires: ${notice.expiresAt!.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              Text(
                'Created: ${notice.createdAt.toLocal().toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirm() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
