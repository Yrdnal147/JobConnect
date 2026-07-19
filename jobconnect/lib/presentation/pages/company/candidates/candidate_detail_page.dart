import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../presentation/widgets/match_score_badge.dart';
import '../../../../injection_container.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../../blocs/profile/all_candidates/candidate_detail_cubit.dart';
import '../../../blocs/profile/all_candidates/candidate_detail_state.dart';

class CandidateDetailPage extends StatefulWidget {
  final String applicationId;
  const CandidateDetailPage({super.key, required this.applicationId});

  @override
  State<CandidateDetailPage> createState() => _CandidateDetailPageState();
}

class _CandidateDetailPageState extends State<CandidateDetailPage> {
  late final CandidateDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<CandidateDetailCubit>();
    _cubit.loadCandidate(widget.applicationId);
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
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? AppColorsLight.error
            : AppColorsLight.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  Future<void> _openCv(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Impossible d\'ouvrir le CV', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<CandidateDetailCubit, CandidateDetailState>(
        listener: (context, state) {
          if (state is CandidateRetained) {
            _showSnack('Candidat retenu');
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) {
                context.push('/company/messages/${state.conversationId}');
              }
            });
          } else if (state is CandidateRefused) {
            _showSnack('Candidature refusée');
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) Navigator.of(context).pop();
            });
          } else if (state is CandidateDetailError) {
            _showSnack(state.message, isError: true);
          }
        },
        builder: (context, state) {
          String? status;
          if (state is CandidateDetailLoaded) status = state.candidate.status;
          if (state is CandidateDetailActing) status = state.candidate.status;
          if (state is CandidateRetained) status = 'retained';
          if (state is CandidateRefused) status = 'refused';

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
                                      onPressed: () {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        } else {
                                          context.go('/company/candidates');
                                        }
                                      },
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(
                                      'Profil candidat',
                                      style: AppTypography.displayMedium
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: 26,
                                          ),
                                    ),
                                  ],
                                ),
                                if (status != null)
                                  _StatusBadge(status: status),
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

  Widget _buildBody(BuildContext context, CandidateDetailState state) {
    if (state is CandidateDetailLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColorsLight.primary),
      );
    }

    if (state is CandidateDetailError && state.lastKnown == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColorsLight.error,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.message,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => _cubit.loadCandidate(widget.applicationId),
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

    CandidateDetailData? candidate;
    bool isActing = false;
    String actingAction = '';

    if (state is CandidateDetailLoaded) {
      candidate = state.candidate;
    } else if (state is CandidateDetailActing) {
      candidate = state.candidate;
      isActing = true;
      actingAction = state.action;
    } else if (state is CandidateRetained) {
      candidate = state.candidate;
    } else if (state is CandidateRefused) {
      candidate = state.candidate;
    } else if (state is CandidateDetailError && state.lastKnown != null) {
      candidate = state.lastKnown;
    }

    if (candidate == null) return const SizedBox.shrink();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(candidate),
              _buildScoreCard(candidate),
              const SizedBox(height: AppSpacing.sm),
              if (candidate.skills.isNotEmpty)
                _buildSkillsCard(candidate.skills),
              const SizedBox(height: AppSpacing.sm),
              _buildCvCard(candidate),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildStickyActions(candidate, isActing, actingAction),
        ),
      ],
    );
  }

  // ─── Hero header ─────────────────────────────────────────────────────────

  Widget _buildHeroHeader(CandidateDetailData candidate) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsLight.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    imageUrl: candidate.photoUrl,
                    radius: 44,
                    defaultIcon: Icons.person_rounded,
                    backgroundColor: AppColorsLight.primary.withOpacity(0.12),
                    iconColor: AppColorsLight.primary,
                  ),
                ),
                if (candidate.status == 'retained')
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: _statusDot(
                      AppColorsLight.success,
                      Icons.check_rounded,
                    ),
                  ),
                if (candidate.status == 'refused')
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: _statusDot(
                      AppColorsLight.error,
                      Icons.close_rounded,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  candidate.studentName,
                  style: AppTypography.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if (candidate.educationLevel.isNotEmpty ||
                    candidate.fieldOfStudy.isNotEmpty)
                  Text(
                    [
                      if (candidate.educationLevel.isNotEmpty)
                        candidate.educationLevel,
                      if (candidate.fieldOfStudy.isNotEmpty)
                        candidate.fieldOfStudy,
                    ].join(' • '),
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: AppColorsLight.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.work_outline_rounded,
                        size: 13,
                        color: AppColorsLight.primary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          candidate.offerTitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColorsLight.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _statusDot(Color color, IconData icon) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColorsLight.bgDark, width: 2),
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }

  Widget _initialsWidget(String name, double size) {
    return Container(
      width: size,
      height: size,
      color: AppColorsLight.primary.withOpacity(0.12),
      child: Center(
        child: Text(
          _getInitials(name),
          style: AppTypography.displayMedium.copyWith(
            color: AppColorsLight.primary,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }

  // ─── Score card ───────────────────────────────────────────────────────────

  Widget _buildScoreCard(CandidateDetailData candidate) {
    final score = candidate.matchScore;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.bgDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Score de matching', style: AppTypography.headingSmall),
              const Spacer(),
              MatchScoreBadge(score: score),
            ],
          ),
          if (candidate.matchExplanation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColorsLight.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColorsLight.primary.withOpacity(0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColorsLight.primary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      candidate.matchExplanation!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsLight.primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Compétences ──────────────────────────────────────────────────────────

  Widget _buildSkillsCard(List<SkillDetail> skills) {
    final technical = skills.where((s) => s.skillType == 'technical').toList();
    final soft = skills.where((s) => s.skillType == 'soft').toList();
    final languages = skills.where((s) => s.skillType == 'language').toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.bgDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColorsLight.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColorsLight.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Compétences', style: AppTypography.headingSmall),
              const Spacer(),
              Text('${skills.length} au total', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (technical.isNotEmpty) ...[
            _skillGroupLabel('Techniques', AppColorsLight.primary),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: technical.map((s) => _SkillTag(label: s.name)).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (soft.isNotEmpty) ...[
            _skillGroupLabel('Soft skills', AppColorsLight.secondary),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: soft
                  .map(
                    (s) => _SkillTag(
                      label: s.name,
                      color: AppColorsLight.secondary,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (languages.isNotEmpty) ...[
            _skillGroupLabel('Langues', AppColorsLight.success),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: languages
                  .map(
                    (s) =>
                        _SkillTag(label: s.name, color: AppColorsLight.success),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _skillGroupLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─── CV card ──────────────────────────────────────────────────────────────

  Widget _buildCvCard(CandidateDetailData candidate) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.bgDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColorsLight.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColorsLight.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Curriculum Vitae du candidat',
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (candidate.cvUrl != null)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openCv(candidate.cvUrl!),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColorsLight.error.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColorsLight.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColorsLight.error,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              candidate.cvFileName ?? 'CV du candidat',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Appuyer pour ouvrir',
                              style: AppTypography.caption.copyWith(
                                color: AppColorsLight.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColorsLight.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: AppColorsLight.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColorsLight.bgSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColorsLight.textTertiary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Aucun CV uploadé par ce candidat',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Actions sticky ───────────────────────────────────────────────────────

  Widget _buildStickyActions(
    CandidateDetailData candidate,
    bool isActing,
    String action,
  ) {
    final isRetained = candidate.status == 'retained';
    final isRefused = candidate.status == 'refused';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColorsLight.bgDark,
        border: Border(top: BorderSide(color: AppColorsLight.bgSurface)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: isRetained
          ? _statusBanner(
              'Candidature retenue',
              AppColorsLight.success,
              Icons.check_circle_rounded,
            )
          : isRefused
          ? _statusBanner(
              'Candidature refusée',
              AppColorsLight.error,
              Icons.cancel_rounded,
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isActing ? null : _cubit.refuseCandidate,
                    icon: (isActing && action == 'refusing')
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColorsLight.error,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColorsLight.error,
                          ),
                    label: Text(
                      'Refuser',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColorsLight.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColorsLight.error,
                      side: const BorderSide(color: AppColorsLight.error),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isActing
                          ? LinearGradient(
                              colors: [
                                AppColorsLight.success.withOpacity(0.5),
                                AppColorsLight.success.withOpacity(0.3),
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                AppColorsLight.success,
                                Color(0xFF00C853),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      boxShadow: isActing
                          ? []
                          : [
                              BoxShadow(
                                color: AppColorsLight.success.withOpacity(0.35),
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
                        onTap: isActing ? null : _cubit.retainCandidate,
                        child: Center(
                          child: (isActing && action == 'retaining')
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Retenir ce candidat',
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
              ],
            ),
    );
  }

  Widget _statusBanner(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.labelLarge.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'retained':
        color = AppColorsLight.primary;
        label = 'Retenu';
        icon = Icons.check_circle_rounded;
        break;
      case 'refused':
        color = AppColorsLight.textTertiary;
        label = 'Refusé';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColorsLight.textSecondary;
        label = 'En attente';
        icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
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

class _SkillTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SkillTag({required this.label, this.color = AppColorsLight.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
