import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';

class VideoCallPage extends StatefulWidget {
  final String name;
  final String? photoUrl;
  final String? subtitle;
  final List<String> jobDetails;

  const VideoCallPage({
    super.key,
    required this.name,
    this.photoUrl,
    this.subtitle,
    this.jobDetails = const [],
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  Timer? _timer;
  int _currentCardIndex = 0;
  List<String> _jobDetails = [];

  bool _isMicMuted = false;
  bool _isVideoOff = false;

  @override
  void initState() {
    super.initState();
    _jobDetails = widget.jobDetails;
    
    if (_jobDetails.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          setState(() {
            _currentCardIndex = (_currentCardIndex + 1) % _jobDetails.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- Main Video Feed (Other Person) ---
          if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty && !_isVideoOff)
            Positioned.fill(
              child: Image.network(
                widget.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.person, size: 100, color: Colors.white54),
                ),
              ),
            )
          else
            // Fallback si pas de photo ou vidéo désactivée
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1E1E1E),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Text(
                          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                          style: AppTypography.displayLarge.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
          // Un léger gradient sombre en haut et en bas pour assurer la lisibilité du texte
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.15, 0.7, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // --- Header (Bouton retour & Nom) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                        onPressed: () => context.pop(),
                      ),
                      Column(
                        children: [
                          Text(
                            widget.name,
                            style: AppTypography.headingSmall.copyWith(
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
                            ),
                          ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                            Text(
                              widget.subtitle!,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white70,
                                shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 48), // Pour centrer le texte avec l'icône à gauche
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Animated Job Description Cards ---
                if (_jobDetails.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, -0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<int>(_currentCardIndex),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColorsLight.primary.withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _jobDetails[_currentCardIndex],
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // --- Local Camera PiP (Picture-in-Picture) ---
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 20, bottom: 20),
                    width: 110,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.5),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Placeholder pour notre propre caméra (gris avec icône par défaut)
                          Container(
                            color: const Color(0xFF2A2A2A),
                            child: const Center(
                              child: Icon(Icons.person, color: Colors.white38, size: 50),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Panneau de contrôle ---
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: AppColorsLight.primary.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                              icon: Icons.flip_camera_android_rounded,
                              onTap: () {}, // Simuler le switch caméra
                            ),
                            _buildControlButton(
                              icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                              onTap: () {
                                setState(() {
                                  _isVideoOff = !_isVideoOff;
                                });
                              },
                              isActive: !_isVideoOff,
                            ),
                            _buildControlButton(
                              icon: _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              onTap: () {
                                setState(() {
                                  _isMicMuted = !_isMicMuted;
                                });
                              },
                              isActive: !_isMicMuted,
                            ),
                            // Raccrocher
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white54,
          size: 28,
        ),
      ),
    );
  }
}
