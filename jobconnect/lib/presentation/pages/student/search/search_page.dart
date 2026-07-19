import 'dart:ui';
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
import '../../../blocs/search/search_cubit.dart';
import '../../../blocs/search/search_state.dart';
import '../../../../presentation/widgets/match_score_badge.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchCubit _cubit;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  final List<String> _filters = [
    'Tous',
    'CDI',
    'CDD',
    'Stage académique',
    'Stage pro',
  ];

  final List<IconData> _filterIcons = [
    Icons.apps_rounded,
    Icons.work_rounded,
    Icons.event_note_rounded,
    Icons.school_rounded,
    Icons.business_center_rounded,
  ];

  final List<Map<String, dynamic>> _trending = const [
    {'label': 'Flutter', 'icon': Icons.phone_android_rounded},
    {'label': 'Data Science', 'icon': Icons.bar_chart_rounded},
    {'label': 'Marketing', 'icon': Icons.campaign_rounded},
    {'label': 'DevOps', 'icon': Icons.cloud_rounded},
    {'label': 'UI/UX', 'icon': Icons.design_services_rounded},
    {'label': 'Finance', 'icon': Icons.account_balance_rounded},
  ];

  static const _avatarGradients = [
    [Color(0xFF0052CC), Color(0xFF00D9FF)],
    [Color(0xFF00D9FF), Color(0xFFFF6B6B)],
    [Color(0xFFFF6B6B), Color(0xFF0052CC)],
    [Color(0xFF0052CC), Color(0xFFFF6B6B)],
    [Color(0xFF00D9FF), Color(0xFF0052CC)],
  ];

  @override
  void initState() {
    super.initState();
    _cubit = sl<SearchCubit>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _cubit.onQueryChanged(value);
  }

  void _onTapSuggestion(String text) {
    _searchController.text = text;
    setState(() {});
    _cubit.search(text);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    _cubit.onQueryChanged('');
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

  String _translateFilter(String filter) {
    switch (filter) {
      case 'Tous':
        return 'home.filters.all'.tr();
      case 'CDI':
        return 'home.filters.cdi'.tr();
      case 'CDD':
        return 'home.filters.cdd'.tr();
      case 'Stage académique':
        return 'home.filters.academic_internship'.tr();
      case 'Stage pro':
        return 'home.filters.pro_internship'.tr();
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.isNotEmpty;
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColorsLight.bgDark,
            body: Stack(
              children: [
                // 1. En-tête Violet avec la barre de recherche
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.30,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'search.title'.tr(),
                                        style: AppTypography.displayMedium.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'search.subtitle'.tr(),
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // ── Barre de recherche ────────────────
                            Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                                horizontal: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: AppSpacing.md),
                                  Icon(
                                    Icons.search_rounded,
                                    color: hasQuery
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                    size: 22,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _focusNode,
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: Colors.white,
                                      ),
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        hintText: 'search.search_hint'.tr(),
                                        hintStyle: AppTypography.bodyLarge
                                            .copyWith(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                      ),
                                      onChanged: _onChanged,
                                      onSubmitted: (v) => _cubit.search(v),
                                    ),
                                  ),
                                  if (hasQuery)
                                    IconButton(
                                      icon: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: _clearSearch,
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

                // 2. Carte Glassmorphism Flottante
                Positioned.fill(
                  top: size.height * 0.27,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
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
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.lg),
                              // Filtres s'affichent uniquement s'il y a des résultats
                              if (state is SearchLoaded)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppSpacing.lg,
                                    bottom: AppSpacing.md,
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: List.generate(_filters.length, (
                                        i,
                                      ) {
                                        final filter = _filters[i];
                                        final icon = _filterIcons[i];
                                        final isSelected =
                                            state.activeFilter == filter;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: AppSpacing.sm,
                                          ),
                                          child: GestureDetector(
                                            onTap: () =>
                                                _cubit.filterByType(filter),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.md,
                                                    vertical: AppSpacing.sm,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: isSelected
                                                    ? LinearGradient(
                                                        colors: [
                                                          AppColorsLight
                                                              .primary,
                                                          AppColorsLight
                                                              .secondary,
                                                        ],
                                                      )
                                                    : null,
                                                color: isSelected
                                                    ? null
                                                    : AppColorsLight.bgCard,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppSpacing.radiusFull,
                                                    ),
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
                                                                0.25,
                                                              ),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
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
                                                    color: isSelected
                                                        ? Colors.white
                                                        : AppColorsLight
                                                              .textSecondary,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    _translateFilter(filter),
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
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),

                              // Contenu (Empty, Loading, Error, Results)
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

  // ─── Routing par état ───────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, SearchState state) {
    if (state is SearchInitial) return _buildEmptyState(state.recentSearches);
    if (state is SearchLoading) return _buildLoadingList();
    if (state is SearchError) return _buildErrorState(state.message);

    if (state is SearchLoaded) {
      final results = state.filteredResults;
      if (results.isEmpty) return _buildNoResults(state.query);
      return _buildResults(context, state.query, results);
    }

    return const SizedBox.shrink();
  }

  // ─── État vide : récents + trending ─────────────────────────────────────────

  Widget _buildEmptyState(List<String> recentSearches) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppColorsLight.textPrimary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'search.recent_searches'.tr(),
                      style: AppTypography.headingSmall,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _cubit.clearRecentSearches,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'search.clear'.tr(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColorsLight.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...recentSearches.map(
              (search) => Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: () => _onTapSuggestion(search),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColorsLight.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColorsLight.bgSurface),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: AppColorsLight.textTertiary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(search, style: AppTypography.bodyMedium),
                        ),
                        Icon(
                          Icons.north_west_rounded,
                          size: 16,
                          color: AppColorsLight.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(height: 1, color: AppColorsLight.bgSurface),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Tendances
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: AppColorsLight.bgDark.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text('search.trending'.tr(), style: AppTypography.headingSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _trending.map((item) {
              return GestureDetector(
                onTap: () => _onTapSuggestion(item['label'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgCard,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: AppColorsLight.bgSurface),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 14,
                        color: AppColorsLight.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item['label'] as String,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColorsLight.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ─── Chargement ──────────────────────────────────────────────────────────────

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
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

  // ─── Aucun résultat ──────────────────────────────────────────────────────────

  Widget _buildNoResults(String query) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: AppColorsLight.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'search.no_results_title'.tr(),
                      style: AppTypography.headingSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'search.no_results_subtitle'.tr(args: [query]),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsLight.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Erreur ──────────────────────────────────────────────────────────────────

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
              'search.error_title'.tr(),
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
              onPressed: () => _cubit.search(_searchController.text),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('home.offers.retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsLight.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Résultats ───────────────────────────────────────────────────────────────

  Widget _buildResults(
    BuildContext context,
    String query,
    List<SearchOfferItem> results,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text(
                results.length > 1
                    ? 'search.results_count_plural'.tr(
                        args: [results.length.toString()],
                      )
                    : 'search.results_count_single'.tr(
                        args: [results.length.toString()],
                      ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColorsLight.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'search.for_query'.tr(args: [query]),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColorsLight.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              120,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final offer = results[index];
              final gradient =
                  _avatarGradients[index % _avatarGradients.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        context.push('/student/offer/${offer.offerId}'),
                    child: _SearchOfferCard(
                      offer: offer,
                      formatType: _formatOfferType,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchOfferCard extends StatelessWidget {
  final SearchOfferItem offer;
  final String Function(String) formatType;

  const _SearchOfferCard({required this.offer, required this.formatType});

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
    final isHighMatch = offer.matchScore >= 75;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isHighMatch
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${offer.companyName} • ${offer.location}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsLight.textPrimary.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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
              const Spacer(),
              if (offer.matchScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: scoreColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: scoreColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.matchScore}%',
                        style: AppTypography.caption.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
