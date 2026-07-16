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

class RetainedCandidatesPage extends StatefulWidget {
  const RetainedCandidatesPage({super.key});

  @override
  State<RetainedCandidatesPage> createState() =>
      _RetainedCandidatesPageState();
}

class _RetainedCandidatesPageState extends State<RetainedCandidatesPage> {
  late final AllCandidatesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AllCandidatesCubit>();
    // Charge et filtre directement sur 'retained'
    _cubit.loadCandidates().then((_) {
      _cubit.filterByStatus('retained');
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second =
        parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AllCandidatesCubit, AllCandidatesState>(
        builder: (context, state) {
          final size = MediaQuery.of(context).size;

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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColorsLight.primary, Color(0xFF4A148C)],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                                      onPressed: () {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        } else {
                                          context.go('/company/dashboard');
                                        }
                                      },
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(
                                      'company.candidates.retained_title'.tr(),
                                      style: AppTypography.displayMedium.copyWith(color: Colors.white, fontSize: 26),
                                    ),
                                  ],
                                ),
                                if (state is AllCandidatesLoaded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                    ),
                                    child: Text(
                                      '${state.filteredCandidates.length}',
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.lg),
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

  // ─── Corps ────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, AllCandidatesState state) {
    if (state is AllCandidatesLoading) {
      return _buildLoadingList();
    }

    if (state is AllCandidatesError) {
      return _buildErrorState(state.message);
    }

    if (state is AllCandidatesLoaded) {
      final candidates = state.filteredCandidates;

      if (candidates.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        color: AppColorsLight.primary,
        onRefresh: () => _cubit.refresh().then((_) {
          _cubit.filterByStatus('retained');
        }),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: candidates.length,
          itemBuilder: (context, index) {
            return _buildCandidateCard(context, candidates[index]);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Carte candidat retenu ────────────────────────────────────────────────

  Widget _buildCandidateCard(
      BuildContext context, CandidateItem candidate) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColorsLight.success.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorsLight.success.withOpacity(0.05),
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
          onTap: () => context
              .push('/company/candidates/${candidate.applicationId}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Avatar avec badge vert
                Stack(
                  children: [
                    UserAvatar(
                      imageUrl: candidate.photoUrl,
                      radius: 26,
                      defaultIcon: Icons.person_rounded,
                      backgroundColor: AppColorsLight.primary.withOpacity(0.15),
                      iconColor: AppColorsLight.primary,
                    ),
                    // Badge check vert
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColorsLight.success,
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 11,
                            color: AppColorsLight.success,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Retenu',
                            style: AppTypography.caption.copyWith(
                              color: AppColorsLight.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        height: 88,
        decoration: BoxDecoration(
          color: AppColorsLight.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
              color: AppColorsLight.success.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              'Aucun candidat retenu pour l\'instant',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColorsLight.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Consultez les candidatures et retenez les profils qui vous intéressent.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsLight.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => context.go('/company/candidates/all'),
              child: Text(
                'Voir toutes les candidatures',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColorsLight.textTertiary, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Impossible de charger les candidats retenus',
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
              onPressed: () => _cubit.loadCandidates().then((_) {
                _cubit.filterByStatus('retained');
              }),
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