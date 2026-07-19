import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../presentation/widgets/user_avatar.dart';

class AudioCallPage extends StatefulWidget {
  final String name;
  final String? photoUrl;
  final String? subtitle;
  final List<String> jobDetails;

  const AudioCallPage({
    super.key,
    required this.name,
    this.photoUrl,
    this.subtitle,
    this.jobDetails = const [],
  });

  @override
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  Timer? _timer;
  int _currentCardIndex = 0;
  List<String> _jobDetails = [];

  @override
  void initState() {
    super.initState();
    _jobDetails = widget.jobDetails;
    
    if (_jobDetails.isNotEmpty) {
      // Change la carte toutes les 4 secondes
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
      backgroundColor: const Color(0xFF121B22), // WhatsApp dark background
      body: Stack(
        children: [
          // Flou en arrière plan si on a une photo
          if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.network(
                  widget.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header (Bouton pour réduire)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox.shrink(),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 32),

                // Nom et Statut
                Text(
                  widget.name,
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Appel en cours...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      widget.subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                const Spacer(),

                // Avatar principal
                Hero(
                  tag: 'call_avatar',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
                    ),
                    child: UserAvatar(
                      imageUrl: widget.photoUrl,
                      radius: 75,
                      defaultIcon: Icons.person_rounded,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      iconColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Animated Job Description Cards
                if (_jobDetails.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColorsLight.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _jobDetails[_currentCardIndex],
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(flex: 2),

                // Panneau de contrôle
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                              icon: Icons.volume_up_rounded,
                              onTap: () {},
                            ),
                            _buildControlButton(
                              icon: Icons.videocam_rounded,
                              onTap: () {},
                              isActive: false, // Grisé car on est en audio
                            ),
                            _buildControlButton(
                              icon: Icons.mic_off_rounded,
                              onTap: () {},
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
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: 28,
        ),
      ),
    );
  }
}
