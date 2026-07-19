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
      'icon': Icons.work_outline_rounded,
      'title': 'Trouve l\'emploi idéal',
      'subtitle':
          'Des milliers d\'opportunités t\'attendent dans tout le Cameroun.',
      'isDark': false,
    },
    {
      'icon': Icons.auto_awesome_outlined,
      'title': 'Matching par IA',
      'subtitle':
          'Notre IA analyse ton profil et trouve les meilleures offres qui te correspondent.',
      'isDark': false,
    },
    {
      'icon': Icons.description_outlined,
      'title': 'Recommandation de CV',
      'subtitle':
          'Démarque-toi grâce aux conseils et recommandations personnalisés de notre IA.',
      'isDark': false,
    },
    {
      'icon': Icons.groups_outlined,
      'title': 'Recrutez les meilleurs',
      'subtitle':
          'Entreprises, publiez vos offres et trouvez les talents parfaits grâce à notre algorithme de matching.',
      'isDark': false,
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
    final bool isDark = _slides[_currentPage]['isDark'] as bool;
    final Color bgColor = isDark ? const Color(0xFF161821) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1D26);
    final Color subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: bgColor,
        child: SafeArea(
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
                      color: textColor,
                      fontWeight: FontWeight.w600,
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
                    final slideIsDark = slide['isDark'] as bool;
                    final sTextColor = slideIsDark ? Colors.white : const Color(0xFF1A1D26);
                    final sSubtitleColor = slideIsDark ? Colors.white70 : const Color(0xFF6B7280);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon / Illustration placeholder
                          Container(
                            height: 250,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Décoration graphique subtile (cercle coloré)
                                Positioned(
                                  right: 20,
                                  top: 20,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFFACC15), Color(0xFFE81CFF)], // Jaune/Rose
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                                // Icone principale style line-art
                                Icon(
                                  slide['icon'] as IconData,
                                  size: 190,
                                  color: slideIsDark ? Colors.white : Colors.black87,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title
                          Text(
                            slide['title'] as String,
                            style: AppTypography.displayMedium.copyWith(
                              color: sTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Subtitle
                          Text(
                            slide['subtitle'] as String,
                            style: AppTypography.bodyLarge.copyWith(
                              color: sSubtitleColor,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom navigation row (Indicators + Next Button)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Indicators
                    Row(
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: _currentPage == index ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColorsLight.primary // Couleur principale de l'app
                                : (_slides[_currentPage]['isDark']
                                    ? Colors.white24
                                    : Colors.black12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    // Next / Start Button (Circular)
                    InkWell(
                      onTap: _nextPage,
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColorsLight.primary, // Couleur principale de l'app
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
