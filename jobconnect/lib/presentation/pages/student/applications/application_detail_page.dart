import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../presentation/widgets/match_score_badge.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/feed/applications_cubit.dart';
import '../../../blocs/feed/applications_state.dart';

class ApplicationDetailPage extends StatefulWidget {
  final String applicationId;
  const ApplicationDetailPage({super.key, required this.applicationId});

  @override
  State<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends State<ApplicationDetailPage> {
  late final ApplicationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ApplicationsCubit>();
    _cubit.loadApplicationDetail(widget.applicationId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _formatOfferType(String type) {
    switch (type) {
      case 'cdi':
        return 'home.filters.cdi'.tr();
      case 'cdd':
        return 'home.filters.cdd'.tr();
      case 'stage_academique':
        return 'home.filters.academic_internship'.tr();
      case 'stage_professionnel':
        return 'home.filters.pro_internship'.tr();
      default:
        return type.toUpperCase();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'retained':
        return AppColorsLight.primary;
      case 'refused':
        return AppColorsLight.textTertiary;
      default:
        return AppColorsLight.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'retained':
        return 'applications.status.retained'.tr();
      case 'refused':
        return 'applications.status.refused'.tr();
      default:
        return 'applications.status.pending'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColorsLight.bgDark,
        body: BlocBuilder<ApplicationsCubit, ApplicationsState>(
          builder: (context, state) {
            final size = MediaQuery.of(context).size;

            return Stack(
              children: [
                // ── En-tête Violet ────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.22,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColorsLight.primary,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    context.go('/student/applications');
                                  }
                                },
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'applications.detail.title'.tr(),
                                style: AppTypography.headingMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Carte Blanche Glassmorphism ──────────────────────
                Positioned.fill(
                  top: size.height * 0.14,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          child: _buildContent(context, state),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ApplicationsState state) {
    if (state is ApplicationDetailLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColorsLight.primary),
      );
    }

    if (state is ApplicationDetailError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColorsLight.error,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.message,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () =>
                    _cubit.loadApplicationDetail(widget.applicationId),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLight.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ApplicationDetailLoaded) {
      final detail = state.detail;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          120, // Espace pour la bottom navigation bar potentielle
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOfferSummary(detail),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    label: 'applications.detail.score'.tr(),
                    color: detail.matchScore >= 75
                        ? AppColorsLight.success
                        : detail.matchScore >= 50
                        ? AppColorsLight.warning
                        : AppColorsLight.error,
                    customValue: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: MatchScoreBadge(score: detail.matchScore),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _InfoCard(
                    label: 'applications.detail.status'.tr(),
                    value: _statusLabel(detail.status),
                    color: _statusColor(detail.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildAiSection(context, detail),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Résumé offre ─────────────────────────────────────────────────────────

  Widget _buildOfferSummary(ApplicationDetail detail) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.bgSurface),
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: detail.companyLogoUrl,
            radius: 28,
            defaultIcon: Icons.business_rounded,
            backgroundColor: AppColorsLight.bgSurface,
            iconColor: AppColorsLight.textTertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.offerTitle, style: AppTypography.headingSmall),
                Text(
                  '${detail.companyName} • ${_formatOfferType(detail.offerType)}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'applications.detail.applied_on'.tr(args: [detail.appliedAt]),
                  style: AppTypography.caption.copyWith(
                    color: AppColorsLight.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section IA selon statut ───────────────────────────────────────────────

  Widget _buildAiSection(BuildContext context, ApplicationDetail detail) {
    if (detail.statusExplanation != null &&
        detail.statusExplanation!.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(detail.statusExplanation!);
        if (decoded is Map<String, dynamic>) {
          return _CustomAiCard(detail: detail, data: decoded);
        } else {
          // JSON valide mais pas une Map
          return _CustomAiCard(
            detail: detail,
            data: {'message': detail.statusExplanation!},
          );
        }
      } catch (e) {
        // Pas du JSON valide : c'est une chaîne de texte brute de l'IA
        return _CustomAiCard(
          detail: detail,
          data: {'message': detail.statusExplanation!},
        );
      }
    }

    switch (detail.status) {
      case 'refused':
        return _RefusedAiCard(detail: detail);
      case 'pending':
        return _PendingAiCard(detail: detail);
      case 'retained':
        return _RetainedAiCard(detail: detail);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String? value;
  final Color color;
  final Widget? customValue;

  const _InfoCard({
    required this.label,
    this.value,
    required this.color,
    this.customValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.bgSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall),
          const SizedBox(height: 4),
          customValue ??
              Text(
                value ?? '',
                style: AppTypography.headingLarge.copyWith(color: color),
              ),
        ],
      ),
    );
  }
}

// ─── Carte refusé — compétences manquantes ────────────────────────────────────

class _RefusedAiCard extends StatelessWidget {
  final ApplicationDetail detail;
  const _RefusedAiCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColorsLight.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'applications.detail.ai_analysis'.tr(),
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'applications.detail.ai_score_text'.tr(
              args: [detail.matchScore.toString()],
            ),
            style: AppTypography.bodyMedium,
          ),
          if (detail.missingSkills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'applications.detail.missing_skills'.tr(),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...detail.missingSkills.map((s) => _GapItem(text: s)),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'applications.detail.tips_title'.tr(),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionItem(number: 1, text: 'applications.detail.tip_1'.tr()),
          _ActionItem(number: 2, text: 'applications.detail.tip_2'.tr()),
          _ActionItem(number: 3, text: 'applications.detail.tip_3'.tr()),
        ],
      ),
    );
  }
}

// ─── Carte en attente — offres similaires ─────────────────────────────────────

class _PendingAiCard extends StatelessWidget {
  final ApplicationDetail detail;
  const _PendingAiCard({required this.detail});

  String _formatOfferType(String type) {
    switch (type) {
      case 'cdi':
        return 'home.filters.cdi'.tr();
      case 'cdd':
        return 'home.filters.cdd'.tr();
      case 'stage_academique':
        return 'home.filters.academic_internship'.tr();
      case 'stage_professionnel':
        return 'home.filters.pro_internship'.tr();
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColorsLight.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'applications.detail.ai_analysis'.tr(),
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            detail.similarOffers.isNotEmpty
                ? 'applications.detail.pending_with_similar'.tr()
                : 'applications.detail.pending_no_similar'.tr(),
            style: AppTypography.bodyMedium,
          ),
          if (detail.similarOffers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...detail.similarOffers.map(
              (offer) =>
                  _SimilarOfferTile(offer: offer, formatType: _formatOfferType),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Carte retenu ─────────────────────────────────────────────────────────────

class _RetainedAiCard extends StatelessWidget {
  final ApplicationDetail detail;
  const _RetainedAiCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: AppColorsLight.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'applications.detail.congrats'.tr(),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColorsLight.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'applications.detail.retained_message'.tr(
              args: [detail.companyName],
            ),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'applications.detail.retained_tip'.tr(),
            style: AppTypography.bodySmall.copyWith(
              color: AppColorsLight.success,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: detail.conversationId != null
                ? () =>
                      context.push('/student/messages/${detail.conversationId}')
                : () => context.go('/student/messages'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsLight.success,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text('applications.detail.go_to_messages'.tr()),
          ),
        ],
      ),
    );
  }
}

class _GapItem extends StatelessWidget {
  final String text;
  const _GapItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.close_rounded,
            size: 16,
            color: AppColorsLight.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final int number;
  final String text;
  const _ActionItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColorsLight.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.caption.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

class _SimilarOfferTile extends StatelessWidget {
  final SimilarOffer offer;
  final String Function(String) formatType;

  const _SimilarOfferTile({required this.offer, required this.formatType});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/student/offer/${offer.offerId}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColorsLight.bgSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColorsLight.bgCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  size: 18,
                  color: AppColorsLight.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${offer.companyName} • ${formatType(offer.offerType)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColorsLight.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColorsLight.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Carte IA sur-mesure (Mastra) ───────────────────────────────────────────

class _CustomAiCard extends StatelessWidget {
  final ApplicationDetail detail;
  final Map<String, dynamic> data;
  const _CustomAiCard({required this.detail, required this.data});

  Color _getColor() {
    switch (detail.status) {
      case 'refused':
        return AppColorsLight.textTertiary;
      case 'retained':
        return AppColorsLight.primary;
      default:
        return AppColorsLight.textSecondary;
    }
  }

  IconData _getIcon() {
    switch (detail.status) {
      case 'refused':
        return Icons.insights_rounded;
      case 'retained':
        return Icons.celebration_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final message = data['message'] as String? ?? '';
    final actions = data['actions'] as List? ?? [];
    final nextStep = data['nextStep'] as String?;
    final similarOffers = data['similarOffers'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: detail.status == 'retained'
            ? color.withOpacity(0.08)
            : AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIcon(), color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                detail.status == 'retained'
                    ? 'applications.detail.congrats'.tr()
                    : 'applications.detail.ai_analysis'.tr(),
                style: AppTypography.headingSmall.copyWith(
                  color: detail.status == 'retained' ? color : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTypography.bodyMedium),

          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'applications.detail.recommended_actions'.tr(),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...actions.asMap().entries.map((entry) {
              final actionData = entry.value;
              String actionText = actionData.toString();
              if (actionData is Map<String, dynamic> &&
                  actionData.containsKey('message')) {
                actionText = actionData['message'].toString();
              }
              return _ActionItem(number: entry.key + 1, text: actionText);
            }),
          ],


          if (nextStep != null &&
              nextStep.isNotEmpty &&
              detail.status != 'pending') ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      nextStep,
                      style: AppTypography.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (detail.status == 'retained') ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: detail.conversationId != null
                  ? () => context.push(
                      '/student/messages/${detail.conversationId}',
                    )
                  : () => context.go('/student/messages'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text('applications.detail.go_to_messages'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}
