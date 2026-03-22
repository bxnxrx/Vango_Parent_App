import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vango_parent_app/screens/Attendance/attendance_screen.dart';
import 'package:vango_parent_app/screens/finder/finder_screen.dart';
import 'package:vango_parent_app/screens/home/home_screen.dart';
import 'package:vango_parent_app/screens/messages/messages_screen.dart';
import 'package:vango_parent_app/screens/payments/payments_screen.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
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
  String _parentName = 'Parent';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    final authEmail =
        user?.email ?? user?.userMetadata?['email'] as String? ?? '';
    final authPhone = user?.phone ?? '';

    if (authEmail.isNotEmpty) {
      setState(() => _userEmail = authEmail);
      return;
    }

    if (authPhone.isNotEmpty) {
      setState(() => _userEmail = authPhone);
      return;
    }

    try {
      final profileData = await Supabase.instance.client
          .from('parents')
          .select('email, phone')
          .eq('supabase_user_id', user?.id ?? '')
          .single();

      final dbEmail = profileData['email'] as String? ?? '';
      final dbPhone = profileData['phone'] as String? ?? '';

      setState(() {
        _userEmail = dbEmail.isNotEmpty ? dbEmail : dbPhone;
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch profile email: $e');
      setState(() => _userEmail = '');
    }
  }

  void _selectTab(int index) {
    setState(() => _index = index);
  }

  void _showProfilePhoto(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: textColor,
                    size: 30,
                  ), // 👇 Dynamic Close Icon
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface, // 👇 Dynamic Surface
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _parentName.isNotEmpty ? _parentName[0].toUpperCase() : 'P',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkAccent
                          : AppColors.accent, // 👇 Dynamic Accent
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _parentName,
                style: AppTypography.title.copyWith(
                  color: textColor,
                  fontSize: 24,
                ), // 👇 Dynamic Text
              ),
              Text(
                _userEmail,
                style: AppTypography.body.copyWith(
                  color: secondaryTextColor,
                ), // 👇 Dynamic Secondary Text
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface, // 👇 Dynamic Dialog Background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).dividerColor,
          ), // 👇 Dynamic Border
        ),
        title: Text(
          'Sign Out',
          style: AppTypography.title.copyWith(color: textColor),
        ), // 👇 Dynamic Text
        content: Text(
          'Are you sure you want to log out of your account?',
          style: AppTypography.body.copyWith(color: textColor),
        ), // 👇 Dynamic Text
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ), // 👇 Dynamic Cancel Button
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onSignOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = <Widget>[
      HomeScreen(
        onOpenMore: () => _scaffoldKey.currentState?.openDrawer(),
        onNameLoaded: (name) {
          setState(() => _parentName = name);
        },
      ),
      const FinderScreen(),
      MessagesScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      const PaymentsScreen(),
      const AttendanceScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context), // Pass context to pull theme
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface, // 👇 Dynamic Nav Bar Background
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        indicatorColor: isDark
            ? AppColors.darkAccent.withOpacity(0.2)
            : AppColors.accentLow, // 👇 Dynamic Indicator
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

  Drawer _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = isDark
        ? AppColors.darkAccent
        : AppColors.accent; // 👇 Dynamic Brand Color

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(
                    0.85,
                  ), // 👇 Dynamic Blurred Overlay
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ), // 👇 Dynamic Border
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- COMPACT PROFILE BOX ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: GestureDetector(
                    onTap: () => _showProfilePhoto(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            AppColors.buttonGradient, // Keep brand gradient
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Text(
                                _parentName.isNotEmpty
                                    ? _parentName[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  color: AppColors
                                      .accent, // Kept light accent since circle is always white
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _parentName,
                            textAlign: TextAlign.center,
                            style: AppTypography.title.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userEmail.isNotEmpty ? _userEmail : 'Vango Parent',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // -----------------------------
                const SizedBox(height: 12),
                _buildDrawerItem(
                  context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.search_rounded,
                  label: 'Find Driver',
                  index: 1,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Messages',
                  index: 2,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Payments',
                  index: 3,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.verified_user_rounded,
                  label: 'Attendance',
                  index: 4,
                ),
                const Spacer(),
                Divider(
                  indent: 20,
                  endIndent: 20,
                  color: Theme.of(context).dividerColor,
                ), // 👇 Dynamic Divider

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: InkWell(
                    onTap: () => _confirmSignOut(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(
                          0.1,
                        ), // Danger keeps its semantic meaning
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: AppColors.danger),
                          const SizedBox(width: 12),
                          Text(
                            'Sign out',
                            style: AppTypography.title.copyWith(
                              color: AppColors.danger,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.danger.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _index == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 👇 Dynamic text and icon colors based on theme and selection state
    final defaultTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final defaultIconColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final activeColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1,
          ),
          color: isSelected
              ? activeColor.withOpacity(0.08)
              : Colors.transparent,
        ),
        child: ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            icon,
            color: isSelected ? activeColor : defaultIconColor,
            size: 22,
          ),
          title: Text(
            label,
            style: AppTypography.body.copyWith(
              color: isSelected ? activeColor : defaultTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            _selectTab(index);
          },
        ),
      ),
    );
  }
}
