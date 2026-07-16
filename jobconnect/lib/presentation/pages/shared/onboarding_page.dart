import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.school_rounded,
      'color': AppColorsLight.primary,
      'title': 'Trouve l\'emploi ou le stage idéal',
      'subtitle': 'Des milliers d\'opportunités t\'attendent dans toute le cameroun et au-delà',
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'color': AppColorsLight.secondary,
      'title': 'Matching par IA',
      'subtitle': 'Notre IA analyse ton profil et trouve les meilleures offres qui te correspondent',
    },
    {
      'icon': Icons.business_rounded,
      'color': AppColorsLight.success,
      'title': 'Les meilleures entreprises',
      'subtitle': 'Connecte-toi avec des entreprises de qualité partout où tu es',
    },
    {
      'icon': Icons.verified_rounded,
      'color': AppColorsLight.warning,
      'title': 'Profil vérifié',
      'subtitle': 'Obtiens le badge certifié et augmente tes chances de 40%',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/status-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsLight.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/status-selection'),
                child: Text(
                  'Passer',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColorsLight.textSecondary,
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (slide['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            color: slide['color'] as Color,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Title
                        Text(
                          slide['title'] as String,
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Subtitle
                        Text(
                          slide['subtitle'] as String,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColorsLight.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColorsLight.primary
                        : AppColorsLight.textTertiary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLight.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  _currentPage == _slides.length - 1
                      ? 'Commencer'
                      : 'Suivant',
                  style: AppTypography.labelLarge,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}