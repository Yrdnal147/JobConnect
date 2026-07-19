import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class MatchScoreBadge extends StatelessWidget {
  final int score;
  final bool showLabel;
  final bool onDarkBackground;

  const MatchScoreBadge({
    super.key,
    required this.score,
    this.showLabel = false,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    if (score <= 0) return const SizedBox.shrink();

    final scoreColor = onDarkBackground
        ? Colors.white
        : (score >= 75
              ? AppColorsLight.success
              : score >= 50
              ? AppColorsLight.warning
              : AppColorsLight.error);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(onDarkBackground ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: scoreColor.withOpacity(onDarkBackground ? 0.4 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: showLabel ? 14 : 11,
            color: scoreColor,
          ),
          const SizedBox(width: 4),
          Text(
            showLabel ? '$score% de match' : '$score%',
            style: AppTypography.labelSmall.copyWith(
              color: scoreColor,
              fontWeight: FontWeight.w700,
              fontSize: showLabel ? null : 11,
            ),
          ),
        ],
      ),
    );
  }
}
