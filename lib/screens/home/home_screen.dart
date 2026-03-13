import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/ride_status.dart';
import 'package:vango_parent_app/screens/tracking/live_tracking_screen.dart';
import 'package:vango_parent_app/screens/ride_detail/ride_detail_screen.dart';
import 'package:vango_parent_app/screens/children/manage_children_screen.dart';
import 'package:vango_parent_app/services/app_config.dart';
import 'package:vango_parent_app/services/parent_data_service.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/child_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vango_parent_app/screens/notifications/notification_panel_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badges/badges.dart' as badges;
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenMore, this.onNameLoaded});
  final VoidCallback onOpenMore;
  final ValueChanged<String>? onNameLoaded;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ParentDataService _dataService = ParentDataService.instance;
  static const platform = MethodChannel('com.vango.app/apikey');
  final _supabase = Supabase.instance.client;

  List<ChildProfile> _children = <ChildProfile>[];
  final RideStatus _rideStatus = const RideStatus.placeholder();
  bool _loading = true;
  String _parentName = "Parent";
  String? _mapsApiKey; 

  // 👇 NEW: Filter state for the notifications
  String _selectedFilter = 'All'; 

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _fetchApiKey(); 
  }

  Future<void> _fetchApiKey() async {
    try {
      final String apiKey = await platform.invokeMethod('getApiKey');
      if (mounted) {
        setState(() {
          _mapsApiKey = apiKey;
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get API key from Native channel: '${e.message}'.");
    }
  }

  Future<void> _loadDashboard({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _dataService.fetchChildren(),
        _dataService.fetchProfile(),
      ]);

      if (!mounted) return;

      final profileData = results[1] as Map<String, dynamic>;
      final name = (profileData['full_name'] as String? ?? '').trim();
      final resolvedName = name.isEmpty ? 'Parent' : name;

      setState(() {
        _children = results[0] as List<ChildProfile>;
        _parentName = resolvedName;
        _loading = false;
      });

      widget.onNameLoaded?.call(resolvedName);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openRideDetail() {
    final tripId = AppConfig.trackingTripId;
    if (tripId == null || tripId.isEmpty) return;
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

  void _navigateToManageChildren() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageChildrenScreen()));
    _loadDashboard(showSpinner: false); 
  }

  // 👇 NEW: Helper function to determine if an alert is "Important" (Critical)
  bool _isImportantAlert(Map<String, dynamic> alert) {
    final title = (alert['title'] ?? '').toString().toLowerCase();
    // These match your critical emergency types from the driver app
    return title.contains('breakdown') || 
           title.contains('accident') || 
           title.contains('medical') || 
           title.contains('security');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final String userId = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('notification_logs')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          
          final liveNotifications = snapshot.data ?? [];
          final unreadCount = liveNotifications.where((n) => n['is_read'] != true).length;

          // 👇 NEW: Apply the selected filter
          final filteredNotifications = liveNotifications.where((alert) {
            if (_selectedFilter == 'All') return true;
            final isImportant = _isImportantAlert(alert);
            if (_selectedFilter == 'Important') return isImportant;
            if (_selectedFilter == 'Situational') return !isImportant;
            return true;
          }).toList();

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => _loadDashboard(showSpinner: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildModernAppBar(unreadCount),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildQuickStatusCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Live Tracking', 'Expand Map', _openFullscreenMap),
                        const SizedBox(height: 12),
                        _LiveMapCard(
                          onExpand: _openFullscreenMap,
                          tripId: AppConfig.trackingTripId,
                          apiKey: _mapsApiKey,
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('My Students', 'Manage', _navigateToManageChildren),
                        const SizedBox(height: 12),
                        if (_children.isEmpty)
                          _buildEmptyState()
                        else
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: _children.length,
                              itemBuilder: (context, index) {
                                return ChildCard(
                                  child: _children[index],
                                  onToggle: () {},
                                  onTap: _navigateToManageChildren,
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 32),
                        
                        // 👇 NEW: Filter UI next to Recent Alerts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Alerts', style: AppTypography.title.copyWith(fontSize: 20)),
                            DropdownButton<String>(
                              value: _selectedFilter,
                              icon: const Icon(Icons.filter_list, size: 18),
                              underline: const SizedBox(), // Removes the default line
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
                              items: ['All', 'Important', 'Situational'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedFilter = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (filteredNotifications.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No alerts matching this filter."),
                          )
                        else
                          // 👇 Changed to take(5)
                          ...filteredNotifications
                              .take(5) 
                              .map((alert) => _LiveNotificationCard(alertData: alert)),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  SliverAppBar _buildModernAppBar(int unreadCount) {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: widget.onOpenMore,
        icon: const Icon(Icons.grid_view_rounded, color: AppColors.textPrimary),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentLow,
              child: Text(
                _parentName.isNotEmpty ? _parentName[0].toUpperCase() : 'P',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Morning,', style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.textSecondary)),
              Text(_parentName, style: AppTypography.headline.copyWith(fontSize: 18)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationPanelScreen(),
              ),
            );
          },
          icon: badges.Badge(
            showBadge: unreadCount > 0,
            badgeStyle: const badges.BadgeStyle(badgeColor: Colors.redAccent),
            badgeContent: Text(
              unreadCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionLabel, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.title.copyWith(fontSize: 20)),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildQuickStatusCard() {
    final comingCount = _children.where((c) => c.attendance == AttendanceState.coming).length;
    return GestureDetector(
      onTap: _openRideDetail,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Next Pickup", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                const SizedBox(height: 4),
                const Text('06:45 AM', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('$comingCount students scheduled', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.directions_bus_rounded, color: AppColors.accent, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.group_add_outlined, size: 48, color: AppColors.accent),
          const SizedBox(height: 16),
          Text('No students added yet', style: AppTypography.title),
          const SizedBox(height: 8),
          Text('Add a student to manage their rides', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _navigateToManageChildren,
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }
}

class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({required this.onExpand, required this.tripId, this.apiKey});
  final VoidCallback onExpand;
  final String? tripId;
  final String? apiKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpand,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: AppColors.surfaceStrong,
          border: Border.all(color: AppColors.stroke),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              if (apiKey != null && apiKey!.isNotEmpty)
                IgnorePointer(
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(target: LatLng(6.9271, 79.8612), zoom: 13),
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    liteModeEnabled: true, 
                  ),
                )
              else
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text("Loading Map...", style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              if (tripId == null && apiKey != null && apiKey!.isNotEmpty)
                const Center(
                  child: Text("Map Preview", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, backgroundColor: Colors.white70)),
                ),
              Positioned(
                top: 16, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.subtle),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text("Live Tracking", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppShadows.subtle),
                  child: const Icon(Icons.fullscreen, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 👇 UPDATED: Pop-up perfectly matches the widget design!
// 👇 UPDATED: Added Time formatting and display!
class _LiveNotificationCard extends StatefulWidget {
  const _LiveNotificationCard({required this.alertData});
  final Map<String, dynamic> alertData;

  @override
  State<_LiveNotificationCard> createState() => _LiveNotificationCardState();
}

class _LiveNotificationCardState extends State<_LiveNotificationCard> {
  late bool _localIsRead;

  @override
  void initState() {
    super.initState();
    _localIsRead = widget.alertData['is_read'] == true;
  }

  @override
  void didUpdateWidget(covariant _LiveNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alertData['is_read'] == true) {
      _localIsRead = true;
    }
  }

  Future<void> _markAsReadBackend() async {
    try {
      await Supabase.instance.client
          .from('notification_logs')
          .update({'is_read': true})
          .eq('id', widget.alertData['id']);
    } catch (e) {
      debugPrint("Failed to mark notification as read: $e");
    }
  }

  void _handleTap(IconData iconData, Color iconColor, Color iconBgColor, String timeString) {
    if (!_localIsRead) {
      setState(() => _localIsRead = true);
      _markAsReadBackend();
    }

    final String title = widget.alertData['title'] ?? 'Notification';
    final String body = widget.alertData['message'] ?? '';
    final String type = widget.alertData['notification_type'] ?? '';
    final String? referenceId = widget.alertData['reference_id'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                      child: Icon(iconData, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Added time to the pop-up as well!
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(title, style: AppTypography.title.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              Text(timeString, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(body, style: AppTypography.body.copyWith(fontSize: 15, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (type == 'EMERGENCY_ALERT' && referenceId != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.of(context).pushNamed('/emergency_status', arguments: {'emergencyId': referenceId});
                      },
                      child: const Text('View Live Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.grey.shade100,
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close', style: TextStyle(color: Colors.blueGrey, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 👇 HELPER FUNCTION TO FORMAT THE TIME BEAUTIFULLY 👇
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(timestamp).toLocal();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24 && now.day == date.day) {
        return DateFormat('h:mm a').format(date); // e.g., "3:45 PM"
      } else if (difference.inDays < 2) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM d').format(date); // e.g., "Oct 12"
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !_localIsRead; 
    final String title = widget.alertData['title'] ?? 'Notification';
    final String body = widget.alertData['message'] ?? '';
    
    // 👇 Get the formatted time string
    final String timeString = _formatTimestamp(widget.alertData['created_at']);
    
    IconData iconData = Icons.notifications;
    Color iconColor = Colors.blueGrey;
    Color iconBgColor = Colors.blueGrey.withOpacity(0.1);
    
    if (title.toLowerCase().contains('resolved') || widget.alertData['notification_type'] == 'EMERGENCY_RESOLVED') {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
      iconBgColor = Colors.green.withOpacity(0.15);
    } else if (title.toLowerCase().contains('breakdown') || title.toLowerCase().contains('accident') || title.toLowerCase().contains('medical') || widget.alertData['notification_type'] == 'EMERGENCY_ALERT') {
      iconData = Icons.warning_rounded;
      iconColor = Colors.redAccent;
      iconBgColor = Colors.redAccent.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: () => _handleTap(iconData, iconColor, iconBgColor, timeString),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👇 Title row now includes the time string pushed to the right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.title.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeString,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTypography.body.copyWith(fontSize: 14, color: Colors.grey.shade700),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}