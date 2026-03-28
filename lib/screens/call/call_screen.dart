import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// 🚨 Parent App Imports
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

// Your exact Agora App ID
const String appId = '8470fb315c3f4fdfb549d4f2811e0d5a';

class CallScreen extends StatefulWidget {
  final String channelName; // The unique Room ID (e.g., the chatId)
  final String callerName; // Name of the person you are talking to

  const CallScreen({
    super.key,
    required this.channelName,
    required this.callerName,
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
    // 1. Request microphone permission
    await [Permission.microphone].request();

    // 2. Create and initialize the Agora Engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // 3. Set up event handlers to know when people join/leave
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("✅ Joined local channel: ${connection.channelId}");
          setState(() => _isJoined = true);

          // ✨ Safely turn on speakerphone AFTER joining
          try {
            _engine.setEnableSpeakerphone(_isSpeakerOn);
          } catch (e) {
            debugPrint('⚠️ Could not set speakerphone: $e');
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("👋 Remote user joined: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
            _startTimer(); // Start counting when they pick up!
          });
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("🏃 Remote user left: $remoteUid");
              setState(() => _remoteUid = null);
              _leaveCall(); // Auto-end call if the other person hangs up
            },
      ),
    );

    // 4. Enable audio
    await _engine.enableAudio();

    // ✨ FIX: Agora strict 64-character limit handled via deterministic UUID
    String safeChannelName = widget.channelName;
    if (safeChannelName.length > 64) {
      // Compress the long string into a unique 36-character string
      safeChannelName = const Uuid().v5(Uuid.NAMESPACE_URL, widget.channelName);
    }

    // We pass a blank token because we selected "App ID Only" in the console
    await _engine.joinChannel(
      token: '',
      channelId: safeChannelName, // 🚨 Safely shortened name passed here!
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

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      _engine.setEnableSpeakerphone(_isSpeakerOn);
    });
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
            // --- TOP SECTION: Caller Info ---
            Column(
              children: [
                const SizedBox(height: 80),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: Text(
                    widget.callerName.isNotEmpty
                        ? widget.callerName[0].toUpperCase()
                        : '?',
                    style: AppTypography.display.copyWith(
                      color: AppColors.accent,
                      fontSize: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  widget.callerName,
                  style: AppTypography.headline.copyWith(
                    color: textColor,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  callStatus,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    fontWeight: _remoteUid != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),

            // --- BOTTOM SECTION: Controls ---
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speaker Button
                  _buildControlButton(
                    icon: _isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_down_rounded,
                    isActive: _isSpeakerOn,
                    onTap: _toggleSpeaker,
                    isDark: isDark,
                  ),

                  // End Call Button
                  GestureDetector(
                    onTap: _leaveCall,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  // Mute Button
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
          color: isActive
              ? (isDark ? Colors.white : Colors.black87)
              : (isDark ? AppColors.darkSurfaceStrong : Colors.white),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white : Colors.black87),
          size: 28,
        ),
      ),
    );
  }
}
