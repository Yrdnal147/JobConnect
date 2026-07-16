import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/feed/company_detail_cubit.dart';
import '../../../blocs/feed/company_detail_state.dart';

class CompanyDetailPage extends StatefulWidget {
  final String? companyId;
  const CompanyDetailPage({super.key, this.companyId});

  @override
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  late final CompanyDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<CompanyDetailCubit>();
    if (widget.companyId != null) {
      _cubit.loadCompany(widget.companyId!);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _formatOfferType(String type) {
    switch (type) {
      case 'cdi':                 return 'CDI';
      case 'cdd':                 return 'CDD';
      case 'stage_academique':    return 'Stage académique';
      case 'stage_professionnel': return 'Stage pro';
      default:                    return type.toUpperCase();
    }
  }

  String _formatSize(String size) {
    switch (size) {
      case '1-10':   return '1–10 employés';
      case '11-50':  return '11–50 employés';
      case '51-200': return '51–200 employés';
      case '200+':   return '200+ employés';
      default:       return size;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<CompanyDetailCubit, CompanyDetailState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColorsLight.bgDark,
            body: SafeArea(
              child: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  // ─── Corps ────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, CompanyDetailState state) {
    if (state is CompanyDetailLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColorsLight.primary),
      );
    }

    if (state is CompanyDetailError) {
      return _buildErrorState(context, state.message);
    }

    if (state is CompanyDetailLoaded) {
      return _buildContent(context, state.company);
    }

    return const SizedBox.shrink();
  }

  // ─── Contenu principal ────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, CompanyDetailData company) {
    return CustomScrollView(
      slivers: [
        // ── AppBar ────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColorsLight.bgDark,
          elevation: 0,
          shape: Border(
              bottom: BorderSide(color: AppColorsLight.bgSurface)),
          leading: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: AppColorsLight.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColorsLight.bgSurface),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    size: 18, color: AppColorsLight.textPrimary),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/student/home');
                  }
                },
              ),
            ),
          ),
          title: Text('Profil entreprise',
              style: AppTypography.headingMedium),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero bannière + logo ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgCard,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: AppColorsLight.bgSurface),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsLight.primary.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Bannière gradient
                          Container(
                            height: 90,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColorsLight.textPrimary,
                                  AppColorsLight.primary,
                                ],
                              ),
                            ),
                          ),
                          // Logo overlap
                          Positioned(
                            left: AppSpacing.lg,
                            bottom: -30,
                            child: Container(
                              width: 68,
                              height: 68,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColorsLight.bgCard,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: UserAvatar(
                                imageUrl: company.logoUrl,
                                radius: 30,
                                defaultIcon: Icons.business_rounded,
                                backgroundColor: AppColorsLight.primary.withOpacity(0.12),
                                iconColor: AppColorsLight.primary,
                              ),
                            ),
                          ),
                          // Stats bannière
                          Positioned(
                            right: AppSpacing.md,
                            top: AppSpacing.md,
                            child: Row(
                              children: [
                                if (company.size.isNotEmpty)
                                  _BannerStat(
                                    value: company.size,
                                    label: 'Employés',
                                  ),
                                const SizedBox(width: AppSpacing.sm),
                                _BannerStat(
                                  value:
                                      '${company.activeOffersCount}',
                                  label: 'Offres',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Infos entreprise
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          38,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(company.name,
                                style: AppTypography.headingMedium),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.category_outlined,
                                    size: 13,
                                    color: AppColorsLight.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  [
                                    if (company.sector.isNotEmpty)
                                      company.sector,
                                    if (company.size.isNotEmpty)
                                      _formatSize(company.size),
                                  ].join(' • '),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColorsLight.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Badge vérifié
                            if (company.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorsLight.success
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull),
                                  border: Border.all(
                                    color: AppColorsLight.success
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        size: 12,
                                        color: AppColorsLight.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Vérifiée',
                                      style: AppTypography.caption
                                          .copyWith(
                                        color: AppColorsLight.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorsLight.textTertiary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull),
                                  border: Border.all(
                                    color: AppColorsLight.textTertiary
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Non vérifiée',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColorsLight.textTertiary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Corps ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // À propos
                    if (company.description.isNotEmpty)
                      _SectionCard(
                        title: 'À propos',
                        icon: Icons.info_outline_rounded,
                        child: Text(
                          company.description,
                          style: AppTypography.bodyMedium.copyWith(
                            height: 1.6,
                            color: AppColorsLight.textPrimary
                                .withOpacity(0.8),
                          ),
                        ),
                      ),
                    if (company.description.isNotEmpty)
                      const SizedBox(height: AppSpacing.md),

                    // Direction
                    if (company.ceoName.isNotEmpty)
                      _SectionCard(
                        title: 'Direction',
                        icon: Icons.badge_outlined,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColorsLight.primary,
                                    AppColorsLight.secondary,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.ceoName,
                                  style: AppTypography.labelLarge
                                      .copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Directeur Général',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColorsLight.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (company.ceoName.isNotEmpty)
                      const SizedBox(height: AppSpacing.md),

                    // Localisation
                    _SectionCard(
                      title: 'Localisation',
                      icon: Icons.location_on_outlined,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColorsLight.bgDark,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                          border: Border.all(
                              color: AppColorsLight.bgSurface),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColorsLight.primary
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.map_rounded,
                                      size: 24,
                                      color: AppColorsLight.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: AppSpacing.sm,
                              left: AppSpacing.sm,
                              right: AppSpacing.sm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorsLight.bgCard,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  border: Border.all(
                                      color: AppColorsLight.bgSurface),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColorsLight.primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        size: 15,
                                        color: AppColorsLight.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        company.location,
                                        style: AppTypography.bodySmall
                                            .copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Offres actives
                    if (company.activeOffers.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.work_outline_rounded,
                                  size: 16,
                                  color: AppColorsLight.primary),
                              const SizedBox(width: 6),
                              Text('Offres actives',
                                  style: AppTypography.headingSmall),
                            ],
                          ),
                          Text(
                            '${company.activeOffers.length} offre${company.activeOffers.length > 1 ? 's' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColorsLight.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: company.activeOffers.length,
                          itemBuilder: (context, index) {
                            final offer = company.activeOffers[index];
                            final gradients = [
                              [AppColorsLight.primary,
                                  AppColorsLight.secondary],
                              [AppColorsLight.secondary,
                                  AppColorsLight.primary],
                              [AppColorsLight.primary,
                                  AppColorsLight.accentRed],
                            ];
                            final g = gradients[
                                index % gradients.length];

                            return GestureDetector(
                              onTap: () => context.push(
                                  '/student/offer/${offer.offerId}'),
                              child: Container(
                                width: 190,
                                margin: const EdgeInsets.only(
                                    right: AppSpacing.sm),
                                padding: const EdgeInsets.all(
                                    AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColorsLight.bgCard,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusLg),
                                  border: Border.all(
                                      color: AppColorsLight.bgSurface),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                colors: g),
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          child: const Icon(
                                            Icons.work_rounded,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColorsLight.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppSpacing.radiusFull),
                                          ),
                                          child: Text(
                                            _formatOfferType(
                                                offer.offerType),
                                            style: AppTypography.caption
                                                .copyWith(
                                              color:
                                                  AppColorsLight.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                        height: AppSpacing.sm),
                                    Text(
                                      offer.title,
                                      style: AppTypography.labelLarge
                                          .copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 11,
                                          color:
                                              AppColorsLight.textTertiary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          offer.location,
                                          style: AppTypography.caption
                                              .copyWith(
                                            color: AppColorsLight
                                                .textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_outlined,
                color: AppColorsLight.textTertiary, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('Entreprise introuvable',
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.companyId != null) {
                  _cubit.loadCompany(widget.companyId!);
                }
              },
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

// ─── Composants ───────────────────────────────────────────────────────────────

class _BannerStat extends StatelessWidget {
  final String value;
  final String label;
  const _BannerStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColorsLight.primary),
              const SizedBox(width: 6),
              Text(title, style: AppTypography.headingSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}