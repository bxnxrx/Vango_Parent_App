import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:intl/intl.dart';

class NotificationPanelScreen extends StatefulWidget {
  const NotificationPanelScreen({super.key});

  @override
  State<NotificationPanelScreen> createState() => _NotificationPanelScreenState();
}

class _NotificationPanelScreenState extends State<NotificationPanelScreen> {
  final _supabase = Supabase.instance.client;

  // Mark all notifications as read
  Future<void> _markAllAsRead(List<Map<String, dynamic>> unreadNotifications) async {
    if (unreadNotifications.isEmpty) return;
    
    try {
      final unreadIds = unreadNotifications.map((n) => n['id']).toList();
      await _supabase
          .from('notification_logs')
          .update({'is_read': true})
          .inFilter('id', unreadIds); // Updates all matching IDs instantly
    } catch (e) {
      debugPrint("Failed to mark all as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text("Notifications", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('notification_logs')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final notifications = snapshot.data ?? [];
          final unreadNotifications = notifications.where((n) => n['is_read'] != true).toList();

          return Column(
            children: [
              // Header with "Mark all as read" button
              if (notifications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${notifications.length} Alerts", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      if (unreadNotifications.isNotEmpty)
                        TextButton(
                          onPressed: () => _markAllAsRead(unreadNotifications),
                          child: const Text("Mark all as read", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              
              // The List of Notifications
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("No notifications yet", style: AppTypography.title.copyWith(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return _PanelNotificationCard(alertData: notifications[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Re-using your exact pop-up card design so it matches the home screen!
// 👇 UPDATED: Added Time formatting to the Panel Screen!
class _PanelNotificationCard extends StatefulWidget {
  const _PanelNotificationCard({required this.alertData});
  final Map<String, dynamic> alertData;

  @override
  State<_PanelNotificationCard> createState() => _PanelNotificationCardState();
}

class _PanelNotificationCardState extends State<_PanelNotificationCard> {
  late bool _localIsRead;

  @override
  void initState() {
    super.initState();
    _localIsRead = widget.alertData['is_read'] == true;
  }

  @override
  void didUpdateWidget(covariant _PanelNotificationCard oldWidget) {
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
      debugPrint("Failed to mark as read: $e");
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
                          // 👇 Time added to the Pop-up Dialog
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

  // 👇 Helper function to format time
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
        return DateFormat('h:mm a').format(date);
      } else if (difference.inDays < 2) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM d').format(date);
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
                  // 👇 Title row now includes the time string on the right
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
                child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }
}