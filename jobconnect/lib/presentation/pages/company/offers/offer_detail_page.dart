import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../blocs/profile/offers/offer_detail_cubit.dart';
import '../../../blocs/profile/offers/offer_detail_state.dart';
import '../../../blocs/profile/offers/offers_state.dart';

class CompanyOfferDetailPage extends StatefulWidget {
  final String offerId;
  const CompanyOfferDetailPage({super.key, required this.offerId});

  @override
  State<CompanyOfferDetailPage> createState() =>
      _CompanyOfferDetailPageState();
}

class _CompanyOfferDetailPageState extends State<CompanyOfferDetailPage> {
  late final OfferDetailCubit _cubit;

  // Controllers pour le mode édition
  final _titleCtrl       = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _salaryCtrl      = TextEditingController();
  final _durationCtrl    = TextEditingController();
  final _skillCtrl       = TextEditingController();

  String _offerType    = 'cdi';
  String _minEducation = 'bac+3';
  int    _yearsOfExp   = 0;
  bool   _isActive     = true;
  List<String> _skills = [];

  bool _isEditing = false;
  bool _controllersInitialized = false;

  final List<Map<String, String>> _offerTypes = [
    {'value': 'cdi',                 'label': 'CDI'},
    {'value': 'cdd',                 'label': 'CDD'},
    {'value': 'stage_academique',    'label': 'Stage académique'},
    {'value': 'stage_professionnel', 'label': 'Stage professionnel'},
  ];

  final List<String> _educationLevels = [
    'bac', 'bac+2', 'bac+3', 'bac+4', 'bac+5', 'doctorat'
  ];

  @override
  void initState() {
    super.initState();
    _cubit = sl<OfferDetailCubit>();
    _cubit.loadOffer(widget.offerId);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _salaryCtrl.dispose();
    _durationCtrl.dispose();
    _skillCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  // ─── Init controllers depuis l'offre chargée ──────────────────────────────

  void _initControllers(OfferItem offer) {
    if (_controllersInitialized) return;
    _titleCtrl.text       = offer.title;
    _descriptionCtrl.text = offer.description;
    _locationCtrl.text    = offer.location;
    _salaryCtrl.text      = offer.salaryRange ?? '';
    _durationCtrl.text    = offer.durationMonths?.toString() ?? '';
    _offerType            = offer.offerType;
    _minEducation         = offer.minEducation.isEmpty
        ? 'bac+3'
        : offer.minEducation;
    _yearsOfExp           = offer.yearsOfExperience;
    _isActive             = offer.isActive;
    _skills               = List.from(offer.requiredSkills);
    _controllersInitialized = true;
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  void _addSkill() {
    final skill = _skillCtrl.text.trim();
    if (skill.isEmpty || _skills.contains(skill)) return;
    setState(() {
      _skills.add(skill);
      _skillCtrl.clear();
    });
  }

  void _save() {
    _cubit.updateOffer(
      offerId: widget.offerId,
      title: _titleCtrl.text,
      description: _descriptionCtrl.text,
      offerType: _offerType,
      minEducation: _minEducation,
      location: _locationCtrl.text,
      requiredSkills: _skills,
      yearsOfExperience: _yearsOfExp,
      isActive: _isActive,
      durationMonths: _durationCtrl.text.isNotEmpty
          ? int.tryParse(_durationCtrl.text)
          : null,
      salaryRange: _salaryCtrl.text.trim().isEmpty
          ? null
          : _salaryCtrl.text.trim(),
    );
  }

  // ─── Dialog suppression ───────────────────────────────────────────────────

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColorsLight.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColorsLight.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColorsLight.error,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Supprimer l\'offre',
                style: AppTypography.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous supprimer définitivement cette offre ?',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColorsLight.error.withOpacity(0.05),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColorsLight.error.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColorsLight.error,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible. Toutes les candidatures liées seront également supprimées.',
                      style: AppTypography.caption.copyWith(
                        color: AppColorsLight.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Bouton Annuler
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Annuler',
              style: AppTypography.labelLarge.copyWith(
                color: AppColorsLight.textSecondary,
              ),
            ),
          ),
          // Bouton Supprimer
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _cubit.deleteOffer(widget.offerId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsLight.error,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              'Supprimer',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatOfferType(String type) {
    switch (type) {
      case 'cdi':                 return 'CDI';
      case 'cdd':                 return 'CDD';
      case 'stage_academique':    return 'Stage académique';
      case 'stage_professionnel': return 'Stage professionnel';
      default:                    return type;
    }
  }

  IconData _iconForOfferType(String value) {
    switch (value) {
      case 'cdi':                 return Icons.work_rounded;
      case 'cdd':                 return Icons.event_note_rounded;
      case 'stage_academique':    return Icons.school_rounded;
      case 'stage_professionnel': return Icons.business_center_rounded;
      default:                    return Icons.work_rounded;
    }
  }

  InputDecoration _decoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColorsLight.bgDark,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20,
              color: AppColorsLight.textTertiary)
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
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
            color: AppColorsLight.primary, width: 1.5),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: AppColorsLight.textPrimary.withOpacity(0.6)),
        const SizedBox(width: 6),
        Text(text, style: AppTypography.labelLarge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<OfferDetailCubit, OfferDetailState>(
        listener: (context, state) {
          if (state is OfferDetailLoaded) {
            _initControllers(state.offer);
          }
          if (state is OfferDetailUpdated) {
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Offre modifiée avec succès '),
                backgroundColor: AppColorsLight.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
          }
          if (state is OfferDetailDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Offre supprimée définitivement'),
                backgroundColor: AppColorsLight.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
            context.go('/company/offers');
          }
          if (state is OfferDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColorsLight.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading  = state is OfferDetailLoading;
          final isUpdating = state is OfferDetailUpdating;
          final isDeleting = state is OfferDetailDeleting;
          final isBusy     = isUpdating || isDeleting;
          final offer = _extractOffer(state);
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
                              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.go('/company/offers');
                                }
                              },
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    _isEditing ? 'Modifier l\'offre' : 'Détail de l\'offre',
                                    style: AppTypography.displayMedium.copyWith(color: Colors.white, fontSize: 26),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLoading && offer != null && !isBusy) ...[
                              // Bouton Modifier / Annuler
                              IconButton(
                                icon: Icon(
                                  _isEditing
                                      ? Icons.close_rounded
                                      : Icons.edit_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleEdit,
                                tooltip: _isEditing ? 'Annuler' : 'Modifier',
                              ),
                              // Bouton Supprimer
                              if (!_isEditing)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.white),
                                  onPressed: () => _showDeleteDialog(context),
                                  tooltip: 'Supprimer',
                                ),
                            ],
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
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColorsLight.primary))
                              : offer == null
                                  ? _buildErrorState(context)
                                  : _isEditing
                                      ? _buildEditMode(offer, isBusy)
                                      : _buildViewMode(offer, isDeleting),
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

  // ─── Mode affichage ───────────────────────────────────────────────────────

  Widget _buildViewMode(OfferItem offer, bool isDeleting) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColorsLight.bgCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColorsLight.bgSurface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer.title,
                        style: AppTypography.headingMedium,
                      ),
                    ),
                    // Badge actif/inactif
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: offer.isActive
                            ? AppColorsLight.success.withOpacity(0.1)
                            : AppColorsLight.textTertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull),
                        border: Border.all(
                          color: offer.isActive
                              ? AppColorsLight.success.withOpacity(0.3)
                              : AppColorsLight.textTertiary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: offer.isActive
                                  ? AppColorsLight.success
                                  : AppColorsLight.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            offer.isActive ? 'Active' : 'Inactive',
                            style: AppTypography.caption.copyWith(
                              color: offer.isActive
                                  ? AppColorsLight.success
                                  : AppColorsLight.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Chips infos
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoChip(
                      icon: _iconForOfferType(offer.offerType),
                      label: _formatOfferType(offer.offerType),
                      color: AppColorsLight.primary,
                    ),
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: offer.location,
                      color: AppColorsLight.secondary,
                    ),
                    _InfoChip(
                      icon: Icons.school_outlined,
                      label: offer.minEducation.toUpperCase(),
                      color: AppColorsLight.warning,
                    ),
                    _InfoChip(
                      icon: Icons.timeline_rounded,
                      label: offer.yearsOfExperience == 0
                          ? 'Sans expérience'
                          : '${offer.yearsOfExperience} an${offer.yearsOfExperience > 1 ? 's' : ''} exp.',
                      color: AppColorsLight.textSecondary,
                    ),
                    if (offer.durationMonths != null)
                      _InfoChip(
                        icon: Icons.calendar_month_rounded,
                        label: '${offer.durationMonths} mois',
                        color: AppColorsLight.accentRed,
                      ),
                    if (offer.salaryRange != null)
                      _InfoChip(
                        icon: Icons.payments_outlined,
                        label: offer.salaryRange!,
                        color: AppColorsLight.success,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13,
                        color: AppColorsLight.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Publié le ${offer.postedAt}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.people_outline_rounded,
                        size: 13,
                        color: AppColorsLight.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.applicationsCount} candidature${offer.applicationsCount > 1 ? 's' : ''}',
                      style: AppTypography.caption.copyWith(
                        color: AppColorsLight.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Description ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColorsLight.bgCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColorsLight.bgSurface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 16,
                        color: AppColorsLight.primary),
                    const SizedBox(width: 6),
                    Text('Description',
                        style: AppTypography.headingSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  offer.description.isEmpty
                      ? 'Aucune description'
                      : offer.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColorsLight.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Compétences ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColorsLight.bgCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColorsLight.bgSurface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_outline_rounded,
                        size: 16,
                        color: AppColorsLight.primary),
                    const SizedBox(width: 6),
                    Text('Compétences requises',
                        style: AppTypography.headingSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                offer.requiredSkills.isEmpty
                    ? Text(
                        'Aucune compétence spécifiée',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColorsLight.textTertiary,
                        ),
                      )
                    : Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: offer.requiredSkills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorsLight.primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                              border: Border.all(
                                color: AppColorsLight.primary
                                    .withOpacity(0.25),
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Bouton voir candidatures ──────────────────────────────────
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              gradient: LinearGradient(colors: [
                AppColorsLight.textPrimary,
                AppColorsLight.primary,
              ]),
              boxShadow: [
                BoxShadow(
                  color: AppColorsLight.primary.withOpacity(0.3),
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
                onTap: () => 
                context.push('/company/candidates/all?offerId=${offer.offerId}'),
                
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_rounded,
                          color: Colors.white),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Voir les candidatures (${offer.applicationsCount})',
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

          if (isDeleting) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                      color: AppColorsLight.error),
                  SizedBox(height: AppSpacing.sm),
                  Text('Suppression en cours...'),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  //  Mode édition 

  Widget _buildEditMode(OfferItem offer, bool isBusy) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Titre ──────────────────────────────────────────────
                _sectionLabel('Titre du poste', Icons.edit_note_rounded),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _titleCtrl,
                  style: AppTypography.bodyLarge,
                  enabled: !isBusy,
                  decoration: _decoration('Ex: Développeur react Js',
                      prefixIcon: Icons.work_outline_rounded),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Type de contrat ────────────────────────────────────
                _sectionLabel('Type de contrat', Icons.category_rounded),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _offerTypes.map((type) {
                    final isSelected = _offerType == type['value'];
                    return GestureDetector(
                      onTap: isBusy
                          ? null
                          : () => setState(
                              () => _offerType = type['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [
                                  AppColorsLight.textPrimary,
                                  AppColorsLight.primary,
                                ])
                              : null,
                          color: isSelected
                              ? null
                              : AppColorsLight.bgCard,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColorsLight.bgSurface,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconForOfferType(type['value']!),
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : AppColorsLight.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type['label']!,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColorsLight.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Description ────────────────────────────────────────
                _sectionLabel('Description', Icons.description_outlined),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _descriptionCtrl,
                  maxLines: 6,
                  style: AppTypography.bodyLarge,
                  enabled: !isBusy,
                  decoration: _decoration('Décrivez le poste, les missions et les responsabilités...'),
                ),
                const SizedBox(height: AppSpacing.lg),

                //  Compétences 
                _sectionLabel('Compétences requises',
                    Icons.star_outline_rounded),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillCtrl,
                        style: AppTypography.bodyLarge,
                        enabled: !isBusy,
                        decoration: _decoration('Ex:  Maitrise de Django Rest  ',
                            prefixIcon: Icons.bolt_rounded),
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColorsLight.textPrimary,
                          AppColorsLight.primary,
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: isBusy ? null : _addSkill,
                        icon: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _skills.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd),
                          border: Border.all(
                              color: AppColorsLight.bgSurface),
                        ),
                        child: Text(
                          'Aucune compétence ajoutée',
                          style: AppTypography.caption.copyWith(
                            color: AppColorsLight.textTertiary,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _skills.map((skill) {
                          return Chip(
                            label: Text(
                              skill,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColorsLight.bgCard,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor:
                                AppColorsLight.primary.withOpacity(0.1),
                            side: BorderSide(
                              color: AppColorsLight.primary
                                  .withOpacity(0.25),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                            deleteIcon: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColorsLight.bgCard,
                            ),
                            onDeleted: isBusy
                                ? null
                                : () => setState(
                                    () => _skills.remove(skill)),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: AppSpacing.lg),

                //  Niveau d'éducation 
                _sectionLabel('Niveau d\'éducation minimum',
                    Icons.school_outlined),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _minEducation,
                  dropdownColor: AppColorsLight.bgCard,
                  style: AppTypography.bodyLarge,
                  decoration: _decoration(''),
                  items: _educationLevels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: isBusy
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() => _minEducation = v);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.lg),

                //  Années d'expérience 
                _sectionLabel('Années d\'expérience',
                    Icons.timeline_rounded),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgCard,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border:
                        Border.all(color: AppColorsLight.bgSurface),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _yearsOfExp == 0
                              ? 'Aucune expérience'
                              : '$_yearsOfExp an${_yearsOfExp > 1 ? 's' : ''} min',
                          style: AppTypography.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: isBusy
                                ? null
                                : () {
                                    if (_yearsOfExp > 0) {
                                      setState(() => _yearsOfExp--);
                                    }
                                  },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _yearsOfExp > 0
                                    ? AppColorsLight.primary
                                        .withOpacity(0.1)
                                    : AppColorsLight.bgSurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _yearsOfExp > 0
                                      ? AppColorsLight.primary
                                          .withOpacity(0.3)
                                      : AppColorsLight.bgSurface,
                                ),
                              ),
                              child: Icon(Icons.remove_rounded,
                                  size: 16,
                                  color: _yearsOfExp > 0
                                      ? AppColorsLight.primary
                                      : AppColorsLight.textTertiary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_yearsOfExp',
                            style: AppTypography.headingMedium.copyWith(
                              color: AppColorsLight.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: isBusy
                                ? null
                                : () {
                                    if (_yearsOfExp < 20) {
                                      setState(() => _yearsOfExp++);
                                    }
                                  },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppColorsLight.textPrimary,
                                  AppColorsLight.primary,
                                ]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Localisation ───────────────────────────────────────
                _sectionLabel('Localisation', Icons.location_on_outlined),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _locationCtrl,
                  style: AppTypography.bodyLarge,
                  enabled: !isBusy,
                  decoration: _decoration('Ex: Douala',
                      prefixIcon: Icons.location_on_outlined),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Durée si stage ─────────────────────────────────────
                if (_offerType == 'stage_academique' ||
                    _offerType == 'stage_professionnel') ...[
                  _sectionLabel(
                      'Durée (mois)', Icons.calendar_month_rounded),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _durationCtrl,
                    style: AppTypography.bodyLarge,
                    enabled: !isBusy,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Ex: 3',
                        prefixIcon: Icons.calendar_month_rounded),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Rémunération ───────────────────────────────────────
                _sectionLabel('Rémunération (optionnel)',
                    Icons.payments_outlined),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _salaryCtrl,
                  style: AppTypography.bodyLarge,
                  enabled: !isBusy,
                  decoration: _decoration('Ex: 100 000 FCFA / mois',
                      prefixIcon: Icons.payments_outlined),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Toggle actif/inactif ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgCard,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border:
                        Border.all(color: AppColorsLight.bgSurface),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Offre active',
                              style: AppTypography.labelLarge),
                          Text(
                            _isActive
                                ? 'Visible par les candidats'
                                : 'Masquée aux candidats',
                            style: AppTypography.caption.copyWith(
                              color: _isActive
                                  ? AppColorsLight.success
                                  : AppColorsLight.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        activeColor: AppColorsLight.primary,
                        onChanged: isBusy
                            ? null
                            : (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),

        // ── Bouton sauvegarder sticky ─────────────────────────────────
        Container(
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
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              gradient: isBusy
                  ? LinearGradient(colors: [
                      AppColorsLight.textPrimary.withOpacity(0.5),
                      AppColorsLight.primary.withOpacity(0.5),
                    ])
                  : LinearGradient(colors: [
                      AppColorsLight.textPrimary,
                      AppColorsLight.primary,
                    ]),
              boxShadow: isBusy
                  ? []
                  : [
                      BoxShadow(
                        color: AppColorsLight.primary.withOpacity(0.3),
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
                onTap: isBusy ? null : _save,
                child: Center(
                  child: isBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Sauvegarder les modifications',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── États auxiliaires ────────────────────────────────────────────────────

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
            Text('Offre introuvable',
                style: AppTypography.headingSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _cubit.loadOffer(widget.offerId),
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

  OfferItem? _extractOffer(OfferDetailState state) {
    if (state is OfferDetailLoaded)   return state.offer;
    if (state is OfferDetailUpdating) return state.offer;
    if (state is OfferDetailUpdated)  return state.offer;
    if (state is OfferDetailDeleting) return state.offer;
    if (state is OfferDetailError)    return state.lastKnownOffer;
    return null;
  }
}

// ─── Widget chip info ─────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.25)),
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