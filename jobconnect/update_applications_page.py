import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\applications\applications_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the whole _AppCard class
old_class_pattern = r"class _AppCard extends StatelessWidget \{.*?\}\s*\}(?!.*\})"
old_class_compiled = re.compile(old_class_pattern, re.DOTALL)

new_app_card = """class _AppCard extends StatelessWidget {
  final ApplicationItem application;
  final List<Color> gradient;
  final String Function(String) formatType;

  const _AppCard({
    required this.application,
    required this.gradient,
    required this.formatType,
  });

  Color get _statusColor {
    switch (application.status) {
      case 'retained': return AppColorsLight.primary;
      case 'refused':  return AppColorsLight.textTertiary;
      default:         return AppColorsLight.textSecondary;
    }
  }

  String get _statusLabel {
    switch (application.status) {
      case 'retained': return 'applications.status.retained'.tr();
      case 'refused':  return 'applications.status.refused'.tr();
      default:         return 'applications.status.pending'.tr();
    }
  }

  IconData get _statusIcon {
    switch (application.status) {
      case 'retained': return Icons.check_circle_rounded;
      case 'refused':  return Icons.cancel_rounded;
      default:         return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = application.matchScore;
    final scoreColor = score >= 75
        ? AppColorsLight.success
        : score >= 55
            ? AppColorsLight.warning
            : AppColorsLight.error;

    return Container(
      decoration: BoxDecoration(
        color: AppColorsLight.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: application.status == 'retained'
              ? AppColorsLight.primary.withOpacity(0.4)
              : AppColorsLight.primary.withOpacity(0.2),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusXl),
                  bottomLeft: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo entreprise
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColorsLight.bgCard,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: UserAvatar(
                            imageUrl: application.companyLogoUrl,
                            radius: 21,
                            defaultIcon: Icons.business_rounded,
                            gradientColors: gradient,
                            iconColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Infos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application.offerTitle,
                                style: AppTypography.headingSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                application.companyName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColorsLight.textPrimary.withOpacity(0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            border: Border.all(color: _statusColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon, size: 12, color: _statusColor),
                              const SizedBox(width: 4),
                              Text(
                                _statusLabel,
                                style: AppTypography.caption.copyWith(
                                  color: _statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: _statusColor.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                application.appliedAt,
                                style: AppTypography.caption.copyWith(
                                  color: _statusColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (score > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(color: scoreColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 12, color: scoreColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${score}%',
                                  style: AppTypography.caption.copyWith(
                                    color: scoreColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
"""

if old_class_compiled.search(content):
    content = old_class_compiled.sub(new_app_card, content)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Applications page updated successfully.")
else:
    print("Could not find _AppCard class using regex.")
