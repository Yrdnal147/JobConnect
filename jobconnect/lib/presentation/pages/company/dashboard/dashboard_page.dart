import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/profile/dashboard/dashboard_cubit.dart';
import '../../../blocs/profile/dashboard/dashboard_state.dart';
import '../../../../presentation/widgets/match_score_badge.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<DashboardCubit>();
    _cubit.loadDashboard();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _cubit.refresh();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    final initials = (first + second).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColorsLight.bgDark,
            body: Stack(
              children: [
                // ── En-tête Violet ────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.25,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColorsLight.primary,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            _buildHeader(state),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Carte Blanche Glassmorphism ──────────────────────
                Positioned.fill(
                  top: size.height * 0.16,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          child: RefreshIndicator(
                            color: AppColorsLight.primary,
                            onRefresh: _onRefresh,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xl,
                                AppSpacing.lg,
                                100, // padding bottom
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMetrics(context, state),
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildRecentApplications(context, state),
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildQuickActions(context),
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                              ),
                            ),
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

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(DashboardState state) {
    final companyName = state is DashboardLoaded
        ? state.companyName
        : 'company.dashboard.hello'.tr();
    final unreadMessages = state is DashboardLoaded
        ? state.metrics.unreadMessages
        : 0;
    final companyLogo = state is DashboardLoaded ? state.companyLogo : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            final advancedDrawerController =
                context.read<AdvancedDrawerController?>();
            advancedDrawerController?.showDrawer();
          },
        ),
        Expanded(
          child: Row(
            children: [
              if (state is DashboardLoading)
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColorsLight.textPrimary,
                        AppColorsLight.primary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsLight.primary.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                UserAvatar(
                  imageUrl: companyLogo,
                  radius: 24,
                  defaultIcon: Icons.business_rounded,
                  gradientColors: [
                    AppColorsLight.textPrimary,
                    AppColorsLight.primary,
                  ],
                  iconColor: Colors.white,
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'company.dashboard.hello'.tr(),
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      companyName,
                      style: AppTypography.displayMedium.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
            if (unreadMessages > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColorsLight.accentRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColorsLight.bgCard, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Métriques ────────────────────────────────────────────────────────────

  Widget _buildMetrics(BuildContext context, DashboardState state) {
    final metrics = state is DashboardLoaded
        ? state.metrics
        : const DashboardMetrics();

    final isLoading = state is DashboardLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'company.dashboard.overview'.tr(),
          style: AppTypography.headingSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'company.dashboard.active_offers'.tr(),
                value: isLoading ? '...' : '${metrics.activeOffers}',
                icon: Icons.work_rounded,
                color: AppColorsLight.primary,
                onTap: () => context.push('/company/offers/active'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MetricCard(
                title: 'company.dashboard.applications'.tr(),
                value: isLoading ? '...' : '${metrics.totalApplications}',
                icon: Icons.people_rounded,
                color: AppColorsLight.textTertiaryDark,
                // Redirige vers TOUTES les candidatures, sans filtre offerId
                onTap: () => context.push('/company/candidates/all'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'company.dashboard.retained'.tr(),
                value: isLoading ? '...' : '${metrics.retainedCandidates}',
                icon: Icons.check_circle_rounded,
                color: AppColorsLight.success,
                onTap: () => context.push('/company/candidates/retained'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MetricCard(
                title: 'company.dashboard.messages'.tr(),
                value: isLoading ? '...' : '${metrics.unreadMessages}',
                icon: Icons.chat_bubble_rounded,
                color: AppColorsLight.textTertiaryDark,
                onTap: () => context.push('/company/messages'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Candidatures récentes ────────────────────────────────────────────────

  Widget _buildRecentApplications(BuildContext context, DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'company.dashboard.recent_applications'.tr(),
              style: AppTypography.headingSmall,
            ),
            TextButton(
              // Redirige vers TOUTES les candidatures, sans filtre offerId
              onPressed: () => context.push('/company/candidates/all'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'company.dashboard.see_all'.tr(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColorsLight.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColorsLight.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (state is DashboardLoading) _buildLoadingList(),
        if (state is DashboardError) _buildErrorState(state.message),

        if (state is DashboardLoaded) ...[
          if (state.recentApplications.isEmpty)
            _buildEmptyApplications()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.recentApplications.length,
              itemBuilder: (context, index) {
                final app = state.recentApplications[index];
                return _buildApplicationCard(context, app, index);
              },
            ),
        ],
      ],
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    RecentApplication app,
    int index,
  ) {
    final avatarGradients = <List<Color>>[
      [AppColorsLight.primary, AppColorsLight.secondary],
      [AppColorsLight.textPrimary, AppColorsLight.success],
      [AppColorsLight.secondary, AppColorsLight.accentRed],
      [AppColorsLight.accentRed, AppColorsLight.primary],
      [AppColorsLight.success, AppColorsLight.secondary],
      [AppColorsLight.warning, AppColorsLight.accentRed],
    ];
    final gradient = avatarGradients[index % avatarGradients.length];

    Color scoreColor;
    if (app.matchScore >= 75) {
      scoreColor = AppColorsLight.success;
    } else if (app.matchScore >= 50) {
      scoreColor = AppColorsLight.warning;
    } else {
      scoreColor = AppColorsLight.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.bgSurface),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/company/candidates/${app.applicationId}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // ── Avatar — vraie photo si disponible, sinon initiales ──
                UserAvatar(
                  imageUrl: app.photoUrl,
                  radius: 27.5,
                  defaultIcon: Icons.person_rounded,
                ),
                const SizedBox(width: AppSpacing.md),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.studentName,
                        style: AppTypography.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.educationLevel.isNotEmpty
                            ? '${app.fieldOfStudy} • ${app.educationLevel}'
                            : app.fieldOfStudy,
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

                MatchScoreBadge(score: app.matchScore),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Actions rapides ──────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'company.dashboard.quick_actions'.tr(),
          style: AppTypography.headingSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColorsLight.textPrimary, AppColorsLight.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColorsLight.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/company/offers/create'),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'company.dashboard.publish_offer'.tr(),
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── États auxiliaires ────────────────────────────────────────────────────

  Widget _buildLoadingList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        height: 75,
        decoration: BoxDecoration(
          color: AppColorsLight.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColorsLight.bgSurface),
        ),
      ),
    );
  }

  Widget _buildEmptyApplications() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.bgSurface),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 40,
              color: AppColorsLight.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'company.dashboard.empty_applications'.tr(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsLight.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.push('/company/offers/create'),
              child: Text(
                'company.dashboard.publish_first_offer'.tr(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColorsLight.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColorsLight.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'company.dashboard.error_loading'.tr(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsLight.error,
              ),
            ),
          ),
          TextButton(
            onPressed: _cubit.refresh,
            child: Text(
              'company.dashboard.retry'.tr(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsLight.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget MetricCard ────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.bgSurface),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  value,
                  style: AppTypography.displayMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColorsLight.textPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
