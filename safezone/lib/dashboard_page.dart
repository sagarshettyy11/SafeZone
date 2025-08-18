import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your actual pages
import 'features/home_page.dart';
import 'features/map_page.dart';
import 'features/emergency_page.dart';
import 'features/complaint_page.dart';
import 'features/user_profile.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Replace placeholders with actual pages
  final List<Widget> _pages = const [
    HomePage(),
    MapPage(),
    EmergencyPage(),
    ComplaintPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // Redirect if user is not logged in
  void _checkAuth() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      });
    }
  }

  // Handle bottom nav taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.exclamationmark_triangle_fill),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.flag),
            label: 'Complaint',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
