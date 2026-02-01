import 'package:flutter/material.dart';

import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/notification_item.dart';
import 'package:vango_parent_app/models/ride_status.dart';
import 'package:vango_parent_app/screens/ride_detail/ride_detail_screen.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenMore});

  final VoidCallback onOpenMore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ParentDataService _dataService = ParentDataService.instance;

  List<ChildProfile> _children = <ChildProfile>[];
  List<NotificationItem> _notifications = <NotificationItem>[];
  RideStatus _rideStatus = const RideStatus.placeholder();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final childrenFuture = _dataService.fetchChildren();
      final notificationsFuture = _dataService.fetchNotifications();
      final children = await childrenFuture;
      final notifications = await notificationsFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _children = children;
        _notifications = notifications;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshDashboard() {
    return _loadDashboard(showSpinner: false);
  }

  // Let parents create a quick profile for another child.
  Future<void> _openAddChildSheet() async {
    final request = await showModalBottomSheet<_NewChildData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: const _AddChildSheet(),
        );
      },
    );

    if (request == null) {
      return;
    }

    try {
      final created = await _dataService.createChild(
        childName: request.name,
        school: request.school,
        pickupLocation: request.pickupLocation,
        pickupTime: request.pickupTime,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _children = [..._children, created];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.name} added to your roster')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add child: $error')));
    }
  }

  // Flip the attendance for a single child in the list.
  Future<void> _toggleAttendance(ChildProfile child) async {
    final nextState = child.attendance == AttendanceState.coming
        ? AttendanceState.notComing
        : AttendanceState.coming;

    setState(() {
      _children = _children.map((current) {
        if (current.id != child.id) {
          return current;
        }
        return current.copyWith(attendance: nextState);
      }).toList();
    });

    try {
      await _dataService.updateAttendance(child.id, nextState);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _children = _children.map((current) {
          if (current.id != child.id) {
            return current;
          }
          return current.copyWith(attendance: child.attendance);
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update attendance: $error')),
      );
    }
  }

  // Jump into the ride detail screen.
  void _openRideDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RideDetailScreen(status: _rideStatus)),
    );
  }

  // Present the full map preview in a dialog-like screen.
  void _openFullscreenMap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _FullscreenMapView()));
  }

  // Open the action sheet so a parent can mark attendance.
  void _showAttendanceSheet(ChildProfile child) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update attendance for ${child.name}',
                style: AppTypography.headline,
              ),
              const SizedBox(height: 16),
              _AttendanceOption(
                label: 'Coming today',
                value: AttendanceState.coming,
                groupValue: child.attendance,
                onChanged: () {
                  Navigator.pop(context);
                  _toggleAttendance(child);
                },
              ),
              _AttendanceOption(
                label: 'Not coming today',
                helper: 'Driver will be notified.',
                value: AttendanceState.notComing,
                groupValue: child.attendance,
                onChanged: () {
                  Navigator.pop(context);
                  _toggleAttendance(child);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Could not load dashboard',
              style: AppTypography.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Try again',
              onPressed: () {
                _loadDashboard();
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _LiveMapCard(onExpand: _openFullscreenMap),
                  const SizedBox(height: 16),
                  _TodayStatusCard(
                    children: _children,
                    onViewRide: _openRideDetail,
                  ),
                  const SizedBox(height: 24),
                  _buildStudentsHeader(),
                  const SizedBox(height: 12),
                  if (_children.isEmpty)
                    _EmptyStateCard(
                      icon: Icons.person_add_alt,
                      title: 'No children yet',
                      message: 'Add your first child to start tracking rides.',
                      actionLabel: 'Add child',
                      onAction: _openAddChildSheet,
                    )
                  else
                    ..._children.map(
                      (child) => _StudentListTile(
                        child: child,
                        onTap: () => _showAttendanceSheet(child),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildAlertsHeader(),
                  const SizedBox(height: 12),
                  if (_notifications.isEmpty)
                    const _EmptyStateCard(
                      icon: Icons.notifications_none,
                      title: 'No alerts right now',
                      message:
                          'We will notify you when a driver updates the ride.',
                    )
                  else
                    ..._notifications
                        .take(2)
                        .map(
                          (notification) => _CompactNotificationCard(
                            notification: notification,
                          ),
                        ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable app bar with the parent avatar and notifications.
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      leading: IconButton(
        onPressed: widget.onOpenMore,
        icon: const Icon(Icons.menu, color: AppColors.accent),
      ),
      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            child: Text(
              'L',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, Lakshmi',
                  style: AppTypography.headline.copyWith(fontSize: 18),
                ),
                Text(
                  'Colombo 06',
                  style: AppTypography.body.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none,
                color: AppColors.accent,
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStudentsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Students', style: AppTypography.title.copyWith(fontSize: 20)),
        TextButton.icon(
          onPressed: _openAddChildSheet,
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildAlertsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent alerts',
          style: AppTypography.title.copyWith(fontSize: 20),
        ),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }
}

// Preview tile for the in-progress ride map.
class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpand,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.1),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.map,
                    size: 64,
                    color: AppColors.accent.withOpacity(0.3),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live tracking',
                        style: AppTypography.label.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
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

// Lightweight full screen placeholder for the map integration.
class _FullscreenMapView extends StatelessWidget {
  const _FullscreenMapView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: AppColors.accent),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withOpacity(0.1), AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 120,
                    color: AppColors.accent.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Google Maps integration',
                    style: AppTypography.title.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Bus arriving in 8 mins',
                        style: AppTypography.title.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '2.3 km away - Moving at 35 km/h',
                        style: AppTypography.body.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Summarises the next pickup in a tappable card.
class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.children, required this.onViewRide});

  final List<ChildProfile> children;
  final VoidCallback onViewRide;

  @override
  Widget build(BuildContext context) {
    final comingCount = children
        .where((c) => c.attendance == AttendanceState.coming)
        .length;
    return GestureDetector(
      onTap: onViewRide,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bus_alert,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'En route',
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Today's pickup",
              style: AppTypography.body.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '6:45 AM',
              style: AppTypography.display.copyWith(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$comingCount of ${children.length} student${children.length > 1 ? 's' : ''} coming',
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            GradientButton(
              label: actionLabel!,
              onPressed: onAction!,
              expanded: true,
            ),
          ],
        ],
      ),
    );
  }
}

// One row inside the students list with attendance status.
class _StudentListTile extends StatelessWidget {
  const _StudentListTile({required this.child, required this.onTap});

  final ChildProfile child;
  final VoidCallback onTap;

  Color _statusColor() {
    if (child.attendance == AttendanceState.coming) {
      return AppColors.success;
    }

    if (child.attendance == AttendanceState.notComing) {
      return AppColors.textSecondary;
    }

    return AppColors.warning;
  }

  String _statusLabel() {
    if (child.attendance == AttendanceState.coming) {
      return 'Coming';
    }

    if (child.attendance == AttendanceState.notComing) {
      return 'Not coming';
    }

    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final label = _statusLabel();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: child.avatarColor.withOpacity(0.15),
          child: Text(
            child.name[0].toUpperCase(),
            style: TextStyle(
              color: child.avatarColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          child.name,
          style: AppTypography.title.copyWith(fontSize: 16),
        ),
        subtitle: Row(
          children: [
            const Icon(
              Icons.school_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                child.school,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(color: color, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// Condensed card for recent ride or payment notifications.
class _CompactNotificationCard extends StatelessWidget {
  const _CompactNotificationCard({required this.notification});

  final NotificationItem notification;

  IconData _iconForCategory() {
    if (notification.category == NotificationCategory.ride) {
      return Icons.directions_bus;
    }

    if (notification.category == NotificationCategory.payment) {
      return Icons.payments;
    }

    return Icons.shield;
  }

  Color _colorForCategory() {
    if (notification.category == NotificationCategory.ride) {
      return AppColors.accent;
    }

    if (notification.category == NotificationCategory.payment) {
      return AppColors.success;
    }

    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForCategory(), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTypography.title.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: AppTypography.body.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            notification.relativeTime,
            style: AppTypography.label.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet used to capture a new child profile.
class _NewChildData {
  const _NewChildData({
    required this.name,
    required this.school,
    required this.pickupLocation,
    required this.pickupTime,
  });

  final String name;
  final String school;
  final String pickupLocation;
  final String pickupTime;
}

class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet();

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _pickupLocationController = TextEditingController(text: 'Front gate');
  final _pickupTimeController = TextEditingController(text: '6:45 AM');

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _pickupLocationController.dispose();
    _pickupTimeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _NewChildData(
        name: _nameController.text.trim(),
        school: _schoolController.text.trim(),
        pickupLocation: _pickupLocationController.text.trim().isEmpty
            ? 'Front gate'
            : _pickupLocationController.text.trim(),
        pickupTime: _pickupTimeController.text.trim().isEmpty
            ? '6:45 AM'
            : _pickupTimeController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a student', style: AppTypography.headline),
            const SizedBox(height: 4),
            Text(
              'Create a child profile to track attendance and rides.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Student name',
                prefixIcon: Icon(Icons.child_care),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolController,
              decoration: const InputDecoration(
                labelText: 'School',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'School is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pickupLocationController,
              decoration: const InputDecoration(
                labelText: 'Pickup location',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Pickup location is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pickupTimeController,
              decoration: const InputDecoration(
                labelText: 'Pickup time',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Add student',
              onPressed: _submit,
              expanded: true,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// Radio list item for the attendance bottom sheet.
class _AttendanceOption extends StatelessWidget {
  const _AttendanceOption({
    required this.label,
    this.helper,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String? helper;
  final AttendanceState value;
  final AttendanceState groupValue;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: helper == null ? null : Text(helper!),
      trailing: Radio<AttendanceState>(
        value: value,
        groupValue: groupValue,
        onChanged: (_) => onChanged(),
      ),
      onTap: onChanged,
    );
  }
}
