import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/live_trip_location.dart';
import 'package:vango_parent_app/models/notification_item.dart';
import 'package:vango_parent_app/models/ride_status.dart';
import 'package:vango_parent_app/screens/tracking/live_tracking_screen.dart';
import 'package:vango_parent_app/screens/ride_detail/ride_detail_screen.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/services/parent_tracking_repository.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/gradient_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenMore,
    this.onNameLoaded,
  });
  final VoidCallback onOpenMore;
  final ValueChanged<String>? onNameLoaded;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ParentDataService _dataService = ParentDataService.instance;

  List<ChildProfile> _children = <ChildProfile>[];
  List<NotificationItem> _notifications = <NotificationItem>[];
  final RideStatus _rideStatus = const RideStatus.placeholder();
  bool _loading = true;
  String? _error;
  String _parentName = "Parent";

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
      final results = await Future.wait([
        _dataService.fetchChildren(),
        _dataService.fetchNotifications(),
        _dataService.fetchProfile(),
      ]);

      if (!mounted) return;

      final children = results[0] as List<ChildProfile>;
      final notifications = results[1] as List<NotificationItem>;
      final profileData = results[2] as Map<String, dynamic>;

      final name = (profileData['full_name'] as String? ?? '').trim();
      final resolvedName = name.isEmpty ? 'Parent' : name;

      setState(() {
        _children = children;
        _notifications = notifications;
        _parentName = resolvedName;
        _loading = false;
      });

      widget.onNameLoaded?.call(resolvedName);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshDashboard() {
    return _loadDashboard(showSpinner: false);
  }

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

    if (request == null) return;

    try {
      final created = await _dataService.createChild(
        childName: request.name,
        school: request.school,
        pickupLocation: request.pickupLocation,
        pickupTime: request.pickupTime,
        inviteCode: request.inviteCode,
      );

      if (!mounted) return;

      setState(() {
        _children = [..._children, created];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.name} added to your roster')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add child: $error')),
      );
    }
  }

  Future<void> _toggleAttendance(ChildProfile child) async {
    final nextState = child.attendance == AttendanceState.coming
        ? AttendanceState.notComing
        : AttendanceState.coming;

    setState(() {
      _children = _children.map((current) {
        if (current.id != child.id) return current;
        return current.copyWith(attendance: nextState);
      }).toList();
    });

    try {
      await _dataService.updateAttendance(child.id, nextState);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _children = _children.map((current) {
          if (current.id != child.id) return current;
          return current.copyWith(attendance: child.attendance);
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update attendance: $error')),
      );
    }
  }

  void _openRideDetail() {
    final tripId = AppConfig.trackingTripId;
    if (tripId == null || tripId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tracking ID not set.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RideDetailScreen(status: _rideStatus, tripId: tripId),
      ),
    );
  }

  void _openFullscreenMap() {
    final tripId = AppConfig.trackingTripId;
    if (tripId == null || tripId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LiveTrackingScreen(tripId: tripId)),
    );
  }

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
              Text('Update attendance for ${child.name}', style: AppTypography.headline),
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
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
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
                    _LiveMapCard(onExpand: _openFullscreenMap, tripId: AppConfig.trackingTripId),
                    const SizedBox(height: 16),
                    _TodayStatusCard(children: _children, onViewRide: _openRideDetail),
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
                      ..._children.map((child) => _StudentListTile(child: child, onTap: () => _showAttendanceSheet(child))),
                    const SizedBox(height: 24),
                    _buildAlertsHeader(),
                    const SizedBox(height: 12),
                    if (_notifications.isEmpty)
                      const _EmptyStateCard(
                        icon: Icons.notifications_none,
                        title: 'No alerts right now',
                        message: 'We will notify you when a driver updates the ride.',
                      )
                    else
                      ..._notifications.take(2).map((n) => _CompactNotificationCard(notification: n)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            child: Text(
              _parentName.isNotEmpty ? _parentName[0].toUpperCase() : 'P',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $_parentName', style: AppTypography.headline.copyWith(fontSize: 18)),
                Text('Colombo 06', style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: AppColors.accent)),
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
        Text('Recent alerts', style: AppTypography.title.copyWith(fontSize: 20)),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }
}

// --- Map Widgets ---
class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({required this.onExpand, required this.tripId});
  final VoidCallback onExpand;
  final String? tripId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpand,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey[200],
        ),
        child: Stack(
          children: [
            const Center(child: Text("Map Preview")),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Text("Live tracking", style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Status Card ---
class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.children, required this.onViewRide});
  final List<ChildProfile> children;
  final VoidCallback onViewRide;

  @override
  Widget build(BuildContext context) {
    final comingCount = children.where((c) => c.attendance == AttendanceState.coming).length;
    return GestureDetector(
      onTap: onViewRide,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's pickup", style: TextStyle(color: Colors.white.withOpacity(0.8))),
            const Text('6:45 AM', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$comingCount students coming', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _NewChildData {
  const _NewChildData({
    required this.name,
    required this.school,
    required this.pickupLocation,
    required this.pickupTime,
    required this.inviteCode,
  });
  final String name;
  final String school;
  final String pickupLocation;
  final String pickupTime;
  final String inviteCode;
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
  final _inviteCodeController = TextEditingController();

  // Added selection state
  bool _hasDriver = false;

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _pickupLocationController.dispose();
    _pickupTimeController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _NewChildData(
        name: _nameController.text.trim(),
        school: _schoolController.text.trim(),
        pickupLocation: _pickupLocationController.text.trim(),
        pickupTime: _pickupTimeController.text.trim(),
        inviteCode: _hasDriver ? _inviteCodeController.text.trim() : "",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a student', style: AppTypography.headline),
              const SizedBox(height: 4),
              Text('Create a child profile to track attendance and rides.',
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // Student Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Student name', prefixIcon: Icon(Icons.child_care)),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // School
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(labelText: 'School', prefixIcon: Icon(Icons.school_outlined)),
                validator: (v) => v!.isEmpty ? 'School is required' : null,
              ),
              const SizedBox(height: 16),

              // Driver Selection Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text('Do you already have a driver?'),
                  subtitle: Text(_hasDriver ? 'I have an invite code' : 'I need to find a driver'),
                  value: _hasDriver,
                  onChanged: (val) => setState(() => _hasDriver = val),
                  secondary: Icon(_hasDriver ? Icons.local_taxi : Icons.person_search, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 16),

              // Conditional Invite Code Field
              if (_hasDriver) ...[
                TextFormField(
                  controller: _inviteCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Driver invite code',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                    hintText: 'Enter code from your driver',
                  ),
                  validator: (v) => (_hasDriver && v!.isEmpty) ? 'Code is required' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Pickup Details
              TextFormField(
                controller: _pickupLocationController,
                decoration: const InputDecoration(labelText: 'Pickup location', prefixIcon: Icon(Icons.place_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pickupTimeController,
                decoration: const InputDecoration(labelText: 'Pickup time', prefixIcon: Icon(Icons.schedule_outlined)),
              ),

              const SizedBox(height: 24),
              GradientButton(label: 'Add student', onPressed: _submit, expanded: true),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper Components (Simplified for space) ---
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  final IconData icon; final String title; final String message; final String? actionLabel; final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(child: Column(children: [Icon(icon), Text(title), Text(message), if (onAction != null) ElevatedButton(onPressed: onAction, child: Text(actionLabel!))]));
}

class _StudentListTile extends StatelessWidget {
  const _StudentListTile({required this.child, required this.onTap});
  final ChildProfile child; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, leading: CircleAvatar(child: Text(child.name[0])), title: Text(child.name), subtitle: Text(child.school));
}

class _CompactNotificationCard extends StatelessWidget {
  const _CompactNotificationCard({required this.notification});
  final NotificationItem notification;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(title: Text(notification.title), subtitle: Text(notification.body)));
}

class _AttendanceOption extends StatelessWidget {
  const _AttendanceOption({required this.label, this.helper, required this.value, required this.groupValue, required this.onChanged});
  final String label; final String? helper; final AttendanceState value; final AttendanceState groupValue; final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => ListTile(title: Text(label), subtitle: helper != null ? Text(helper!) : null, trailing: Radio(value: value, groupValue: groupValue, onChanged: (_) => onChanged()));
}