import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/profile/all_candidates/all_candidates_cubit.dart';
import '../../../blocs/profile/all_candidates/all_candidates_state.dart';
import '../../../../presentation/widgets/match_score_badge.dart';

class AllCandidatesPage extends StatefulWidget {
  const AllCandidatesPage({super.key});

  @override
  State<AllCandidatesPage> createState() => _AllCandidatesPageState();
}

class _AllCandidatesPageState extends State<AllCandidatesPage> {
  late final AllCandidatesCubit _cubit;
  String? _offerId;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AllCandidatesCubit>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupère l'offerId depuis les query parameters GoRouter
    final newOfferId = GoRouterState.of(context).uri.queryParameters['offerId'];
    if (newOfferId != _offerId) {
      _offerId = newOfferId;
      _cubit.loadCandidates(offerId: _offerId);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // ─── Helpers visuels ─────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'retained':
        return AppColorsLight.success;
      case 'refused':
        return AppColorsLight.error;
      default:
        return AppColorsLight.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'retained':
        return 'Retenu';
      case 'refused':
        return 'Refusé';
      default:
        return 'En attente';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'retained':
        return Icons.check_circle_rounded;
      case 'refused':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColorsLight.success;
    if (score >= 50) return AppColorsLight.warning;
    return AppColorsLight.error;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AllCandidatesCubit, AllCandidatesState>(
        builder: (context, state) {
          // Titre selon contexte filtré ou global
          final title = _offerId != null
              ? 'Candidatures de l\'offre'
              : 'Toutes les candidatures';

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    context.go('/company/dashboard');
                                  }
                                },
                              ),
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTypography.headingMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (state is AllCandidatesLoaded)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.md,
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusFull,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '${state.filteredCandidates.length} candidat${state.filteredCandidates.length > 1 ? 's' : ''}',
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
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
                          child: Column(
                            children: [
                              const SizedBox(height: AppSpacing.md),
                              if (state is AllCandidatesLoaded)
                                _buildFilters(state.filterStatus),
                              Expanded(child: _buildBody(context, state)),
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

  // ─── Filtres ──────────────────────────────────────────────────────────────

  Widget _buildFilters(String currentFilter) {
    final filters = [
      {'key': 'all', 'label': 'Tous'},
      {'key': 'pending', 'label': 'En attente'},
      {'key': 'retained', 'label': 'Retenus'},
      {'key': 'refused', 'label': 'Refusés'},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isActive = currentFilter == filter['key'];

          return GestureDetector(
            onTap: () => _cubit.filterByStatus(filter['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColorsLight.primary
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isActive
                      ? AppColorsLight.primary
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Text(
                filter['label']!,
                style: AppTypography.labelSmall.copyWith(
                  color: isActive ? Colors.white : AppColorsLight.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Corps principal ──────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, AllCandidatesState state) {
    if (state is AllCandidatesLoading) return _buildLoadingList();
    if (state is AllCandidatesError) return _buildErrorState(state.message);

    if (state is AllCandidatesLoaded) {
      final candidates = state.filteredCandidates;
      if (candidates.isEmpty) return _buildEmptyState(state.filterStatus);

      return RefreshIndicator(
        color: AppColorsLight.primary,
        onRefresh: _cubit.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: candidates.length,
          itemBuilder: (context, index) =>
              _buildCandidateCard(context, candidates[index]),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Carte candidat ───────────────────────────────────────────────────────

  Widget _buildCandidateCard(BuildContext context, CandidateItem candidate) {
    final scoreColor = _scoreColor(candidate.matchScore);
    final statusColor = _statusColor(candidate.status);

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
          onTap: () =>
              context.push('/company/candidates/${candidate.applicationId}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Avatar
                UserAvatar(
                  imageUrl: candidate.photoUrl,
                  radius: 26,
                  defaultIcon: Icons.person_rounded,
                  backgroundColor: AppColorsLight.primary.withOpacity(0.15),
                  iconColor: AppColorsLight.primary,
                ),
                const SizedBox(width: AppSpacing.md),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.studentName,
                        style: AppTypography.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        candidate.offerTitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColorsLight.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(candidate.status),
                              size: 10,
                              color: statusColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _statusLabel(candidate.status),
                              style: AppTypography.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                MatchScoreBadge(score: candidate.matchScore),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── États auxiliaires ────────────────────────────────────────────────────

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
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

  Widget _buildEmptyState(String filterStatus) {
    final message = filterStatus == 'all'
        ? 'Aucune candidature reçue pour l\'instant'
        : 'Aucun candidat ${_statusLabel(filterStatus).toLowerCase()} pour l\'instant';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppColorsLight.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColorsLight.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            if (filterStatus == 'all')
              TextButton(
                onPressed: () => context.push('/company/offers/create'),
                child: Text(
                  'Publier une offre pour recevoir des candidatures',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColorsLight.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
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
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColorsLight.textTertiary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Impossible de charger les candidatures',
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _cubit.loadCandidates(offerId: _offerId),
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
}
