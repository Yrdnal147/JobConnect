import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../blocs/profile/offers/offers_cubit.dart';
import '../../../blocs/profile/offers/offers_state.dart';

class ActiveOffersPage extends StatefulWidget {
  const ActiveOffersPage({super.key});

  @override
  State<ActiveOffersPage> createState() => _ActiveOffersPageState();
}

class _ActiveOffersPageState extends State<ActiveOffersPage> {
  late final OffersCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<OffersCubit>();
    _cubit.loadOffers();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _formatOfferType(String type, int? durationMonths) {
    switch (type) {
      case 'cdi':
        return 'CDI';
      case 'cdd':
        return 'CDD';
      case 'stage_academique':
        return durationMonths != null
            ? 'Stage académique • $durationMonths mois'
            : 'Stage académique';
      case 'stage_professionnel':
        return durationMonths != null
            ? 'Stage pro • $durationMonths mois'
            : 'Stage professionnel';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<OffersCubit, OffersState>(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.arrow_back_ios_rounded,
                                        color: Colors.white,
                                      ),
                                      onPressed: () =>
                                          context.go('/company/dashboard'),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(
                                      'Offres actives',
                                      style: AppTypography.displayMedium
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: 26,
                                          ),
                                    ),
                                  ],
                                ),
                                if (state is OffersLoaded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull,
                                      ),
                                    ),
                                    child: Text(
                                      '${state.activeCount}',
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
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push('/company/offers/create'),
              backgroundColor: AppColorsLight.primary,
              icon: const Icon(Icons.add_rounded, color: AppColorsLight.bgDark),
              label: const Text(
                'Nouvelle offre',
                style: TextStyle(color: AppColorsLight.bgDark),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Corps ────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, OffersState state) {
    if (state is OffersLoading) {
      return _buildLoadingList();
    }

    if (state is OffersError) {
      return _buildErrorState(state.message);
    }

    if (state is OffersLoaded) {
      final activeOffers = state.activeOffers;

      if (activeOffers.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        color: AppColorsLight.primary,
        onRefresh: _cubit.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: activeOffers.length,
          itemBuilder: (context, index) {
            return _buildOfferCard(context, activeOffers[index]);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Carte offre active ───────────────────────────────────────────────────

  Widget _buildOfferCard(BuildContext context, OfferItem offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColorsLight.primary.withOpacity(0.05),
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
          onTap: () => context.push('/company/candidates/all'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icône offre
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: AppColorsLight.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: AppTypography.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatOfferType(offer.offerType, offer.durationMonths),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColorsLight.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColorsLight.textTertiary,
                          ),
                          const SizedBox(width: 2),
                          Text(offer.location, style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ),
                ),

                // Candidats + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsLight.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${offer.applicationsCount} candidat${offer.applicationsCount > 1 ? 's' : ''}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColorsLight.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(offer.postedAt, style: AppTypography.caption),
                  ],
                ),
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
          border: Border.all(color: AppColorsLight.primary.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_outline_rounded,
              size: 64,
              color: AppColorsLight.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucune offre active pour l\'instant',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColorsLight.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => context.push('/company/offers/create'),
              child: Text(
                'Publier votre première offre',
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
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColorsLight.textTertiary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Impossible de charger les offres',
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
              onPressed: _cubit.loadOffers,
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
