import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/profile/company_profile/company_profil_cubit.dart';
import '../../../blocs/profile/company_profile/company_profil_state.dart';
import '../../../../presentation/widgets/user_avatar.dart';
import '../../shared/settings_page.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _sectorCtrl      = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _ceoCtrl         = TextEditingController();
  final _websiteCtrl     = TextEditingController();
  String? _selectedSize;

  late final CompanyProfileCubit _cubit;
  late final AuthBloc _authBloc;

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _cubit    = sl<CompanyProfileCubit>();
    _authBloc = sl<AuthBloc>();
    _cubit.loadProfile();
  }

  @override
  void dispose() {
    _sectorCtrl.dispose();
    _descriptionCtrl.dispose();
    _ceoCtrl.dispose();
    _websiteCtrl.dispose();
    _cubit.close();
    _authBloc.close();
    super.dispose();
  }

  void _initControllers(CompanyProfileData profile) {
    if (_controllersInitialized) return;
    _sectorCtrl.text      = profile.sector;
    _descriptionCtrl.text = profile.description;
    _ceoCtrl.text         = profile.ceoName;
    _websiteCtrl.text     = profile.website;
    _selectedSize         = profile.size.isEmpty ? null : profile.size;
    _controllersInitialized = true;
  }

  void _save() {
    _cubit
      ..updateSector(_sectorCtrl.text)
      ..updateDescription(_descriptionCtrl.text)
      ..updateCeoName(_ceoCtrl.text)
      ..updateWebsite(_websiteCtrl.text);
    if (_selectedSize != null) _cubit.updateSize(_selectedSize!);
    _cubit.saveProfile();
  }

  void _logout() => _authBloc.add(const AuthLogoutRequested());

  void _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      _cubit.uploadLogo(File(picked.path));
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColorsLight.error : AppColorsLight.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColorsLight.bgDark,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: AppColorsLight.textTertiary)
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: AppColorsLight.bgDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: AppColorsLight.bgDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide:
            const BorderSide(color: AppColorsLight.primary, width: 1.5),
      ),
    );
  }

  Widget _fieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon,
            size: 15,
            color: AppColorsLight.textPrimary.withOpacity(0.6)),
        const SizedBox(width: 6),
        Text(text, style: AppTypography.labelLarge),
      ],
    );
  }

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
                _showSnack(context,
                    'company.profile.logout_error'.tr(args: [state.message]),
                    isError: true);
              }
            },
          ),
          BlocListener<CompanyProfileCubit, CompanyProfileState>(
            listener: (context, state) {
              if (state is CompanyProfileSaved) {
                _showSnack(context, 'company.profile.saved_success'.tr());
              } else if (state is CompanyProfileError) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
        ],
        child: BlocBuilder<CompanyProfileCubit, CompanyProfileState>(
          builder: (context, state) {
            if (state is CompanyProfileLoaded) {
              _initControllers(state.profile);
            }

            final profile = _extractProfile(state);
            final isSaving = state is CompanyProfileSaving;
            final isLogoUploading = state is CompanyLogoUploading;

            if (state is CompanyProfileLoading) {
              return const Scaffold(
                backgroundColor: AppColorsLight.bgDark,
                body: Center(
                  child: CircularProgressIndicator(
                      color: AppColorsLight.primary),
                ),
              );
            }

            return Scaffold(
              backgroundColor: AppColorsLight.bgDark,
              body: Stack(
                children: [
                  // ── En-tête Violet ────────────────────────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.25,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        'company.profile.title'.tr(),
                                        style: AppTypography.headingMedium.copyWith(color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Row(
                                    children: [
                                      // Badge non sauvegardé
                                      if (state is CompanyProfileLoaded && state.isDirty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColorsLight.warning.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                            border: Border.all(
                                              color: AppColorsLight.warning.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            'company.profile.unsaved'.tr(),
                                            style: AppTypography.caption.copyWith(color: AppColorsLight.warning),
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                                        onPressed: () => Navigator.of(context, rootNavigator: true).push(
                                          MaterialPageRoute(builder: (_) => const SettingsPage()),
                                        ),
                                        tooltip: 'company.profile.settings'.tr(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Carte Blanche Glassmorphism ──────────────────────
                  Positioned.fill(
                    top: MediaQuery.of(context).size.height * 0.14,
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
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header bannière + logo ──────────────────────
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColorsLight.bgDark,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                          border:
                              Border.all(color: AppColorsLight.bgSurface),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
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
                                  height: 84,
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
                                // Logo cliquable en overlap
                                Positioned(
                                  left: AppSpacing.lg,
                                  bottom: -32,
                                  child: GestureDetector(
                                    onTap: isLogoUploading
                                        ? null
                                        : _pickLogo,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColorsLight.bgCard,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppSpacing.radiusLg +
                                                        4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.08),
                                                blurRadius: 8,
                                                offset:
                                                    const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppColorsLight.primary
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppSpacing.radiusLg),
                                            ),
                                            child: isLogoUploading
                                                ? const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: AppColorsLight
                                                          .primary,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : UserAvatar(
                                                    imageUrl: profile?.logoUrl,
                                                    radius: 36,
                                                    defaultIcon: Icons.business_rounded,
                                                    backgroundColor: Colors.transparent,
                                                    iconColor: AppColorsLight.primary,
                                                  ),
                                          ),
                                        ),
                                        // Icône édition
                                        if (!isLogoUploading)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColorsLight.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      AppColorsLight.bgCard,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                40,
                                AppSpacing.lg,
                                AppSpacing.lg,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile?.name ?? 'company.profile.default_name'.tr(),
                                    style: AppTypography.headingMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.email_outlined,
                                          size: 13,
                                          color:
                                              AppColorsLight.textTertiary),
                                      const SizedBox(width: 4),
                                      Text(
                                        profile?.email ?? '',
                                        style:
                                            AppTypography.bodySmall.copyWith(
                                          color: AppColorsLight.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _buildVerificationBadge(
                                      profile?.verificationStatus),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Formulaire ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColorsLight.bgCard,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                          border:
                              Border.all(color: AppColorsLight.bgSurface),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColorsLight.primary),
                                const SizedBox(width: 6),
                                Text('company.profile.info_tab'.tr(),
                                    style: AppTypography.headingSmall),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _fieldLabel('company.profile.industry'.tr(),
                                Icons.category_outlined),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _sectorCtrl,
                              onChanged: _cubit.updateSector,
                              enabled: !isSaving,
                              style: AppTypography.bodyLarge,
                              decoration: _decoration('company.profile.sector_hint'.tr(),
                                  prefixIcon: Icons.category_outlined),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _fieldLabel('company.profile.size_label'.tr(),
                                Icons.groups_outlined),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<String>(
                              value: _selectedSize,
                              dropdownColor: AppColorsLight.bgCard,
                              style: AppTypography.bodyLarge,
                              icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColorsLight.textTertiary),
                              decoration: _decoration('',
                                  prefixIcon: Icons.groups_outlined),
                              items: [
                                DropdownMenuItem(
                                    value: '1-10',
                                    child: Text('company.profile.size_1_10'.tr())),
                                DropdownMenuItem(
                                    value: '11-50',
                                    child: Text('company.profile.size_11_50'.tr())),
                                DropdownMenuItem(
                                    value: '51-200',
                                    child: Text('company.profile.size_51_200'.tr())),
                                DropdownMenuItem(
                                    value: '200+',
                                    child: Text('company.profile.size_200_plus'.tr())),
                              ],
                              onChanged: isSaving
                                  ? null
                                  : (v) {
                                      setState(() => _selectedSize = v);
                                      if (v != null)
                                        _cubit.updateSize(v);
                                    },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _fieldLabel('company.profile.desc_label'.tr(), Icons.notes_rounded),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _descriptionCtrl,
                              onChanged: _cubit.updateDescription,
                              enabled: !isSaving,
                              maxLines: 4,
                              style: AppTypography.bodyLarge,
                              decoration:
                                  _decoration('company.profile.desc_hint'.tr()),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _fieldLabel('company.profile.ceo_label'.tr(), Icons.badge_outlined),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _ceoCtrl,
                              onChanged: _cubit.updateCeoName,
                              enabled: !isSaving,
                              style: AppTypography.bodyLarge,
                              decoration: _decoration('company.profile.ceo_hint'.tr(),
                                  prefixIcon: Icons.badge_outlined),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            _fieldLabel('company.profile.website'.tr(), Icons.language_rounded),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _websiteCtrl,
                              onChanged: _cubit.updateWebsite,
                              enabled: !isSaving,
                              keyboardType: TextInputType.url,
                              style: AppTypography.bodyLarge,
                              decoration: _decoration('company.profile.website_hint'.tr(),
                                  prefixIcon: Icons.language_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Section vérification ────────────────────────
                      _buildVerificationSection(context, profile),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Bouton Enregistrer ──────────────────────────
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          gradient: isSaving
                              ? LinearGradient(colors: [
                                  AppColorsLight.primary.withOpacity(0.5),
                                  AppColorsLight.secondary.withOpacity(0.5),
                                ])
                              : LinearGradient(colors: [
                                  AppColorsLight.textPrimary,
                                  AppColorsLight.primary,
                                ]),
                          boxShadow: isSaving
                              ? []
                              : [
                                  BoxShadow(
                                    color: AppColorsLight.primary
                                        .withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: isSaving ? null : _save,
                            child: Center(
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'company.profile.save_btn'.tr(),
                                      style:
                                          AppTypography.labelLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Bouton Déconnexion ──────────────────────────
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          final isLoading = authState is AuthLoading;
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColorsLight.error.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                            ),
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _logout,
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: AppColorsLight.error,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.logout_rounded,
                                      size: 18,
                                      color: AppColorsLight.error),
                              label: Text(
                                'company.profile.logout'.tr(),
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColorsLight.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColorsLight.error),
                                minimumSize:
                                    const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
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

  // ─── Badge vérification ───────────────────────────────────────────────────

  Widget _buildVerificationBadge(CompanyVerificationStatus? status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case CompanyVerificationStatus.verified:
        color = AppColorsLight.success;
        label = 'company.profile.verified'.tr();
        icon = Icons.verified_rounded;
        break;
      case CompanyVerificationStatus.pending:
        color = AppColorsLight.warning;
        label = 'company.profile.pending_verification'.tr();
        icon = Icons.hourglass_top_rounded;
        break;
      case CompanyVerificationStatus.rejected:
        color = AppColorsLight.error;
        label = 'Document rejeté';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColorsLight.warning;
        label = 'Non vérifiée';
        icon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
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

  // ─── Section vérification RCCM ───────────────────────────────────────────

  Widget _buildVerificationSection(
      BuildContext context, CompanyProfileData? profile) {
    final status =
        profile?.verificationStatus ?? CompanyVerificationStatus.none;

    if (status == CompanyVerificationStatus.verified) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColorsLight.success.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border:
              Border.all(color: AppColorsLight.success.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: AppColorsLight.success, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entreprise vérifiée',
                      style: AppTypography.headingSmall
                          .copyWith(color: AppColorsLight.success)),
                  Text(
                    'Votre RCCM a été validé. Le badge vérifié est visible sur vos offres.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == CompanyVerificationStatus.pending) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColorsLight.warning.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border:
              Border.all(color: AppColorsLight.warning.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded,
                color: AppColorsLight.warning, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vérification en cours',
                      style: AppTypography.headingSmall
                          .copyWith(color: AppColorsLight.warning)),
                  Text(
                    'Votre RCCM est en cours de vérification. Vous serez notifié sous 24h.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // none ou rejected
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsLight.primary.withOpacity(0.07),
            AppColorsLight.secondary.withOpacity(0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border:
            Border.all(color: AppColorsLight.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColorsLight.primary,
                    AppColorsLight.secondary,
                  ]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Vérifiez votre entreprise',
                  style: AppTypography.headingSmall
                      .copyWith(color: AppColorsLight.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            status == CompanyVerificationStatus.rejected
                ? 'Votre document précédent a été rejeté. Veuillez uploader un RCCM valide.'
                : 'Uploadez votre RCCM pour obtenir le badge vérifié et inspirer confiance aux candidats.',
            style: AppTypography.bodySmall,
          ),
          if (status == CompanyVerificationStatus.rejected)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Vérifiez que le RCCM est lisible et en cours de validité.',
                style: AppTypography.caption
                    .copyWith(color: AppColorsLight.error),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Material(
              color: AppColorsLight.bgCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/company/profile/verify'),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border:
                        Border.all(color: AppColorsLight.primary),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_rounded,
                            size: 18, color: AppColorsLight.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          status == CompanyVerificationStatus.rejected
                              ? 'Uploader un nouveau RCCM'
                              : 'Uploader le RCCM',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColorsLight.primary,
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

  // ─── Helper ──────────────────────────────────────────────────────────────

  CompanyProfileData? _extractProfile(CompanyProfileState state) {
    if (state is CompanyProfileLoaded) return state.profile;
    if (state is CompanyProfileSaving) return state.profile;
    if (state is CompanyProfileSaved) return state.profile;
    if (state is CompanyLogoUploading) return state.profile;
    if (state is CompanyProfileError) return state.lastKnownProfile;
    return null;
  }
}