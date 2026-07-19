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
import '../../../blocs/feed/feed_cubit.dart';
import '../../../blocs/feed/feed_state.dart';
import '../../../blocs/notifications/notification_cubit.dart';
import '../../../blocs/notifications/notification_state.dart';
import '../../../../presentation/widgets/match_score_badge.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FeedCubit _cubit;
  late final NotificationCubit _notificationCubit;

  final List<String> _filters = ['Tous', 'CDI', 'CDD', 'Stage'];

  final List<IconData> _filterIcons = [
    Icons.apps_rounded,
    Icons.work_rounded,
    Icons.event_note_rounded,
    Icons.school_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _cubit = sl<FeedCubit>();
    _cubit.loadFeed();
    _notificationCubit = sl<NotificationCubit>();
    _notificationCubit.loadNotifications();
  }

  @override
  void dispose() {
    _cubit.close();
    _notificationCubit.close();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (a + b).toUpperCase();
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
        return type.toUpperCase();
    }
  }

  String _translateFilter(String filter) {
    switch (filter) {
      case 'Tous':
        return 'home.filters.all'.tr();
      case 'CDI':
        return 'home.filters.cdi'.tr();
      case 'CDD':
        return 'home.filters.cdd'.tr();
      case 'Stage':
        return 'home.filters.internship'.tr();
      default:
        return filter;
    }
  }

  // ─── Avatar ───────────────────────────────────────────────────────────────

  Widget _buildAvatar(String userName, String? photoUrl, bool isLoading) {
    if (isLoading) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColorsLight.primary, AppColorsLight.secondary],
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return UserAvatar(
      imageUrl: photoUrl,
      radius: 23,
      defaultIcon: Icons.person_rounded,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _notificationCubit),
      ],
      child: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          final userName = state is FeedLoaded
              ? state.userName
              : 'home.candidate'.tr();
          final photoUrl = state is FeedLoaded ? state.photoUrl : null;
          final hasProfile = state is FeedLoaded ? state.hasProfile : false;
          final profileScore = state is FeedLoaded ? state.profileScore : 0;
          final activeFilter = state is FeedLoaded
              ? state.activeFilter
              : 'Tous';
          final isLoading = state is FeedLoading;

          final size = MediaQuery.of(context).size;

          return Scaffold(
            backgroundColor: AppColorsLight.bgDark,
            body: Stack(
              children: [
                // En-tête Violet
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.28,
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
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Menu Button
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
                                // Logo Text
                                Text(
                                  "JobConnect",
                                  style: AppTypography.headingMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                // Actions
                                Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                        right: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColorsLight.success,
                                        ),
                                        onPressed: () =>
                                            context.push('/student/success'),
                                        tooltip: 'profile.tooltip_success'.tr(),
                                      ),
                                    ),
                                    // Notifications
                                BlocBuilder<
                                  NotificationCubit,
                                  NotificationState
                                >(
                                  builder: (context, notifState) {
                                    int unreadCount = 0;
                                    if (notifState is NotificationLoaded) {
                                      unreadCount = notifState.unreadCount;
                                    }
                                    return Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.notifications_outlined,
                                              color: Colors.white,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(
                                                  context,
                                                  rootNavigator: true,
                                                ).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BlocProvider.value(
                                                          value:
                                                              _notificationCubit,
                                                          child:
                                                              const NotificationsPage(),
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColorsLight.primary,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Text(
                                                unreadCount > 9
                                                    ? '9+'
                                                    : unreadCount.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                _buildAvatar(userName, photoUrl, isLoading),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'home.greeting'.tr(),
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      Text(
                                        userName,
                                        style: AppTypography.displayMedium
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 24,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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

                // Carte Blanche Globale (Contenu Scrollable)
                Positioned.fill(
                  top: size.height * 0.22, // Chevauchement
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
                          child: RefreshIndicator(
                            color: AppColorsLight.primary,
                            onRefresh: _cubit.refresh,
                            child: CustomScrollView(
                              slivers: [
                                // Contenu statique de la carte blanche
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ── Banner profil ─────────────────────────
                                        if (!hasProfile)
                                          _buildIncompleteBanner()
                                        else
                                          _buildProfileScoreBanner(
                                            profileScore,
                                          ),
                                        const SizedBox(height: AppSpacing.lg),

                                        // ── Titre + filtres ───────────────────────
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              hasProfile
                                                  ? 'home.offers.for_you'.tr()
                                                  : 'home.offers.recent'.tr(),
                                              style: AppTypography.headingSmall,
                                            ),
                                            GestureDetector(
                                              onTap: () => context.push(
                                                '/student/search',
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'home.offers.see_all'.tr(),
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                          color: AppColorsLight
                                                              .primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  const Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    size: 11,
                                                    color:
                                                        AppColorsLight.primary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),

                                        // Filtres
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: List.generate(
                                              _filters.length,
                                              (i) {
                                                final filter = _filters[i];
                                                final icon = _filterIcons[i];
                                                final isSelected =
                                                    activeFilter == filter;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: AppSpacing.sm,
                                                      ),
                                                  child: GestureDetector(
                                                    onTap: () => _cubit
                                                        .filterOffers(filter),
                                                    child: _FilterChip(
                                                      label: _translateFilter(
                                                        filter,
                                                      ),
                                                      icon: icon,
                                                      isSelected: isSelected,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Liste d'offres ────────────────────────────────
                                if (state is FeedLoading)
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (_, __) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.sm,
                                        ),
                                        child: Container(
                                          height: 110,
                                          decoration: BoxDecoration(
                                            color: AppColorsLight.bgCard,
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusLg,
                                            ),
                                            border: Border.all(
                                              color: AppColorsLight.bgSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                      childCount: 5,
                                    ),
                                  )
                                else if (state is FeedError)
                                  SliverToBoxAdapter(
                                    child: _buildErrorState(state.message),
                                  )
                                else if (state is FeedLoaded) ...[
                                  if (state.filteredOffers.isEmpty)
                                    SliverToBoxAdapter(
                                      child: _buildEmptyState(
                                        state.activeFilter,
                                      ),
                                    )
                                  else
                                    SliverPadding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.xl * 3,
                                      ), // Espace pour la bottom nav
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            final offer =
                                                state.filteredOffers[index];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.lg,
                                                    vertical: AppSpacing.sm,
                                                  ),
                                              child: Material(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppSpacing.radiusLg,
                                                    ),
                                                clipBehavior: Clip.antiAlias,
                                                child: InkWell(
                                                  onTap: () => context.push(
                                                    '/student/offer/${offer.offerId}',
                                                  ),
                                                  child: _OfferCard(
                                                    offer: offer,
                                                    hasProfile: hasProfile,
                                                    formatType:
                                                        _formatOfferType,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          childCount:
                                              state.filteredOffers.length,
                                        ),
                                      ),
                                    ),
                                ],
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
          );
        },
      ),
    );
  }

  // ─── Banner profil incomplet ──────────────────────────────────────────────

  Widget _buildIncompleteBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsLight.primary.withOpacity(0.1),
            AppColorsLight.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.primary.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/student/profile'),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColorsLight.primary, AppColorsLight.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.complete_profile.title'.tr(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColorsLight.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'home.complete_profile.subtitle'.tr(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsLight.primary.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColorsLight.primary,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Banner profil complet avec score

  Widget _buildProfileScoreBanner(int score) {
    final scoreColor = score >= 75
        ? AppColorsLight.success
        : score >= 50
        ? AppColorsLight.warning
        : AppColorsLight.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: scoreColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '$score',
                style: AppTypography.headingSmall.copyWith(
                  color: scoreColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.profile_score.title'.tr(),
                  style: AppTypography.labelSmall.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  score >= 75
                      ? 'home.profile_score.excellent'.tr()
                      : 'home.profile_score.improve'.tr(),
                  style: AppTypography.bodySmall.copyWith(
                    color: scoreColor.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/student/profile'),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: scoreColor,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── États auxiliaires

  Widget _buildEmptyState(String filter) {
    return Padding(
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
            filter == 'Tous'
                ? 'home.offers.empty_all'.tr()
                : 'home.offers.empty_filter'.tr(args: [filter]),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColorsLight.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
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
            'home.offers.error_loading'.tr(),
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
            onPressed: _cubit.loadFeed,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('home.offers.retry'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsLight.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [AppColorsLight.textPrimary, AppColorsLight.primary],
              )
            : null,
        color: isSelected ? null : AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isSelected ? Colors.transparent : AppColorsLight.bgSurface,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColorsLight.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isSelected ? Colors.white : AppColorsLight.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColorsLight.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Offer card ───────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final FeedOffer offer;
  final bool hasProfile;
  final String Function(String) formatType;

  const _OfferCard({
    required this.offer,
    required this.hasProfile,
    required this.formatType,
  });

  static const _avatarGradients = [
    [Color(0xFF0052CC), Color(0xFF00D9FF)],
    [Color(0xFF00D9FF), Color(0xFFFF6B6B)],
    [Color(0xFFFF6B6B), Color(0xFF0052CC)],
    [Color(0xFF0052CC), Color(0xFFFF6B6B)],
    [Color(0xFF00D9FF), Color(0xFF0052CC)],
  ];

  @override
  Widget build(BuildContext context) {
    final scoreColor = offer.matchScore >= 75
        ? AppColorsLight.success
        : offer.matchScore >= 50
        ? AppColorsLight.warning
        : AppColorsLight.error;

    final gradientIndex = offer.offerId.hashCode % _avatarGradients.length;
    final gradient = _avatarGradients[gradientIndex.abs()];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: offer.isHighMatch
              ? AppColorsLight.success.withOpacity(0.4)
              : AppColorsLight.primary.withOpacity(0.2),
        ),
      ),
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
                  imageUrl: offer.companyLogo,
                  radius: 21,
                  defaultIcon: Icons.business_rounded,
                  gradientColors: gradient,
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: AppTypography.headingSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.companyName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsLight.textPrimary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Score badge
              if (hasProfile && offer.matchScore > 0)
                MatchScoreBadge(score: offer.matchScore),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: AppColorsLight.bgSurface),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColorsLight.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  formatType(offer.offerType),
                  style: AppTypography.caption.copyWith(
                    color: AppColorsLight.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColorsLight.textTertiary,
              ),
              const SizedBox(width: 2),
              Text(
                offer.location,
                style: AppTypography.caption.copyWith(
                  color: AppColorsLight.textTertiary,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.schedule_rounded,
                size: 12,
                color: AppColorsLight.textTertiary,
              ),
              const SizedBox(width: 3),
              Text(
                offer.postedAt,
                style: AppTypography.caption.copyWith(
                  color: AppColorsLight.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
