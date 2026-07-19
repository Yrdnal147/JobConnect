import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/supabase/supabase_client.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  final String _textJob = "Job";
  final String _textConnect = "Connect";
  late List<Animation<double>> _letterFades;
  late List<Animation<Offset>> _letterSlides;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600), // Rallongé de 1.6s à 2.6s
    );

    // 0.0s -> 0.5s (0.0 to 0.20 in AnimationController)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.20, curve: Curves.easeIn),
      ),
    );
    _logoScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.20, curve: Curves.easeOutCubic),
      ),
    );

    // 0.5s -> 2.6s (0.20 to 1.0 in AnimationController)
    final totalLetters = _textJob.length + _textConnect.length;
    _letterFades = [];
    _letterSlides = [];

    final double letterDuration =
        0.35; // Chaque lettre prend ~910ms pour s'animer (très fluide)
    final double staggerDelay =
        (0.80 - letterDuration) / (totalLetters > 1 ? totalLetters - 1 : 1);

    for (int i = 0; i < totalLetters; i++) {
      final start = 0.20 + (i * staggerDelay);
      final end = start + letterDuration;

      _letterFades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _letterSlides.add(
        Tween<Offset>(begin: const Offset(0.4, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    _controller.forward();

    // 3.6s timeline for navigation (laisse 1s de pause après l'animation)
    Future.delayed(const Duration(milliseconds: 3600), () {
      if (!mounted) return;

      if (SupabaseClientHelper.isLoggedIn) {
        final role = SupabaseClientHelper.userRole;

        if (role == 'company') {
          context.go('/company/dashboard');
        } else {
          context.go('/student/home');
        }
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLetter(String letter, int index, bool isJobPart) {
    return FadeTransition(
      opacity: _letterFades[index],
      child: SlideTransition(
        position: _letterSlides[index],
        child: Text(
          letter,
          style: AppTypography.displayMedium.copyWith(
            color: isJobPart
                ? AppColorsLight.primary
                : AppColorsLight.primary.withOpacity(0.85), // Texte bleu sur fond blanc
            fontWeight: isJobPart ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: -0.6,
            fontSize: 42, // Taille réduite
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Fond blanc
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              // ================= APP NAME ANIMATED =================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _textJob.length; i++)
                    _buildLetter(_textJob[i], i, true),
                  for (int i = 0; i < _textConnect.length; i++)
                    _buildLetter(_textConnect[i], _textJob.length + i, false),
                ],
              ),

              const SizedBox(height: 12),

              // ================= TAGLINE =================
              FadeTransition(
                opacity: _logoFade, // Fade in with the logo
                child: Text(
                  "Trouve ton opportunité",
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.black.withOpacity(
                      0.6,
                    ), // Gris foncé
                    letterSpacing: 0.5,
                  ),
                ),
              ),
                ],
              ),
            ),
            
            // ================= BOTTOM TEXT =================
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _logoFade,
                child: Column(
                  children: [
                    Text(
                      "from Ziloo",
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.black.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "v1.0.0",
                      style: AppTypography.caption.copyWith(
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
