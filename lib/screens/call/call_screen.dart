import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// 🚨 Make sure this imports your correct app's theme!
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

const String appId = '8470fb315c3f4fdfb549d4f2811e0d5a';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String callerName;
  final String agoraToken; // ✅ Real token from backend

  const CallScreen({
    super.key,
    required this.channelName,
    required this.callerName,
    required this.agoraToken,
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

  int _callDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAgora();
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
        // ✨ ADDED ASYNC HERE
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async { 
          debugPrint("✅ Joined local channel: ${connection.channelId}");
          setState(() => _isJoined = true);

          try {
            // ✨ ADDED AWAIT HERE to prevent the -3 crash!
            await _engine.setEnableSpeakerphone(_isSpeakerOn); 
          } catch (e) {
            debugPrint('⚠️ Could not set speakerphone: $e');
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("👋 Remote user joined: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
            _startTimer();
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("🏃 Remote user left: $remoteUid");
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
      token: widget.agoraToken, // ✅ Use the real Agora token
      channelId: safeChannelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  // ✨ ADDED ASYNC HERE
  void _toggleSpeaker() async { 
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    try {
      // ✨ ADDED AWAIT HERE
      await _engine.setEnableSpeakerphone(_isSpeakerOn); 
    } catch (e) {
      debugPrint('⚠️ Speaker toggle error: $e');
    }
  }

  Future<void> _leaveCall() async {
    _timer?.cancel();
    await _engine.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
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