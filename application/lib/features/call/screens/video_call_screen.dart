import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/call_request_service.dart';
import '../../auth/services/auth_service.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';
import '../widgets/rating_popup.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String remoteUserName;
  final int? uid; // Optional specific UID
  final String? callRequestId;
  final bool isDoctor;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.remoteUserName,
    this.uid,
    this.callRequestId,
    this.isDoctor = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _muted = false;
  bool _speakerOn = true;
  Timer? _timer;
  int _seconds = 0;
  bool _isLoading = true;
  Timer? _callStatusTimer;
  bool _ending = false;
  late final int _localUid;

  // App ID from the user
  final String _appId = 'ae6f0f0e29904fa88c92b1d52b98acc5';

  @override
  void initState() {
    super.initState();
    // Generate a random UID if not provided, to ensure unique identification
    _localUid = widget.isDoctor ? 1 : 2;
    _initAgora();
    _startTimer();
    _startCallStatusPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callStatusTimer?.cancel();
    _disposeAgora();
    super.dispose();
  }

  Future<void> _disposeAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _initAgora() async {
    // 1. Request permissions properly and check results
    final statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    final isMicGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final isCameraGranted = statuses[Permission.camera]?.isGranted ?? false;

    if (!isMicGranted || !isCameraGranted) {
      if (mounted) {
        String message = 'Permissions required:';
        if (!isMicGranted) message += ' Microphone';
        if (!isCameraGranted) message += '${!isMicGranted ? "," : ""} Camera';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        context.pop();
      }
      return;
    }

    // 2. Create the engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
          // Ensure speakerphone is on after joining
          _engine.setEnableSpeakerphone(_speakerOn);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
          _handleRemoteLeft();
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('Token expiring');
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Agora Error: $err, $msg');
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          debugPrint('Connection state changed: $state, reason: $reason');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.enableAudio(); // Explicitly enable audio
    await _engine.startPreview();

    // Set default audio route to speaker - wrap in try-catch to avoid crash on some devices
    try {
      await _engine.setEnableSpeakerphone(_speakerOn);
      await _engine.setDefaultAudioRouteToSpeakerphone(_speakerOn);
    } catch (e) {
      debugPrint('Error setting speakerphone: $e');
    }

    // Fetch token from backend
    try {
      final token = await _fetchToken(widget.channelName, _localUid);
      if (token != null) {
        await _engine.joinChannel(
          token: token,
          channelId: widget.channelName,
          uid: _localUid,
          options: const ChannelMediaOptions(
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch token');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start call: Token error')),
          );
          context.pop();
        }
      }
    } catch (e) {
      debugPrint('Error joining channel: $e');
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<String?> _fetchToken(String channelName, int uid) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/agora/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'channelName': channelName,
          'uid': uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching token: $e');
      return null;
    }
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteLocalAudioStream(_muted);
    // Also ensure microphone is actually enabled/disabled at the engine level
    _engine.enableLocalAudio(!_muted);
  }

  void _onToggleSpeaker() {
    setState(() {
      _speakerOn = !_speakerOn;
    });
    _engine.setEnableSpeakerphone(_speakerOn);
    // Explicitly set the audio route to ensure it switches between earpiece and speaker
    _engine.setDefaultAudioRouteToSpeakerphone(_speakerOn);
  }

  void _onCallEnd() {
    _endCallAndNotify();
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void _startCallStatusPolling() {
    if (widget.callRequestId == null || widget.callRequestId!.isEmpty) return;
    _callStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_ending) return;
      final token = await _getToken();
      if (token == null) return;
      final call = await CallRequestService().getCallRequest(
        token: token,
        callRequestId: widget.callRequestId!,
      );
      if (call == null) return;
      if (call.status == 'cancelled' || call.status == 'declined' || call.status == 'timeout') {
        _ending = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call ended')),
          );
          
          if (!widget.isDoctor && _seconds > 0) {
            // Show rating popup for patient
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => RatingPopup(
                doctorName: widget.remoteUserName,
                onSave: (rating, comment) async {
                  if (token != null && widget.callRequestId != null) {
                    await CallRequestService().updateCallReport(
                      token: token,
                      callRequestId: widget.callRequestId!,
                      rating: rating,
                      ratingComment: comment,
                    );
                  }
                  if (mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    context.pop(); // Exit call screen
                  }
                },
                onLater: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.pop(); // Exit call screen
                },
              ),
            );
          } else {
            context.pop();
          }
        }
      }
    });
  }

  Future<String?> _getToken() async {
    if (widget.isDoctor) {
      return DoctorAuthService().getDoctorToken();
    }
    return AuthService().getToken();
  }

  Future<void> _endCallAndNotify() async {
    if (_ending) return;
    _ending = true;
    final token = await _getToken();
    if (widget.callRequestId != null && widget.callRequestId!.isNotEmpty) {
      if (token != null) {
        final status = _seconds > 0 ? 'completed' : 'cancelled';
        await CallRequestService().updateCallReport(
          token: token,
          callRequestId: widget.callRequestId!,
          status: status,
          duration: _seconds,
        );
      }
    }

    if (mounted) {
      if (!widget.isDoctor && _seconds > 0) {
        // Show rating popup for patient if call was successful
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RatingPopup(
            doctorName: widget.remoteUserName,
            onSave: (rating, comment) async {
              if (token != null && widget.callRequestId != null) {
                await CallRequestService().updateCallReport(
                  token: token,
                  callRequestId: widget.callRequestId!,
                  rating: rating,
                  ratingComment: comment,
                );
              }
              if (mounted) {
                Navigator.of(context).pop(); // Close dialog
                context.pop(); // Exit call screen
              }
            },
            onLater: () {
              Navigator.of(context).pop(); // Close dialog
              context.pop(); // Exit call screen
            },
          ),
        );
      } else {
        context.pop();
      }
    }
  }

  Future<void> _handleRemoteLeft() async {
    if (_ending) return;
    _ending = true;
    final token = await _getToken();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User left the call')),
      );

      if (!widget.isDoctor && _seconds > 0) {
        // Show rating popup for patient
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RatingPopup(
            doctorName: widget.remoteUserName,
            onSave: (rating, comment) async {
              if (token != null && widget.callRequestId != null) {
                await CallRequestService().updateCallReport(
                  token: token,
                  callRequestId: widget.callRequestId!,
                  rating: rating,
                  ratingComment: comment,
                );
              }
              if (mounted) {
                Navigator.of(context).pop(); // Close dialog
                context.pop(); // Exit call screen
              }
            },
            onLater: () {
              Navigator.of(context).pop(); // Close dialog
              context.pop(); // Exit call screen
            },
          ),
        );
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video (Big Screen)
            Center(
              child: _remoteVideo(),
            ),
            
            // Top Bar (User Name and Time)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.remoteUserName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatTime(_seconds),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Local Video (Small Screen)
            Positioned(
              bottom: 120,
              right: 20,
              child: SizedBox(
                width: 120,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: Colors.grey[800],
                    child: _localUserJoined
                        ? AgoraVideoView(
                            key: const ValueKey('local'),
                            controller: VideoViewController(
                              rtcEngine: _engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              ),
            ),

            // Controls
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Speaker Toggle
                    _buildControlButton(
                      onPressed: _onToggleSpeaker,
                      icon: _speakerOn ? Icons.volume_up : Icons.phone_in_talk,
                      color: Colors.white,
                      backgroundColor: Colors.grey[700]!,
                    ),
                    
                    // Mute Toggle
                    _buildControlButton(
                      onPressed: _onToggleMute,
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      color: _muted ? Colors.black : Colors.white,
                      backgroundColor: _muted ? Colors.white : Colors.grey[700]!,
                    ),
                    
                    // End Call
                    _buildControlButton(
                      onPressed: _onCallEnd,
                      icon: Icons.call_end,
                      color: Colors.white,
                      backgroundColor: Colors.red,
                      size: 70,
                    ),

                    // Switch Camera
                    _buildControlButton(
                      onPressed: _onSwitchCamera,
                      icon: Icons.switch_camera,
                      color: Colors.white,
                      backgroundColor: Colors.grey[700]!,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Waiting for user to join...',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          CircularProgressIndicator(color: Colors.white.withOpacity(0.5)),
        ],
      );
    }
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }
}
