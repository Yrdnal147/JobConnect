import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../injection_container.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/profile/student_profile/student_profile_cubit.dart';
import '../../../blocs/profile/student_profile/student_profile_state.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../shared/settings_page.dart';
import 'document_verification_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final StudentProfileCubit _cubit;
  late final AuthBloc _authBloc;

  final _skillController = TextEditingController();
  String _selectedSkillType = 'technical';

  @override
  void initState() {
    super.initState();
    _cubit = sl<StudentProfileCubit>();
    _authBloc = sl<AuthBloc>();
    _cubit.loadProfile();
  }

  @override
  void dispose() {
    _cubit.close();
    _authBloc.close();
    _skillController.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      _cubit.uploadPhoto(File(picked.path));
    }
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      _cubit.uploadCv(file, fileName);
    }
  }

  void _showAddSkillDialog(BuildContext context) {
    _skillController.clear();
    _selectedSkillType = 'technical';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColorsLight.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          title: Text(
            'profile.skills.add_title'.tr(),
            style: AppTypography.headingSmall,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _skillController,
                style: AppTypography.bodyLarge,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'profile.skills.add_hint'.tr(),
                  filled: true,
                  fillColor: AppColorsLight.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColorsLight.bgSurface),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColorsLight.bgSurface),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColorsLight.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Type de compétence
              Row(
                children: [
                  _TypeChip(
                    label: 'profile.skills.type_technical'.tr(),
                    isSelected: _selectedSkillType == 'technical',
                    onTap: () =>
                        setDialogState(() => _selectedSkillType = 'technical'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TypeChip(
                    label: 'profile.skills.type_soft'.tr(),
                    isSelected: _selectedSkillType == 'soft',
                    onTap: () =>
                        setDialogState(() => _selectedSkillType = 'soft'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TypeChip(
                    label: 'profile.skills.type_language'.tr(),
                    isSelected: _selectedSkillType == 'language',
                    onTap: () =>
                        setDialogState(() => _selectedSkillType = 'language'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'profile.actions.cancel'.tr(),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColorsLight.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_skillController.text.trim().isNotEmpty) {
                  _cubit.addSkill(_skillController.text, _selectedSkillType);
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsLight.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                'profile.actions.add'.tr(),
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColorsLight.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text('Modifier mon nom', style: AppTypography.headingSmall),
        content: TextField(
          controller: nameController,
          style: AppTypography.bodyLarge,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Entrez votre nom complet',
            filled: true,
            fillColor: AppColorsLight.bgDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColorsLight.bgSurface),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColorsLight.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: AppTypography.labelLarge.copyWith(
                color: AppColorsLight.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _cubit.updateFullName(nameController.text);
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsLight.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              'Enregistrer',
              style: AppTypography.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _authBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                context.go('/status-selection');
              } else if (state is AuthError) {
                _showSnack(
                  context,
                  'profile.errors.logout'.tr(args: [state.message]),
                  isError: true,
                );
              }
            },
          ),
          BlocListener<StudentProfileCubit, StudentProfileState>(
            listener: (context, state) {
              if (state is StudentProfileSaved) {
                _showSnack(context, 'profile.success.saved'.tr());
              } else if (state is StudentProfileError) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
        ],
        child: BlocBuilder<StudentProfileCubit, StudentProfileState>(
          builder: (context, state) {
            final profile = _extractProfile(state);
            final isPhotoUploading = state is StudentPhotoUploading;
            final isCvUploading = state is StudentCvUploading;
            final isCvAnalyzing = state is StudentCvAnalyzing;
            final isLoading = state is StudentProfileLoading;
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
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
                                      Text(
                                        'profile.title'.tr(),
                                        style: AppTypography.displayMedium.copyWith(
                                          color: Colors.white,
                                          fontSize: 26,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.settings_outlined,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const SettingsPage(),
                                              ),
                                            ),
                                        tooltip: 'profile.tooltip_settings'
                                            .tr(),
                                      ),
                                    ],
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
                                    child: CircularProgressIndicator(
                                      color: AppColorsLight.primary,
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.lg,
                                      AppSpacing.lg,
                                      AppSpacing.lg,
                                      120, // Espace pour la bottom navigation bar
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ── Header profil ─────────────────────────
                                        _buildHeader(profile, isPhotoUploading),
                                        const SizedBox(height: AppSpacing.lg),

                                        // ── Score CV ──────────────────────────────
                                        _buildScoreCard(
                                          context,
                                          profile,
                                          isCvUploading,
                                          isCvAnalyzing,
                                        ),
                                        const SizedBox(height: AppSpacing.lg),

                                        // ── Compétences ───────────────────────────
                                        _buildSkillsSection(context, profile),
                                        const SizedBox(height: AppSpacing.lg),

                                        // ── Vérification ──────────────────────────
                                        _buildVerificationSection(
                                          context,
                                          profile,
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
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
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(StudentProfileData? profile, bool isPhotoUploading) {
    final score = profile?.profileScore ?? 0;
    final scoreColor = score >= 75
        ? AppColorsLight.success
        : score >= 50
        ? AppColorsLight.warning
        : AppColorsLight.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColorsLight.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar avec jauge de score autour
          GestureDetector(
            onTap: isPhotoUploading ? null : _pickAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    backgroundColor: scoreColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    strokeWidth: 4,
                  ),
                ),
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgCard,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: isPhotoUploading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColorsLight.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : UserAvatar(
                          imageUrl: profile?.photoUrl,
                          radius: 37,
                          defaultIcon: Icons.person_rounded,
                          backgroundColor: Colors.transparent,
                          iconColor: AppColorsLight.primary,
                        ),
                ),
                if (!isPhotoUploading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColorsLight.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColorsLight.bgCard,
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              profile?.fullName ?? 'profile.default_name'.tr(),
                              style: AppTypography.headingMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showEditNameDialog(
                              context,
                              profile?.fullName ?? '',
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: AppColorsLight.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        border: Border.all(color: scoreColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: scoreColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${score}%',
                            style: AppTypography.labelLarge.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (profile?.targetOpportunity.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColorsLight.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      profile!.targetOpportunity,
                      style: AppTypography.caption.copyWith(
                        color: AppColorsLight.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(profile?.email ?? '', style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                _buildVerificationBadge(profile?.verificationStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(StudentVerificationStatus? status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case StudentVerificationStatus.verified:
        color = AppColorsLight.success;
        label = 'profile.verification.verified'.tr();
        icon = Icons.verified_rounded;
        break;
      case StudentVerificationStatus.pending:
        color = AppColorsLight.warning;
        label = 'profile.verification.pending'.tr();
        icon = Icons.hourglass_top_rounded;
        break;
      case StudentVerificationStatus.rejected:
        color = AppColorsLight.error;
        label = 'profile.verification.rejected'.tr();
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColorsLight.warning;
        label = 'profile.verification.unverified'.tr();
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
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
          Text(label, style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }

  // ─── Score card ───────────────────────────────────────────────────────────

  Widget _buildScoreCard(
    BuildContext context,
    StudentProfileData? profile,
    bool isCvUploading,
    bool isCvAnalyzing,
  ) {
    final bool hasCv = profile?.cvUrl != null || profile?.cvFileName != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hasCv
            ? AppColorsLight.success.withOpacity(0.05)
            : AppColorsLight.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: hasCv
              ? AppColorsLight.success.withOpacity(0.3)
              : AppColorsLight.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCv
                    ? Icons.check_circle_rounded
                    : Icons.document_scanner_rounded,
                color: hasCv ? AppColorsLight.success : AppColorsLight.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('CV & Documents', style: AppTypography.headingSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (hasCv) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColorsLight.success.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColorsLight.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColorsLight.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.cvFileName ?? 'CV Uploadé',
                          style: AppTypography.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vérifié par l\'IA',
                          style: AppTypography.caption.copyWith(
                            color: AppColorsLight.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Bouton upload CV stylisé
          InkWell(
            onTap: (isCvUploading || isCvAnalyzing) ? null : _pickCv,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: hasCv ? Colors.transparent : AppColorsLight.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: hasCv
                    ? Border.all(color: AppColorsLight.primary)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCvUploading || isCvAnalyzing)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: hasCv ? AppColorsLight.primary : Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Icon(
                      hasCv ? Icons.sync_rounded : Icons.cloud_upload_rounded,
                      size: 20,
                      color: hasCv ? AppColorsLight.primary : Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCvAnalyzing
                          ? AppStrings.aiAnalyzing
                          : isCvUploading
                          ? 'profile.cv.uploading'.tr()
                          : hasCv
                          ? 'Mettre à jour le CV'
                          : 'Importer un CV (PDF)',
                      style: AppTypography.labelLarge.copyWith(
                        color: hasCv ? AppColorsLight.primary : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compétences ──────────────────────────────────────────────────────────

  Widget _buildSkillsSection(
    BuildContext context,
    StudentProfileData? profile,
  ) {
    final skills = profile?.skills ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'profile.skills.title'.tr(),
              style: AppTypography.headingSmall,
            ),
            TextButton.icon(
              onPressed: () => _showAddSkillDialog(context),
              icon: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColorsLight.primary,
              ),
              label: Text(
                'profile.skills.add'.tr(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColorsLight.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColorsLight.bgCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColorsLight.bgSurface),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: skills.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 32,
                        color: AppColorsLight.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'profile.skills.empty'.tr(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColorsLight.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => _showAddSkillDialog(context),
                        child: Text(
                          'profile.skills.add_first'.tr(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColorsLight.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ...skills.map(
                      (skill) => _SkillChip(
                        label: skill.name,
                        skillType: skill.skillType,
                        onDelete: () => _cubit.removeSkill(skill.id),
                      ),
                    ),
                    // Bouton ajouter stylisé
                    GestureDetector(
                      onTap: () => _showAddSkillDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsLight.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: AppColorsLight.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: AppColorsLight.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'profile.skills.add'.tr(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColorsLight.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ─── Vérification ─────────────────────────────────────────────────────────

  Widget _buildVerificationSection(
    BuildContext context,
    StudentProfileData? profile,
  ) {
    final status =
        profile?.verificationStatus ?? StudentVerificationStatus.none;

    if (status == StudentVerificationStatus.verified) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColorsLight.success.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColorsLight.success.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              color: AppColorsLight.success,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.verification.verified_title'.tr(),
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColorsLight.success,
                    ),
                  ),
                  Text(
                    'profile.verification.verified_desc'.tr(),
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == StudentVerificationStatus.pending) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColorsLight.warning.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColorsLight.warning.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              color: AppColorsLight.warning,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.verification.pending_title'.tr(),
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColorsLight.warning,
                    ),
                  ),
                  Text(
                    'profile.verification.pending_desc'.tr(),
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColorsLight.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'profile.verification.get_badge'.tr(),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColorsLight.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            status == StudentVerificationStatus.rejected
                ? 'profile.verification.rejected_desc'.tr()
                : 'profile.verification.unverified_desc'.tr(),
            style: AppTypography.bodySmall,
          ),
          if (status == StudentVerificationStatus.rejected)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'profile.verification.rejected_warning'.tr(),
                style: AppTypography.caption.copyWith(
                  color: AppColorsLight.error,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DocumentVerificationPage(),
              ),
            ),
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: Text(
              status == StudentVerificationStatus.rejected
                  ? 'profile.verification.upload_new'.tr()
                  : 'profile.verification.upload'.tr(),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsLight.primary,
              side: const BorderSide(color: AppColorsLight.primary),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
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

  StudentProfileData? _extractProfile(StudentProfileState state) {
    if (state is StudentProfileLoaded) return state.profile;
    if (state is StudentProfileSaving) return state.profile;
    if (state is StudentProfileSaved) return state.profile;
    if (state is StudentPhotoUploading) return state.profile;
    if (state is StudentCvUploading) return state.profile;
    if (state is StudentProfileError) return state.lastKnownProfile;
    return null;
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SkillChip extends StatelessWidget {
  final String label;
  final String skillType;
  final VoidCallback onDelete;

  const _SkillChip({
    required this.label,
    required this.skillType,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color getSkillColor() {
      switch (skillType.toLowerCase()) {
        case 'technical':
          return AppColorsLight.primary;
        case 'soft':
          return const Color(0xFF00D9FF);
        case 'language':
          return AppColorsLight.success;
        default:
          return AppColorsLight.textSecondary;
      }
    }

    final color = getSkillColor();

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColorsLight.primary : AppColorsLight.bgSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColorsLight.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
