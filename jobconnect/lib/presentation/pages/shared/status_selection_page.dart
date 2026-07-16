import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';

// ─── Modèle typé — plus de Map<String, dynamic> ──────────────────────────────
class _RoleOption {
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final String title;
  final String subtitle;
  final String role;
  final String tag;
  final IconData tagIcon;

  const _RoleOption({
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.title,
    required this.subtitle,
    required this.role,
    required this.tag,
    required this.tagIcon,
  });

  List<Color> get colors => [colorA, colorB];
}

// ─────────────────────────────────────────────────────────────────────────────
class StatusSelectionPage extends StatefulWidget {
  const StatusSelectionPage({super.key});

  @override
  State<StatusSelectionPage> createState() => _StatusSelectionPageState();
}

class _StatusSelectionPageState extends State<StatusSelectionPage> {
  String? _selectedRole;

  static const _roles = [
    _RoleOption(
      icon: Icons.person_search_rounded,
      colorA: Color(0xFF0052CC),
      colorB: Color(0xFF00D9FF),
      title: 'Candidat',
      subtitle: 'Étudiant, jeune diplômé ou en formation\nJe cherche un emploi ou un stage',
      role: 'student',
      tag: 'Étudiants,diplômés',
      tagIcon: Icons.school_rounded,
    ),
    _RoleOption(
      icon: Icons.corporate_fare_rounded,
      colorA: Color(0xFF00D9FF),
      colorB: Color(0xFF0052CC),
      title: 'Entreprise / Recruteur',
      subtitle: 'Je recrute des talents pour mon entreprise',
      role: 'company',
      tag: 'Recruteurs & RH',
      tagIcon: Icons.badge_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background Gradient Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35, // Réduit la hauteur du violet
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColorsLight.primary, AppColorsLight.textPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      // Brand mark
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.device_hub, color: AppColorsLight.bgDark, size: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'JobConnect',
                            style: AppTypography.displayMedium.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Bienvenue !',
                        style: AppTypography.displayMedium.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Choisissez votre profil pour continuer',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.22), // Remonte la carte blanche
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusXl),
                        topRight: Radius.circular(AppSpacing.radiusXl),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Role cards
                        Expanded(
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _roles.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final role = _roles[index];
                              final isSelected = _selectedRole == role.role;

                              return GestureDetector(
                                onTap: () => setState(() => _selectedRole = role.role),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  constraints: const BoxConstraints(minHeight: 130), // Force la même taille pour les deux cartes
                                  padding: const EdgeInsets.all(AppSpacing.lg), // Agrandissement de la carte
                                  decoration: BoxDecoration(
                                    color: isSelected ?  AppColorsLight.primary : AppColorsLight.textPrimary, // Fond violet
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColorsLight.primary.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center, // Centre le contenu verticalement
                                    children: [
                                      // Icon
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        width: 64, // Agrandi
                                        height: 64, // Agrandi
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15), // Fond semi-transparent clair
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                        ),
                                        child: Icon(
                                          role.icon,
                                          color: Colors.white, // Icône blanche
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),

                                      // Text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(role.tagIcon, size: 12, color: Colors.white),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    role.tag,
                                                    style: AppTypography.caption.copyWith(
                                                      color: Colors.white, // Tag blanc
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              role.title,
                                              style: AppTypography.headingMedium.copyWith(
                                                fontSize: 16,
                                                color: Colors.white, // Titre blanc
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              role.subtitle,
                                              style: AppTypography.bodySmall.copyWith(
                                                color: Colors.grey[300], // Sous-titre gris clair
                                                fontSize: 12,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),

                                      // Checkmark
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                        child: isSelected
                                            ? Container(
                                                key: const ValueKey('on'),
                                                width: 32,
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check_rounded, color: AppColorsLight.primary, size: 18),
                                              )
                                            : Container(
                                                key: const ValueKey('off'),
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.5),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Continue button
                        ElevatedButton(
                          onPressed: _selectedRole == null
                              ? null
                              : () => context.go('/register', extra: {'role': _selectedRole}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorsLight.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                            elevation: _selectedRole != null ? 2 : 0,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continuer',
                                style: AppTypography.labelLarge.copyWith(
                                  fontSize: 16,
                                  color: _selectedRole != null ? Colors.white : Colors.grey[600],
                                ),
                              ),
                              if (_selectedRole != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}