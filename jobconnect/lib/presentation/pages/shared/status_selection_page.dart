import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';

// ─── Modèle typé ──────────────────────────────
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
      subtitle: 'Étudiant, jeune diplômé ou en formation\nJe cherche un emploi',
      role: 'student',
      tag: 'Étudiants & Diplômés',
      tagIcon: Icons.school_rounded,
    ),
    _RoleOption(
      icon: Icons.corporate_fare_rounded,
      colorA: Color(0xFF00D9FF),
      colorB: Color(0xFF0052CC),
      title: 'Entreprise / Recruteur',
      subtitle: 'Entreprise, RH ou cabinet\nJe recrute des talents',
      role: 'company',
      tag: 'Recruteurs & RH',
      tagIcon: Icons.badge_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Illustration style Onboarding
              Container(
                height: 140,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 50,
                        height: 50,
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
                    const Icon(
                      Icons.handshake_outlined,
                      size: 110,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Bienvenue !',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              Text(
                'Choisissez votre profil pour continuer',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Cards
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _roles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role.role;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedRole = role.role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColorsLight.primary : Colors.grey[50],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? AppColorsLight.primary : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColorsLight.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.15) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected ? null : Border.all(color: Colors.grey[200]!),
                              ),
                              child: Icon(
                                role.icon,
                                color: isSelected ? Colors.white : AppColorsLight.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withOpacity(0.2) : AppColorsLight.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          role.tagIcon,
                                          size: 12,
                                          color: isSelected ? Colors.white : AppColorsLight.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          role.tag,
                                          style: AppTypography.caption.copyWith(
                                            color: isSelected ? Colors.white : AppColorsLight.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    role.title,
                                    style: AppTypography.headingMedium.copyWith(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role.subtitle,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isSelected ? Colors.white70 : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: isSelected
                                  ? Container(
                                      key: const ValueKey('on'),
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: AppColorsLight.primary,
                                        size: 18,
                                      ),
                                    )
                                  : Container(
                                      key: const ValueKey('off'),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey[300]!,
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

              // Button
              ElevatedButton(
                onPressed: _selectedRole == null
                    ? null
                    : () => context.go(
                        '/register',
                        extra: {'role': _selectedRole},
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLight.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey[500],
                  elevation: _selectedRole != null ? 4 : 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Continuer',
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 16,
                    color: _selectedRole != null ? Colors.white : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
