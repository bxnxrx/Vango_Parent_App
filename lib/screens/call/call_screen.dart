import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/services/call_service.dart';

const String appId = '8470fb315c3f4fdfb549d4f2811e0d5a';

// ✅ Ringing timeout — auto-cancel if driver doesn't answer within this time
const int _kRingTimeoutSeconds = 30;

class CallScreen extends StatefulWidget {
  final String channelName;
  final String callerName;
  final String agoraToken;
  final String receiverId; // ✅ Needed to send cancel notification

  const CallScreen({
    super.key,
    required this.channelName,
    required this.callerName,
    required this.agoraToken,
    this.receiverId = '', // Default to empty for incoming call scenario
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine _engine;
  bool _isJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isLeaving = false; // ✅ Prevent double-leave crashes

  int _callDuration = 0;
  Timer? _timer;
  Timer? _ringTimeout; // ✅ Timeout timer for unanswered calls

  // ✅ Supabase Realtime channel to listen for driver decline
  RealtimeChannel? _declineChannel;

  @override
  void initState() {
    super.initState();
    // Only listen for decline if parent is the CALLER (has a receiverId)
    if (widget.receiverId.isNotEmpty) {
      _listenForDecline();
    }
    _initAgora();
  }

  // ✅ Listen for driver decline via Supabase Realtime broadcast
  void _listenForDecline() {
    final channelId = 'call:${widget.channelName}';
    debugPrint('📡 [PARENT CALL] Subscribing to decline channel: $channelId');

    _declineChannel = Supabase.instance.client.channel(channelId);

    _declineChannel!
        .onBroadcast(
          event: 'declined',
          callback: (payload) {
            debugPrint('🛑 [PARENT CALL] Driver DECLINED the call! Closing call screen...');
            if (mounted && !_isLeaving) {
              _leaveCall();
            }
          },
        )
        .subscribe();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          debugPrint("✅ [PARENT CALL] Joined channel: ${connection.channelId}");
          if (!mounted) return;
          setState(() => _isJoined = true);

          // ✅ Start ring timeout if parent is the caller
          if (widget.receiverId.isNotEmpty) {
            _startRingTimeout();
          }

          try {
            await _engine.setEnableSpeakerphone(_isSpeakerOn);
          } catch (e) {
            debugPrint('⚠️ Could not set speakerphone: $e');
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("👋 [PARENT CALL] Remote user joined: $remoteUid");
          // Driver answered! Cancel the ring timeout
          _ringTimeout?.cancel();
          _ringTimeout = null;
          if (!mounted) return;
          setState(() {
            _remoteUid = remoteUid;
            _startCallTimer();
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("🏃 [PARENT CALL] Remote user left: $remoteUid");
          if (!mounted) return;
          setState(() => _remoteUid = null);
          _leaveCall();
        },
      ),
    );

    await _engine.enableAudio();

    // ✅ MUST match the driver app's truncation exactly — both use substring(0,64)
    String safeChannelName = widget.channelName;
    if (safeChannelName.length > 64) {
      safeChannelName = safeChannelName.substring(0, 64);
    }

    await _engine.joinChannel(
      token: widget.agoraToken,
      channelId: safeChannelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  // ✅ Ring timeout — if driver doesn't answer in 30s, auto-cancel
  void _startRingTimeout() {
    _ringTimeout?.cancel();
    _ringTimeout = Timer(const Duration(seconds: _kRingTimeoutSeconds), () {
      debugPrint('⏰ [PARENT CALL] Ring timeout! Driver did not answer in ${_kRingTimeoutSeconds}s.');
      if (mounted && _remoteUid == null) {
        _leaveCall();
      }
    });
  }

  void _startCallTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _engine.muteLocalAudioStream(_isMuted);
    });
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    try {
      await _engine.setEnableSpeakerphone(_isSpeakerOn);
    } catch (e) {
      debugPrint('⚠️ Speaker toggle error: $e');
    }
  }

  // ✅ Leave call + send cancel if driver never answered
  Future<void> _leaveCall() async {
    if (_isLeaving) return; // Prevent double calls
    _isLeaving = true;

    _timer?.cancel();
    _ringTimeout?.cancel();

    // ✅ Unsubscribe from decline channel
    if (_declineChannel != null) {
      Supabase.instance.client.removeChannel(_declineChannel!);
    }

    try {
      await _engine.leaveChannel();
    } catch (e) {
      debugPrint('⚠️ Error leaving channel: $e');
    }

    // ✅ Clean up CallKit state
    final sessionId = const Uuid().v5(Uuid.NAMESPACE_URL, widget.channelName);
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: sessionId);
    ConnectycubeFlutterCallKit.clearCallData(sessionId: sessionId);
    debugPrint('✅ CallKit state cleaned up after call ended (session: $sessionId)');

    // ✅ If driver never joined (unanswered call) and parent is the caller,
    // send cancel notification so the driver's CallKit ringing is dismissed
    if (_remoteUid == null && widget.receiverId.isNotEmpty) {
      debugPrint('🛑 [PARENT CALL] Driver never answered. Sending cancel notification...');
      await CallService.instance.cancelCall(
        receiverId: widget.receiverId,
        channelName: widget.channelName,
      );
      debugPrint('✅ [PARENT CALL] Cancel notification sent.');
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringTimeout?.cancel();
    if (_declineChannel != null) {
      Supabase.instance.client.removeChannel(_declineChannel!);
    }
    _engine.leaveChannel();
    _engine.release();

    // ✅ Ensure CallKit is cleaned up even if dispose is called directly
    final sessionId = const Uuid().v5(Uuid.NAMESPACE_URL, widget.channelName);
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: sessionId);
    ConnectycubeFlutterCallKit.clearCallData(sessionId: sessionId);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF1A1A24) : Colors.grey[100];

    String callStatus = "Connecting...";
    if (_isJoined && _remoteUid == null) callStatus = "Ringing...";
    if (_remoteUid != null) callStatus = _formatDuration(_callDuration);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 80),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: Text(
                    widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
                    style: AppTypography.display.copyWith(color: AppColors.accent, fontSize: 48),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  widget.callerName,
                  style: AppTypography.headline.copyWith(color: textColor, fontSize: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  callStatus,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    fontWeight: _remoteUid != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    isActive: _isSpeakerOn,
                    onTap: _toggleSpeaker,
                    isDark: isDark,
                  ),
                  GestureDetector(
                    onTap: _leaveCall,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    isActive: _isMuted,
                    onTap: _toggleMute,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? Colors.white : Colors.black87) : (isDark ? AppColors.darkSurfaceStrong : Colors.white),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(
          icon,
          color: isActive ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : Colors.black87),
          size: 28,
        ),
      ),
    );
  }
}