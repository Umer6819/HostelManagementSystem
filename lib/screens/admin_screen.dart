import 'package:flutter/material.dart';
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

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final GlobalKey<State> _userListKey = GlobalKey();

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
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: views[_selectedIndex],
      floatingActionButton: _selectedIndex == 1
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
      bottomNavigationBar: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Reports',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
            BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Fees'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Payments'),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning),
              label: 'Discipline',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
