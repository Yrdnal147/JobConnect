import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../blocs/feed/offer_detail_student_cubit.dart';
import '../../../blocs/feed/offer_detail_student_state.dart';
import '../../../../presentation/widgets/match_score_badge.dart';
import 'package:easy_localization/easy_localization.dart';

class OfferDetailPage extends StatefulWidget {
  final String? offerId;
  const OfferDetailPage({super.key, this.offerId});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late final OfferDetailStudentCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<OfferDetailStudentCubit>();
    if (widget.offerId != null) {
      _cubit.loadOffer(widget.offerId!);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _formatOfferType(String type) {
    switch (type.toLowerCase()) {
      case 'cdi':                 return 'home.filters.cdi'.tr();
      case 'cdd':                 return 'home.filters.cdd'.tr();
      case 'stage_academique':    return 'home.filters.academic_internship'.tr();
      case 'stage_professionnel': return 'home.filters.pro_internship'.tr();
      default:                    return type.toUpperCase();
    }
  }

  StudentOfferDetail? _extractOffer(OfferDetailStudentState state) {
    if (state is OfferDetailStudentLoaded)   return state.offer;
    if (state is OfferDetailStudentApplying) return state.offer;
    if (state is OfferDetailStudentApplied)  return state.offer;
    if (state is OfferDetailStudentError)    return state.lastKnownOffer;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<OfferDetailStudentCubit, OfferDetailStudentState>(
        listener: (context, state) {
          if (state is OfferDetailStudentApplied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('offer_detail.applied_success'.tr()),
                backgroundColor: AppColorsLight.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
          }
          if (state is OfferDetailStudentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColorsLight.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading   = state is OfferDetailStudentLoading;
          final isApplying  = state is OfferDetailStudentApplying;
          final offer       = _extractOffer(state);
          final isSaved     = state is OfferDetailStudentLoaded
              ? state.isSaved
              : false;

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
                  height: size.height * 0.22,
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
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.go('/student/home');
                                }
                              },
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'offer_detail.title'.tr(),
                                  style: AppTypography.headingMedium.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                            // Bouton sauvegarder
                            if (offer != null)
                              GestureDetector(
                                onTap: _cubit.toggleSave,
                                child: Container(
                                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: isSaved
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSaved
                                          ? Colors.white.withOpacity(0.4)
                                          : Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_outline_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: _cubit.toggleSave,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
                          child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: AppColorsLight.primary))
                            : offer == null
                                ? _buildErrorState(context)
                                : SafeArea(
                                    top: false,
                                    child: CustomScrollView(
                                      slivers: [
                                        SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // ── Hero bannière + logo ────────────
                                  Container(
                                    margin: const EdgeInsets.all(AppSpacing.lg),
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: AppColorsLight.bgCard,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
                                                  begin:
                                                      Alignment.topLeft,
                                                  end:
                                                      Alignment.bottomRight,
                                                  colors: [
                                                    AppColorsLight.textPrimary,
                                                    AppColorsLight.primary,
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Logo entreprise
                                           // Logo entreprise cliquable
                            Positioned(
                         left: AppSpacing.lg,
                                  bottom: -28,
                        child: GestureDetector(
                                 onTap: () => context.push('/student/company/${offer.companyId}'),
    child: Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: UserAvatar(
        imageUrl: offer.companyLogo,
        radius: 28,
        defaultIcon: Icons.business_rounded,
        gradientColors: const [AppColorsLight.primary, AppColorsLight.secondary],
        iconColor: Colors.white,
      ),
    ),
  ),
),
                                            // Score match
                                            if (offer.matchScore > 0)
                                              Positioned(
                                                right: AppSpacing.md,
                                                top: AppSpacing.md,
                                                child: MatchScoreBadge(
                                                  score: offer.matchScore,
                                                  onDarkBackground: true,
                                                ),
                                              ),
                                          ],
                                        ),

                                        // Infos poste
                                        Padding(
                                          padding:
                                              const EdgeInsets.fromLTRB(
                                            AppSpacing.lg,
                                            36,
                                            AppSpacing.lg,
                                            AppSpacing.lg,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                offer.title,
                                                style: AppTypography
                                                    .headingMedium,
                                              ),
                                              const SizedBox(height: 6),
                                              GestureDetector(
  onTap: () => context.push('/student/company/${offer.companyId}'),
  child: Row(
    children: [
      Text(
        offer.companyName,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColorsLight.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (offer.isCompanyVerified) ...[
        const SizedBox(width: 4),
        const Icon(
          Icons.verified_rounded,
          size: 14,
          color: AppColorsLight.primary,
        ),
      ],
      const SizedBox(width: 4),
      Text(
        '· ${offer.location}',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColorsLight.textTertiary,
        ),
      ),
    ],
  ),
),
                                              const SizedBox(
                                                  height: AppSpacing.md),
                                              // Pills infos
                                              Wrap(
                                                spacing: AppSpacing.sm,
                                                runSpacing: AppSpacing.sm,
                                                children: [
                                                  _InfoPill(
                                                    icon: Icons.work_rounded,
                                                    label: _formatOfferType(
                                                        offer.offerType),
                                                    color:
                                                        AppColorsLight.primary,
                                                  ),
                                                  _InfoPill(
                                                    icon: Icons
                                                        .location_on_outlined,
                                                    label: offer.location,
                                                    color: AppColorsLight
                                                        .secondary,
                                                  ),
                                                  if (offer.salaryRange !=
                                                      null)
                                                    _InfoPill(
                                                      icon: Icons
                                                          .payments_outlined,
                                                      label:
                                                          offer.salaryRange!,
                                                      color: AppColorsLight
                                                          .success,
                                                    ),
                                                  if (offer.durationMonths !=
                                                      null)
                                                    _InfoPill(
                                                      icon: Icons
                                                          .calendar_month_rounded,
                                                      label:
                                                          '${offer.durationMonths} mois',
                                                      color: AppColorsLight
                                                          .warning,
                                                    ),
                                                  _InfoPill(
                                                    icon:
                                                        Icons.schedule_rounded,
                                                    label:
                                                        'offer_detail.published'.tr(args: [offer.postedAt]),
                                                    color: AppColorsLight
                                                        .textTertiary,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ── Description ────────────────
                                        _SectionCard(
                                          title: 'offer_detail.description'.tr(),
                                          icon: Icons.description_outlined,
                                          child: Text(
                                            offer.description.isEmpty
                                                ? 'offer_detail.no_description'.tr()
                                                : offer.description,
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                              height: 1.6,
                                              color: AppColorsLight.textPrimary
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.md),

                                        // ── Compétences ────────────────
                                        if (offer.requiredSkills
                                            .isNotEmpty)
                                          _SectionCard(
                                            title: 'offer_detail.required_skills'.tr(),
                                            icon: Icons.bolt_rounded,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (offer.matchingSkills
                                                        .isNotEmpty ||
                                                    offer.missingSkills
                                                        .isNotEmpty) ...[
                                                  Row(
                                                    children: [
                                                      _LegendDot(
                                                          color: AppColorsLight
                                                              .success),
                                                      const SizedBox(
                                                          width: 4),
                                                      Text(
                                                        'offer_detail.mastered'.tr(),
                                                        style: AppTypography
                                                            .caption
                                                            .copyWith(
                                                          color: AppColorsLight
                                                              .textTertiary,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width:
                                                              AppSpacing.md),
                                                      _LegendDot(
                                                          color: AppColorsLight
                                                              .error),
                                                      const SizedBox(
                                                          width: 4),
                                                      Text(
                                                        'offer_detail.to_acquire'.tr(),
                                                        style: AppTypography
                                                            .caption
                                                            .copyWith(
                                                          color: AppColorsLight
                                                              .textTertiary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                      height: AppSpacing.sm),
                                                ],
                                                Wrap(
                                                  spacing: AppSpacing.sm,
                                                  runSpacing: AppSpacing.sm,
                                                  children: [
                                                    ...offer.matchingSkills
                                                        .map((skill) =>
                                                            _SkillTag(
                                                              label: skill,
                                                              isMatching: true,
                                                            )),
                                                    ...offer.missingSkills
                                                        .map((skill) =>
                                                            _SkillTag(
                                                              label: skill,
                                                              isMatching:
                                                                  false,
                                                            )),
                                                    // Skills sans comparaison
                                                    if (offer.matchingSkills
                                                            .isEmpty &&
                                                        offer.missingSkills
                                                            .isEmpty)
                                                      ...offer.requiredSkills
                                                          .map((skill) =>
                                                              _SkillTag(
                                                                label: skill,
                                                                isMatching:
                                                                    false,
                                                              )),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(
                                            height: AppSpacing.md),

                                        // ── Niveau éducation ───────────
                                        if (offer.minEducation.isNotEmpty)
                                          _SectionCard(
                                            title: 'offer_detail.education'.tr(),
                                            icon: Icons.school_outlined,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColorsLight
                                                        .secondary
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppSpacing
                                                                .radiusMd),
                                                  ),
                                                  child: Icon(
                                                    Icons.school_rounded,
                                                    size: 20,
                                                    color: AppColorsLight
                                                        .secondary,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    width: AppSpacing.md),
                                                Text(
                                                  'offer_detail.minimum'.tr(args: [offer.minEducation.toUpperCase()]),
                                                  style: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(
                                            height: AppSpacing.md),

                                        // ── Expérience ─────────────────
                                        _SectionCard(
                                          title: 'offer_detail.experience'.tr(),
                                          icon: Icons.timeline_rounded,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: AppColorsLight.warning
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppSpacing.radiusMd),
                                                ),
                                                child: Icon(
                                                  Icons.timeline_rounded,
                                                  size: 20,
                                                  color: AppColorsLight.warning,
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.md),
                                              Text(
                                                offer.yearsOfExperience == 0
                                                    ? 'offer_detail.no_experience'.tr()
                                                    : offer.yearsOfExperience > 1
                                                        ? 'offer_detail.years_experience_plural'.tr(args: [offer.yearsOfExperience.toString()])
                                                        : 'offer_detail.years_experience_single'.tr(args: [offer.yearsOfExperience.toString()]),
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.xl),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── Bouton postuler sticky ────────────────────────────────
            bottomNavigationBar: offer == null
                ? null
                : Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColorsLight.bgDark,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: offer.hasAlreadyApplied
                          // ── Déjà postulé ─────────────────────────────
                          ? Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color:
                                    AppColorsLight.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                border: Border.all(
                                  color: AppColorsLight.success
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColorsLight.success,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'offer_detail.applied_success'.tr(),
                                      style: AppTypography.labelLarge
                                          .copyWith(
                                        color: AppColorsLight.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          // ── Bouton postuler ───────────────────────────
                          : Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                gradient: isApplying
                                    ? LinearGradient(colors: [
                                        AppColorsLight.primary
                                            .withOpacity(0.5),
                                        AppColorsLight.secondary
                                            .withOpacity(0.5),
                                      ])
                                    : LinearGradient(colors: [
                                        AppColorsLight.textPrimary,
                                        AppColorsLight.primary,
                                      ]),
                                boxShadow: isApplying
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: AppColorsLight.primary
                                              .withOpacity(0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: isApplying
                                      ? null
                                      : _handleApply,
                                  child: Center(
                                    child: isApplying
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.sm),
                                              Text(
                                                'offer_detail.apply'.tr(),
                                                style: AppTypography
                                                    .labelLarge
                                                    .copyWith(
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
                  ),
          );
        },
      ),
    );
  }

  // ─── Handle apply avec coach suggestion ──────────────────────────────────

  void _handleApply() {
    final current = _cubit.state;
    if (current is! OfferDetailStudentLoaded) return;

    final offer = current.offer;

    // Si compétences manquantes → afficher le coach avant de postuler
    if (offer.missingSkills.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (bottomSheetContext) {
          // On déclenche le chargement des conseils IA à l'ouverture du sheet
          _cubit.fetchCoachingAdvice();
          return BlocProvider.value(
            value: _cubit,
            child: _CoachSuggestionSheet(
              missingSkills: offer.missingSkills,
              onApplyAnyway: () {
                Navigator.pop(bottomSheetContext);
                _cubit.applyToOffer();
              },
              onUpdateProfile: () {
                Navigator.pop(bottomSheetContext);
                context.push('/student/profile');
              },
            ),
          );
        },
      );
      
    } else {
      // Pas de compétences manquantes → postuler directement
      _cubit.applyToOffer();
    }
  }

  // ─── Error state ─────────────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColorsLight.textTertiary, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('offer_detail.not_found'.tr(),
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.offerId != null) {
                  _cubit.loadOffer(widget.offerId!);
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text('offer_detail.retry'.tr()),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;
  final bool isMatching;
  const _SkillTag({required this.label, required this.isMatching});

  @override
  Widget build(BuildContext context) {
    final color =
        isMatching ? AppColorsLight.success : AppColorsLight.error;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMatching ? Icons.check_rounded : Icons.close_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Coach suggestion sheet ───────────────────────────────────────────────────

class _CoachSuggestionSheet extends StatelessWidget {
  final List<String> missingSkills;
  final VoidCallback onApplyAnyway;
  final VoidCallback onUpdateProfile;

  const _CoachSuggestionSheet({
    required this.missingSkills,
    required this.onApplyAnyway,
    required this.onUpdateProfile,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfferDetailStudentCubit, OfferDetailStudentState>(
      builder: (context, state) {
        if (state is! OfferDetailStudentLoaded) {
          return const SizedBox.shrink();
        }

        final isLoading = state.isCoachingLoading;
        final coachResult = state.coachResult;
        final coachError = state.coachError;

        return Container(
          decoration: BoxDecoration(
            color: AppColorsLight.bgCard,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Titre IA
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColorsLight.primary,
                        AppColorsLight.secondary,
                      ]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'offer_detail.ai_assistant'.tr(),
                        style: AppTypography.caption.copyWith(
                          color: AppColorsLight.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'offer_detail.advice_before_apply'.tr(),
                        style: AppTypography.headingSmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'offer_detail.ai_analyzing'.tr(),
                          style: AppTypography.bodyMedium.copyWith(color: AppColorsLight.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (coachError != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsLight.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    coachError,
                    style: AppTypography.bodyMedium.copyWith(color: AppColorsLight.error),
                  ),
                )
              else if (coachResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgDark,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    coachResult['globalMessage'] ?? 'offer_detail.suggestions'.tr(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColorsLight.textPrimary.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (coachResult['suggestions'] != null)
                  ...(coachResult['suggestions'] as List).map((sugg) => Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColorsLight.warning.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColorsLight.warning.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColorsLight.warning.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: AppColorsLight.warning,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'offer_detail.suggested_action'.tr(args: [sugg['skill']]),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColorsLight.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sugg['action'] ?? '',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
              ],

              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColorsLight.bgSurface),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Center(
                            child: Text(
                              'offer_detail.cancel'.tr(),
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        gradient: LinearGradient(colors: [
                          AppColorsLight.textPrimary,
                          AppColorsLight.primary,
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color: AppColorsLight.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onApplyAnyway,
                          child: Center(
                            child: Text(
                              'offer_detail.apply_anyway'.tr(),
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
       }
      