import 'package:flutter/material.dart';
import 'admin/user_list_view.dart';
import 'admin/user_form_screen.dart';
import 'admin/room_list_screen.dart';

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
      UserListView(key: _userListKey),
      const RoomListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: views[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Rooms'),
        ],
      ),
    );
  }
}
