import 'package:flutter/material.dart';
import 'package:vango_parent_app/screens/Attendance/Attendance.dart';
import 'package:vango_parent_app/screens/finder/finder_screen.dart';
import 'package:vango_parent_app/screens/home/home_screen.dart';
import 'package:vango_parent_app/screens/messages/messages_screen.dart';
import 'package:vango_parent_app/screens/payments/payments_screen.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart'; // Make sure this import exists

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.onSignOut,
    // Note: These parameters below are currently not used in your build logic
    // but kept to avoid breaking your main.dart calls.
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
      const AttendanceScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
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
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Attendance',
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    const Color brandColor = AppColors.accent;

    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: brandColor, size: 35),
                ),
              ),
              accountName: Text(
                'Parent Account',
                style: AppTypography.title.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                'user@vango.com',
                style: AppTypography.body.copyWith(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 10),
            _buildDrawerItem(icon: Icons.home_rounded, label: 'Home', index: 0),
            _buildDrawerItem(
              icon: Icons.search_rounded,
              label: 'Find Driver',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.chat_bubble_rounded,
              label: 'Messages',
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Payments',
              index: 3,
            ),
            _buildDrawerItem(
              icon: Icons.verified_user_rounded,
              label: 'Attendance',
              index: 4,
            ),
            const Spacer(),
            const Divider(indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                tileColor: AppColors.danger.withOpacity(0.1),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                ),
                title: Text(
                  'Sign out',
                  style: AppTypography.title.copyWith(
                    color: AppColors.danger,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSignOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _index == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppColors.accent.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: AppTypography.body.copyWith(
            color: isSelected ? AppColors.accent : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _selectTab(index);
        },
      ),
    );
  }
}
