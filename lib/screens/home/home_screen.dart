import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED FOR METHODCHANNEL
import 'package:vango_parent_app/models/child_profile.dart';
import 'package:vango_parent_app/models/notification_item.dart';
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

  List<ChildProfile> _children = <ChildProfile>[];
  List<NotificationItem> _notifications = <NotificationItem>[];
  final RideStatus _rideStatus = const RideStatus.placeholder();
  bool _loading = true;
  String _parentName = "Parent";
  String? _mapsApiKey; // NEW: Store the fetched API key

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _fetchApiKey(); // NEW: Fetch API key on startup
  }

  // --- NATIVE API KEY FETCHER ---
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
        _dataService.fetchNotifications(),
        _dataService.fetchProfile(),
      ]);

      if (!mounted) return;

      final profileData = results[2] as Map<String, dynamic>;
      final name = (profileData['full_name'] as String? ?? '').trim();
      final resolvedName = name.isEmpty ? 'Parent' : name;

      setState(() {
        _children = results[0] as List<ChildProfile>;
        _notifications = results[1] as List<NotificationItem>;
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ManageChildrenScreen()));
    _loadDashboard(showSpinner: false); // Refresh dashboard when returning
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => _loadDashboard(showSpinner: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildModernAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildQuickStatusCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Live Tracking',
                      'Expand Map',
                      _openFullscreenMap,
                    ),
                    const SizedBox(height: 12),

                    // The Map Card now receives the dynamic API Key
                    _LiveMapCard(
                      onExpand: _openFullscreenMap,
                      tripId: AppConfig.trackingTripId,
                      apiKey: _mapsApiKey,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'My Students',
                      'Manage',
                      _navigateToManageChildren,
                    ),
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
                    Text(
                      'Recent Alerts',
                      style: AppTypography.title.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    if (_notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No new alerts. You're all caught up!"),
                      )
                    else
                      ..._notifications
                          .take(3)
                          .map((n) => _ModernNotificationCard(notification: n)),
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

  SliverAppBar _buildModernAppBar() {
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
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _parentName,
                style: AppTypography.headline.copyWith(fontSize: 18),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Badge(
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionLabel,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.title.copyWith(fontSize: 20)),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatusCard() {
    final comingCount = _children
        .where((c) => c.attendance == AttendanceState.coming)
        .length;
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
                Text(
                  "Next Pickup",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '06:45 AM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$comingCount students scheduled',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: AppColors.accent,
                size: 32,
              ),
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
          const Icon(
            Icons.group_add_outlined,
            size: 48,
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          Text('No students added yet', style: AppTypography.title),
          const SizedBox(height: 8),
          Text(
            'Add a student to manage their rides',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
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

// --- Helper Components ---
class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({
    required this.onExpand,
    required this.tripId,
    this.apiKey,
  });
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
        // We use ClipRRect to keep the rounded corners for the map
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Use Native GoogleMap instead of NetworkImage to bypass HTTP 403 errors
              if (apiKey != null && apiKey!.isNotEmpty)
                IgnorePointer(
                  // Ignores all touches so it acts like a static image
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(6.9271, 79.8612), // Colombo coordinates
                      zoom: 13,
                    ),
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    liteModeEnabled:
                        true, // Optimizes performance on Android (makes it a static image)
                  ),
                )
              else
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Loading Map...",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

              if (tripId == null && apiKey != null && apiKey!.isNotEmpty)
                const Center(
                  child: Text(
                    "Map Preview",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.white70,
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.subtle,
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
                      const Text(
                        "Live Tracking",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.subtle,
                  ),
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

class _ModernNotificationCard extends StatelessWidget {
  const _ModernNotificationCard({required this.notification});
  final NotificationItem notification;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.accentLow,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active,
            color: AppColors.accent,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: AppTypography.title.copyWith(fontSize: 16),
        ),
        subtitle: Text(
          notification.body,
          style: AppTypography.body.copyWith(fontSize: 14),
        ),
      ),
    );
  }
}
