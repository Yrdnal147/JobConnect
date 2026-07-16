import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/feed/success_cubit.dart';
import '../../../blocs/feed/success_state.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  late final SuccessCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<SuccessCubit>();
    _cubit.loadConnections();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showInspireDialog(
      BuildContext context, SuccessConnection connection) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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

            // Titre
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
                      'success.dialog.skills_title'.tr(),
                      style: AppTypography.caption.copyWith(
                        color: AppColorsLight.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'success.dialog.position_title'.tr(args: [connection.position]),
                      style: AppTypography.headingSmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Compétences
            connection.studentSkills.isEmpty
                ? Text(
                    'success.dialog.no_skills'.tr(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColorsLight.textTertiary,
                    ),
                  )
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: connection.studentSkills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsLight.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                          border: Border.all(
                            color:
                                AppColorsLight.primary.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          skill,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColorsLight.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: AppSpacing.lg),

            // Bouton ajouter ces compétences
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                gradient: LinearGradient(colors: [
                  AppColorsLight.primary,
                  AppColorsLight.secondary,
                ]),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/student/profile');
                  },
                  child: Center(
                    child: Text(
                      'success.dialog.add_skills'.tr(),
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SuccessCubit, SuccessState>(
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
                              onPressed: () => context.go('/student/profile'),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'success.title'.tr(),
                                  style: AppTypography.headingMedium.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                            if (state is SuccessLoaded)
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.md, top: 8.0),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusFull),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      state.connections.length > 1
                                          ? 'success.connections_count_plural'.tr(args: [state.connections.length.toString()])
                                          : 'success.connections_count_single'.tr(args: [state.connections.length.toString()]),
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
                          child: SafeArea(
                            top: false,
                            child: _buildBody(context, state),
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

  Widget _buildBody(BuildContext context, SuccessState state) {
    if (state is SuccessLoading) {
      return _buildLoadingList();
    }

    if (state is SuccessError) {
      return _buildErrorState(state.message);
    }

    if (state is SuccessLoaded) {
      if (state.connections.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        color: AppColorsLight.primary,
        onRefresh: _cubit.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: state.connections.length,
          itemBuilder: (context, index) {
            return _SuccessCard(
              connection: state.connections[index],
              onInspire: () => _showInspireDialog(
                  context, state.connections[index]),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        height: 160,
        decoration: BoxDecoration(
          color: AppColorsLight.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColorsLight.bgSurface),
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
              Icons.emoji_events_rounded,
              size: 64,
              color: AppColorsLight.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'success.empty.title'.tr(),
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'success.empty.subtitle'.tr(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsLight.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => context.push('/student/home'),
              child: Text(
                'success.empty.action'.tr(),
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
            Text('success.error.title'.tr(),
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _cubit.loadConnections,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('common.retry'.tr()),
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

// ─── Card connexion ───────────────────────────────────────────────────────────

class _SuccessCard extends StatelessWidget {
  final SuccessConnection connection;
  final VoidCallback onInspire;

  const _SuccessCard({
    required this.connection,
    required this.onInspire,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
          // ── Avatars ───────────────────────────────────────────────────
          Row(
            children: [
              // Photo étudiant
              _Avatar(
                photoUrl: connection.studentPhotoUrl,
                name: connection.studentName,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColorsLight.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColorsLight.success,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Logo entreprise
              _CompanyAvatar(
                logoUrl: connection.companyLogoUrl,
                name: connection.companyName,
                size: 48,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Infos ─────────────────────────────────────────────────────
          Text(
            'success.card.joined'.tr(args: [connection.studentName, connection.companyName]),
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColorsLight.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  connection.position,
                  style: AppTypography.caption.copyWith(
                    color: AppColorsLight.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Footer ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 13,
                      color: AppColorsLight.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    connection.confirmedAt,
                    style: AppTypography.caption,
                  ),
                ],
              ),
              TextButton(
                onPressed: onInspire,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppColorsLight.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'success.card.inspire'.tr(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsLight.primary,
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
    );
  }
}

// ─── Avatar étudiant ──────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  const _Avatar({
    this.photoUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      imageUrl: photoUrl,
      radius: size / 2,
      defaultIcon: Icons.person_rounded,
      backgroundColor: AppColorsLight.primary.withOpacity(0.15),
      iconColor: AppColorsLight.primary,
    );
  }
}

// ─── Avatar entreprise ────────────────────────────────────────────────────────

class _CompanyAvatar extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final double size;

  const _CompanyAvatar({
    this.logoUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      imageUrl: logoUrl,
      radius: size / 2,
      defaultIcon: Icons.business_rounded,
      backgroundColor: AppColorsLight.bgSurface,
      iconColor: AppColorsLight.textTertiary,
    );
  }
}