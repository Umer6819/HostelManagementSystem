import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin/reports_screen.dart';
import 'admin/user_list_view.dart';
import 'admin/user_form_screen.dart';
import 'admin/room_list_screen.dart';
import 'admin/student_management_screen.dart';
import 'admin/fee_management_screen.dart';
import 'admin/payment_history_screen.dart';
import 'admin/complaint_management_screen.dart';
import 'admin/discipline_management_screen.dart';
import 'admin/settings_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<State> _userListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final views = [
      const ReportsScreen(),
      UserListView(key: _userListKey),
      const RoomListScreen(),
      const StudentManagementScreen(),
      const FeeManagementScreen(),
      const PaymentHistoryScreen(),
      const ComplaintManagementScreen(),
      const DisciplineManagementScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Reports', icon: Icon(Icons.dashboard)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Rooms', icon: Icon(Icons.meeting_room)),
            Tab(text: 'Students', icon: Icon(Icons.school)),
            Tab(text: 'Fees', icon: Icon(Icons.payment)),
            Tab(text: 'Payments', icon: Icon(Icons.history)),
            Tab(text: 'Complaints', icon: Icon(Icons.report_problem)),
            Tab(text: 'Discipline', icon: Icon(Icons.warning)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: views),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserFormScreen()),
                );
                // Force rebuild of UserListView
                setState(() {
                  _userListKey.currentState?.setState(() {});
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
