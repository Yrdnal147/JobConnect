import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../blocs/profile/offers/offers_cubit.dart';
import '../../../blocs/profile/offers/offers_state.dart';

class MyOffersPage extends StatefulWidget {
  const MyOffersPage({super.key});

  @override
  State<MyOffersPage> createState() => _MyOffersPageState();
}

class _MyOffersPageState extends State<MyOffersPage> {
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

  String _formatOfferType(String type) {
    switch (type.toLowerCase()) {
      case 'cdi':
        return 'home.filters.cdi'.tr();
      case 'cdd':
        return 'home.filters.cdd'.tr();
      case 'stage_academique':
        return 'home.filters.academic_internship'.tr();
      case 'stage_professionnel':
        return 'home.filters.pro_internship'.tr();
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<OffersCubit, OffersState>(
        builder: (context, state) {
          final activeCount = state is OffersLoaded
              ? state.activeCount
              : 0;

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('company.offers.my_offers'.tr(),
                                          style: AppTypography.displayMedium.copyWith(color: Colors.white)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'company.offers.manage_desc'.tr(),
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                // Badge nombre d'offres actives
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        activeCount > 1 ? 'company.offers.active_plural'.tr(args: [activeCount.toString()]) : 'company.offers.active_single'.tr(args: [activeCount.toString()]),
                                        style: AppTypography.labelSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
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
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColorsLight.textPrimary,
                                        AppColorsLight.primary,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColorsLight.primary.withValues(alpha: 0.3),
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
                                            const Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Text(
                                              'company.offers.publish_offer'.tr(),
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
                              ),
                              // ── Liste des offres ──────────────────────────────────
                              Expanded(
                                child: _buildOffersList(context, state),
                              ),
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

  // ─── Liste offres ─────────────────────────────────────────────────────────

  Widget _buildOffersList(BuildContext context, OffersState state) {
    if (state is OffersLoading) {
      return _buildLoadingList();
    }

    if (state is OffersError) {
      return _buildErrorState(state.message);
    }

    if (state is OffersLoaded || state is OfferToggling) {
      final offers = state is OffersLoaded
          ? state.offers
          : (state as OfferToggling).offers;

      final togglingId = state is OfferToggling
          ? state.togglingOfferId
          : null;

      if (offers.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        color: AppColorsLight.primary,
        onRefresh: _cubit.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            final isToggling = togglingId == offer.offerId;
            return Padding(
  padding: const EdgeInsets.only(bottom: AppSpacing.md),
  child: GestureDetector(
    onTap: () => context.push('/company/offers/${offer.offerId}'),
    child: _OfferManagementCard(
      offer: offer,
      isToggling: isToggling,
      formatType: _formatOfferType,
      onToggle: (value) =>
          _cubit.toggleOfferStatus(offer.offerId, value),
      onViewCandidates: () =>
          context.push('/company/offers/${offer.offerId}'),
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
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        height: 120,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColorsLight.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline_rounded,
              size: 32,
              color: AppColorsLight.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('company.offers.empty_title'.tr(),
              style: AppTypography.headingSmall),
          const SizedBox(height: 4),
          Text(
            'company.offers.empty_subtitle'.tr(),
            style: AppTypography.bodySmall.copyWith(
              color: AppColorsLight.textPrimary.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () =>
                context.push('/company/offers/create'),
            child: Text(
              'company.offers.publish_first'.tr(),
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
            Text('company.offers.error_loading'.tr(),
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _cubit.loadOffers,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('company.offers.retry'.tr()),
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

// ─── Widget carte offre ───────────────────────────────────────────────────────

class _OfferManagementCard extends StatelessWidget {
  final OfferItem offer;
  final bool isToggling;
  final String Function(String) formatType;
  final void Function(bool) onToggle;
  final VoidCallback onViewCandidates;

  const _OfferManagementCard({
    required this.offer,
    required this.isToggling,
    required this.formatType,
    required this.onToggle,
    required this.onViewCandidates,
  });

  IconData get _typeIcon {
    final type = offer.offerType.toLowerCase();
    if (type.contains('stage')) return Icons.school_rounded;
    if (type.contains('cdd')) return Icons.event_note_rounded;
    return Icons.work_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.bgSurface),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barre colorée gauche
            Container(
              width: 4,
              color: offer.isActive
                  ? AppColorsLight.primary
                  : AppColorsLight.textTertiary,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            offer.title,
                            style: AppTypography.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Switch actif/inactif
                        isToggling
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColorsLight.primary,
                                  strokeWidth: 2,
                                ),
                              )
                            : Switch(
                                value: offer.isActive,
                                activeColor: AppColorsLight.primary,
                                onChanged: onToggle,
                              ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorsLight.primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_typeIcon,
                                  size: 11,
                                  color: AppColorsLight.primary),
                              const SizedBox(width: 3),
                              Text(
                                formatType(offer.offerType),
                                style: AppTypography.caption.copyWith(
                                  color: AppColorsLight.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColorsLight.textTertiary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'company.offers.published_at'.tr(args: [offer.postedAt]),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                        height: 1,
                        color: AppColorsLight.bgSurface),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColorsLight.secondary
                                    .withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.people_outline_rounded,
                                size: 14,
                                color: AppColorsLight.secondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              offer.applicationsCount > 1 ? 'company.offers.application_plural'.tr(args: [offer.applicationsCount.toString()]) : 'company.offers.application_single'.tr(args: [offer.applicationsCount.toString()]),
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: onViewCandidates,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'company.offers.view_candidates'.tr(),
                                style: AppTypography.bodySmall
                                    .copyWith(
                                  color: AppColorsLight.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: AppColorsLight.primary,
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