import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';

class CandidatesPage extends StatelessWidget {
  final Map<String, dynamic>? offer;
  const CandidatesPage({super.key, this.offer});

  final List<Map<String, dynamic>> _candidates = const [
    {
      'name': 'Aïcha Mballa',
      'education': 'Bac+5 • Informatique',
      'score': 88,
      'skills': ['Flutter', 'Dart', 'Firebase'],
      'isVerified': true,
    },
    {
      'name': 'Junior Kamga',
      'education': 'Bac+3 • Génie Logiciel',
      'score': 72,
      'skills': ['React', 'JavaScript', 'Node.js'],
      'isVerified': false,
    },
    {
      'name': 'Sandra Tchoumi',
      'education': 'Bac+4 • Informatique',
      'score': 65,
      'skills': ['Python', 'SQL'],
      'isVerified': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = List<Map<String, dynamic>>.from(_candidates)
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return Scaffold(
      backgroundColor: AppColorsLight.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColorsLight.textPrimary,
          ),
          onPressed: () => context.go('/company/offers'),
        ),
        backgroundColor: AppColorsLight.bgDark,
        elevation: 0,
        title: Text(
          offer != null ? offer!['title'] as String : 'Tous les candidats',
          style: AppTypography.headingMedium,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AI Top 3
            if (sorted.length >= 3)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColorsLight.primary,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColorsLight.primary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Top picks IA',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColorsLight.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Les 3 meilleurs profils pour cette offre',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final candidate = sorted[index];
                  return GestureDetector(
                    onTap: () => context.push('/company/candidates/app-$index'),
                    child: _CandidateCard(candidate: candidate),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  const _CandidateCard({required this.candidate});

  Color get _scoreColor {
    final score = candidate['score'] as int;
    if (score >= 75) return AppColorsLight.success;
    if (score >= 50) return AppColorsLight.warning;
    return AppColorsLight.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.bgSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColorsLight.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (candidate['name'] as String)[0],
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColorsLight.primary,
                        ),
                      ),
                    ),
                  ),
                  if (candidate['isVerified'] as bool)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColorsLight.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColorsLight.bgCard,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate['name'] as String,
                      style: AppTypography.headingSmall,
                    ),
                    Text(
                      candidate['education'] as String,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${candidate['score']}',
                    style: AppTypography.labelLarge.copyWith(
                      color: _scoreColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Skills
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: (candidate['skills'] as List<String>).map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColorsLight.bgSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  skill,
                  style: AppTypography.caption,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColorsLight.error,
                    side: const BorderSide(color: AppColorsLight.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsLight.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Retenir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}