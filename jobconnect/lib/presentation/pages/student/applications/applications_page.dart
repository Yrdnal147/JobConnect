import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/feed/applications_cubit.dart';
import '../../../blocs/feed/applications_state.dart';
import '../../../../presentation/widgets/match_score_badge.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  late final ApplicationsCubit _cubit;

  static const _gradients = [
    [Color(0xFF0052CC), Color(0xFF00D9FF)],
    [Color(0xFF00D9FF), Color(0xFFFF6B6B)],
    [Color(0xFFFF6B6B), Color(0xFF0052CC)],
  ];

  final _filters = ['Tous', 'En attente', 'Retenu', 'Refusé'];

  @override
  void initState() {
    super.initState();
    _cubit = sl<ApplicationsCubit>();
    _cubit.loadApplications();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _formatOfferType(String type) {
    switch (type) {
      case 'cdi':                 return 'home.filters.cdi'.tr();
      case 'cdd':                 return 'home.filters.cdd'.tr();
      case 'stage_academique':    return 'home.filters.academic_internship'.tr();
      case 'stage_professionnel': return 'home.filters.pro_internship'.tr();
      default:                    return type.toUpperCase();
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Tous': return 'applications.status.all'.tr();
      case 'En attente': return 'applications.status.pending'.tr();
      case 'Retenu': return 'applications.status.retained'.tr();
      case 'Refusé': return 'applications.status.refused'.tr();
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ApplicationsCubit, ApplicationsState>(
        builder: (context, state) {
          final size = MediaQuery.of(context).size;

          final counts = state is ApplicationsLoaded
              ? {
                  'retained': state.countByStatus('retained'),
                  'pending': state.countByStatus('pending'),
                  'refused': state.countByStatus('refused'),
                  'total': state.filteredApplications.length,
                }
              : {'retained': 0, 'pending': 0, 'refused': 0, 'total': 0};

          final activeFilter = state is ApplicationsLoaded
              ? state.activeFilter
              : 'Tous';

          return Scaffold(
            backgroundColor: AppColorsLight.bgDark,
            body: Stack(
              children: [
                // ── En-tête Violet ────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.28,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColorsLight.primary, Color(0xFF4A148C)],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'applications.title'.tr(),
                              style: AppTypography.displayMedium
                                  .copyWith(color: Colors.white, fontSize: 26),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                _HeaderStat(
                                  label: 'applications.status.retained_plural'.tr(),
                                  value: '${counts['retained']}',
                                  icon: Icons.check_circle_rounded,
                                  color: Colors.greenAccent,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _HeaderStat(
                                  label: 'applications.status.pending'.tr(),
                                  value: '${counts['pending']}',
                                  icon: Icons.hourglass_top_rounded,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _HeaderStat(
                                  label: 'applications.status.refused_plural'.tr(),
                                  value: '${counts['refused']}',
                                  icon: Icons.cancel_rounded,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Carte Blanche Glassmorphism ──────────────────────
                Positioned.fill(
                  top: size.height * 0.22,
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
                          child: Column(
                            children: [
                              // ── Filtres ──────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.sm),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _filters.map((f) {
                                      final isSelected = activeFilter == f;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            right: AppSpacing.sm),
                                        child: GestureDetector(
                                          onTap: () =>
                                              _cubit.filterByStatus(f),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal:
                                                        AppSpacing.md,
                                                    vertical:
                                                        AppSpacing.sm),
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? LinearGradient(
                                                      colors: [
                                                          AppColorsLight
                                                              .textPrimary,
                                                          AppColorsLight
                                                              .primary,
                                                        ])
                                                  : null,
                                              color: isSelected
                                                  ? null
                                                  : AppColorsLight.bgCard,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppSpacing
                                                          .radiusFull),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.transparent
                                                    : AppColorsLight
                                                        .bgSurface,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColorsLight
                                                            .primary
                                                            .withOpacity(
                                                                0.22),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(
                                                                0, 3),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Text(
                                              _translateStatus(f),
                                              style: AppTypography
                                                  .labelSmall
                                                  .copyWith(
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColorsLight
                                                        .textSecondary,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                              // ── Liste ────────────────────────────
                              Expanded(
                                  child: _buildBody(context, state)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Corps principal ──────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ApplicationsState state) {
    if (state is ApplicationsLoading) return _buildLoadingList();
    if (state is ApplicationsError) return _buildErrorState(state.message);

    if (state is ApplicationsLoaded) {
      final filtered = state.filteredApplications;

      if (filtered.isEmpty) return _buildEmptyState();

      return RefreshIndicator(
        color: AppColorsLight.primary,
        onRefresh: _cubit.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            120,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final app = filtered[index];
            final gradient = _gradients[index % _gradients.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push(
                      '/student/applications/${app.applicationId}'),
                  child: _AppCard(
                    application: app,
                    gradient: gradient,
                    formatType: _formatOfferType,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── États auxiliaires ────────────────────────────────────────────────────

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        height: 88,
        decoration: BoxDecoration(
          color: AppColorsLight.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColorsLight.bgSurface),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColorsLight.textTertiary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.work_off_rounded,
                size: 32, color: AppColorsLight.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('applications.empty.title'.tr(),
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('applications.empty.subtitle'.tr(),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColorsLight.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColorsLight.textTertiary, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('applications.error.title'.tr(),
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _cubit.loadApplications,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('home.offers.retry'.tr()),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLight.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini stat badge ──────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String value;
  final Color color;
  const _MiniStat({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Header stat (violet) ─────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Card candidature ─────────────────────────────────────────────────────────

class _AppCard extends StatelessWidget {
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
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColorsLight.textTertiary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: application.status == 'retained'
              ? AppColorsLight.primary.withOpacity(0.4)
              : AppColorsLight.textTertiary.withOpacity(0.1),
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
                        const SizedBox(width: AppSpacing.sm),
                        if (score > 0)
                          MatchScoreBadge(score: score),
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
