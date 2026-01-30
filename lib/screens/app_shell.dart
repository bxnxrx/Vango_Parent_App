import 'package:flutter/material.dart';

import 'package:vango_parent_app/screens/finder/finder_screen.dart';
import 'package:vango_parent_app/screens/home/home_screen.dart';
import 'package:vango_parent_app/screens/messages/messages_screen.dart';
import 'package:vango_parent_app/screens/payments/payments_screen.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/emergency_button.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onShowOnboarding, required this.onSignOut});

  final VoidCallback onShowOnboarding;
  final VoidCallback onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onOpenMore: _openMorePanel),
      const FinderScreen(),
      const PaymentsScreen(),
      const MessagesScreen(),
    ];

    return Scaffold(
      floatingActionButton: EmergencyButton(onTap: () => _openEmergency(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Finder'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Payments'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
        ],
      ),
      body: SafeArea(child: screens[_index]),
    );
  }

  void _openEmergency(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emergency center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const _EmergencyTile(icon: Icons.call, label: 'Call driver', color: AppColors.accent),
              const _EmergencyTile(icon: Icons.emergency, label: 'Call 119', color: AppColors.danger),
              const _EmergencyTile(icon: Icons.send_time_extension, label: 'Notify SOS contacts', color: AppColors.warning),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Share live location'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMorePanel() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sidebar menu',
      barrierColor: AppColors.overlay,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: _FullScreenSidebar(
            currentIndex: _index,
            onNavigate: (value) {
              setState(() => _index = value);
              Navigator.of(context).pop();
            },
            onClose: () => Navigator.of(context).pop(),
            onShowOnboarding: () {
              Navigator.of(context).pop();
              widget.onShowOnboarding();
            },
            onSignOut: () {
              Navigator.of(context).pop();
              widget.onSignOut();
            },
          ),
        );
      },
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  const _EmergencyTile({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
      title: Text(label),
      onTap: () => Navigator.pop(context),
    );
  }
}

class _FullScreenSidebar extends StatelessWidget {
  const _FullScreenSidebar({
    required this.currentIndex,
    required this.onNavigate,
    required this.onClose,
    required this.onShowOnboarding,
    required this.onSignOut,
  });

  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback onClose;
  final VoidCallback onShowOnboarding;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _SidebarEntry(icon: Icons.home_outlined, label: 'Home', index: 0),
      const _SidebarEntry(icon: Icons.search, label: 'Find Drivers', index: 1),
      const _SidebarEntry(icon: Icons.payments_outlined, label: 'Payments', index: 2),
      const _SidebarEntry(icon: Icons.chat_bubble_outline, label: 'Messages', index: 3),
      const _SidebarEntry(icon: Icons.notifications_outlined, label: 'Notifications'),
      const _SidebarEntry(icon: Icons.person_outline, label: 'My Children'),
      const _SidebarEntry(icon: Icons.settings_outlined, label: 'Settings'),
      const _SidebarEntry(icon: Icons.help_outline, label: 'Help & Support'),
    ];

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(right: 60),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 12, 12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=200&q=60'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lakshmi', style: AppTypography.headline.copyWith(fontSize: 20)),
                          Text('Colombo 06', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 24, endIndent: 24),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  itemBuilder: (context, index) {
                    final entry = items[index];
                    final isActive = entry.index != null && currentIndex == entry.index;
                    return _SidebarNavButton(
                      icon: entry.icon,
                      label: entry.label,
                      isActive: isActive,
                      onTap: () {
                        if (entry.index != null) {
                          onNavigate(entry.index!);
                        } else {
                          onClose();
                        }
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: TextButton(
                  onPressed: onSignOut,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    'Sign out',
                    style: AppTypography.title.copyWith(
                      fontSize: 16,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _SidebarEntry {
  const _SidebarEntry({required this.icon, required this.label, this.index});

  final IconData icon;
  final String label;
  final int? index;
}

class _SidebarNavButton extends StatelessWidget {
  const _SidebarNavButton({required this.icon, required this.label, required this.isActive, required this.onTap});

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surfaceStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.title.copyWith(
                    fontSize: 15,
                    color: isActive ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
