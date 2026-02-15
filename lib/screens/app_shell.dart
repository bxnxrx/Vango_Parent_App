import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/screens/Attendance/Attendance.dart';
import 'package:vango_parent_app/screens/finder/finder_screen.dart';
import 'package:vango_parent_app/screens/home/home_screen.dart';
import 'package:vango_parent_app/screens/messages/messages_screen.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/screens/payments/payments_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    // Removed onShowOnboarding
    required this.onSignOut,
    required this.payments_screen,
    required this.Messages_screen,
    required this.home_screen,
    required this.onAttendancePressed,
  });

  final VoidCallback onSignOut;
  final VoidCallback payments_screen;
  final VoidCallback Messages_screen;
  final VoidCallback home_screen;
  final VoidCallback onAttendancePressed;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  void _selectTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onOpenMore: () => _scaffoldKey.currentState?.openDrawer()),
      const FinderScreen(),
      const MessagesScreen(),
      const PaymentsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        // Changed AppColors.accent.withOpacity to AppColors.accentLow
        indicatorColor: AppColors.accentLow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search_off),
            label: 'Finder',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Attendance',
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    // We use AppColors.accent because "primary" is not defined in your file
    const Color brandColor = AppColors.accent;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: brandColor),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: brandColor),
              ),
              accountName: const Text(
                'Parent Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('user@vango.com'),
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: const Text('Find driver'),
              onTap: () {
                Navigator.pop(context);
                _selectTab(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _selectTab(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment_outlined),
              title: const Text('Payments'),
              onTap: () {
                Navigator.pop(context);
                _selectTab(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message_outlined),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                _selectTab(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Onboarding'),
              onTap: () {
                Navigator.pop(context);
                _selectTab(4);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Sign out',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onSignOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
