import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants/app_cities.dart';
import '../../../blocs/profile/offers/create_offer_cubit.dart';
import '../../../blocs/profile/offers/create_offer_state.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(text: 'Douala');
  final _skillController = TextEditingController();
  final _salaryController = TextEditingController();
  final _durationController = TextEditingController();

  String _offerType = 'cdi';
  String _minEducation = 'bac+3';
  int _yearsOfExp = 0;
  final List<String> _skills = [];

  late final CreateOfferCubit _cubit;

  List<Map<String, String>> get _offerTypes => [
    {'value': 'cdi', 'label': 'home.filters.cdi'.tr()},
    {'value': 'cdd', 'label': 'home.filters.cdd'.tr()},
    {
      'value': 'stage_academique',
      'label': 'home.filters.academic_internship'.tr(),
    },
    {
      'value': 'stage_professionnel',
      'label': 'home.filters.pro_internship'.tr(),
    },
  ];

  final List<String> _educationLevels = [
    'bac',
    'bac+2',
    'bac+3',
    'bac+4',
    'bac+5',
    'doctorat',
  ];

  @override
  void initState() {
    super.initState();
    _cubit = sl<CreateOfferCubit>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _skillController.dispose();
    _salaryController.dispose();
    _durationController.dispose();
    _cubit.close();
    super.dispose();
  }

  // ─── Complétion du formulaire ─────────────────────────────────────────────

  double get _completion {
    var filled = 0;
    if (_titleController.text.trim().isNotEmpty) filled++;
    if (_descriptionController.text.trim().isNotEmpty) filled++;
    if (_skills.isNotEmpty) filled++;
    if (_locationController.text.trim().isNotEmpty) filled++;
    return filled / 4;
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isEmpty) return;
    if (_skills.contains(skill)) return;
    setState(() {
      _skills.add(skill);
      _skillController.clear();
    });
  }

  void _publish() {
    _cubit.publishOffer(
      title: _titleController.text,
      description: _descriptionController.text,
      offerType: _offerType,
      minEducation: _minEducation,
      location: _locationController.text,
      requiredSkills: _skills,
      yearsOfExperience: _yearsOfExp,
      durationMonths: _durationController.text.isNotEmpty
          ? int.tryParse(_durationController.text)
          : null,
      salaryRange: _salaryController.text.trim().isEmpty
          ? null
          : _salaryController.text.trim(),
    );
  }

  IconData _iconForOfferType(String value) {
    switch (value) {
      case 'cdi':
        return Icons.work_rounded;
      case 'cdd':
        return Icons.event_note_rounded;
      case 'stage_academique':
        return Icons.school_rounded;
      case 'stage_professionnel':
        return Icons.business_center_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  InputDecoration _decoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColorsLight.bgCard,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: AppColorsLight.textTertiary)
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
        borderSide: const BorderSide(color: AppColorsLight.primary, width: 1.5),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColorsLight.textPrimary.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppTypography.labelLarge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<CreateOfferCubit, CreateOfferState>(
        listener: (context, state) {
          if (state is CreateOfferSuccess) {
            // Snackbar succès
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('company.offers.publish_success'.tr()),
                backgroundColor: AppColorsLight.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
            // Redirige vers la liste des offres
            context.go('/company/offers');
          } else if (state is CreateOfferError) {
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
          final isPublishing = state is CreateOfferPublishing;
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
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: Colors.white,
                              ),
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
                                    'company.offers.create_title'.tr(),
                                    style: AppTypography.displayMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 26,
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
                            children: [
                              // ── Formulaire scrollable ─────────────────────────────
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Barre de complétion
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'company.offers.completion_gauge'
                                                .tr(),
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: AppColorsLight
                                                      .textTertiary,
                                                ),
                                          ),
                                          Text(
                                            '${(_completion * 100).round()}%',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: AppColorsLight.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusFull,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: _completion,
                                          minHeight: 5,
                                          backgroundColor:
                                              AppColorsLight.bgSurface,
                                          valueColor: AlwaysStoppedAnimation(
                                            AppColorsLight.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Titre ───────────────────────────────────
                                      _sectionLabel(
                                        'company.offers.title_label'.tr(),
                                        Icons.edit_note_rounded,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      TextField(
                                        controller: _titleController,
                                        style: AppTypography.bodyLarge,
                                        enabled: !isPublishing,
                                        onChanged: (_) => setState(() {}),
                                        decoration: _decoration(
                                          'company.offers.title_hint_short'
                                              .tr(),
                                          prefixIcon:
                                              Icons.work_outline_rounded,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Type de contrat ──────────────────────────
                                      _sectionLabel(
                                        'company.offers.type_label'.tr(),
                                        Icons.category_rounded,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: AppSpacing.sm,
                                        runSpacing: AppSpacing.sm,
                                        children: _offerTypes.map((type) {
                                          final isSelected =
                                              _offerType == type['value'];
                                          return GestureDetector(
                                            onTap: isPublishing
                                                ? null
                                                : () => setState(
                                                    () => _offerType =
                                                        type['value']!,
                                                  ),
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
                                                              .textPrimary,
                                                          AppColorsLight
                                                              .primary,
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
                                                    _iconForOfferType(
                                                      type['value']!,
                                                    ),
                                                    size: 14,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : AppColorsLight
                                                              .textSecondary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    type['label']!,
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
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Description ──────────────────────────────
                                      _sectionLabel(
                                        'company.offers.description_label'.tr(),
                                        Icons.description_outlined,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      TextField(
                                        controller: _descriptionController,
                                        maxLines: 6,
                                        style: AppTypography.bodyLarge,
                                        enabled: !isPublishing,
                                        onChanged: (_) => setState(() {}),
                                        decoration: _decoration(
                                          'company.offers.description_hint'
                                              .tr(),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Compétences ──────────────────────────────
                                      _sectionLabel(
                                        'company.offers.requirements_label'
                                            .tr(),
                                        Icons.star_outline_rounded,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _skillController,
                                              style: AppTypography.bodyLarge,
                                              enabled: !isPublishing,
                                              decoration: _decoration(
                                                'company.offers.add_skill_hint'
                                                    .tr(),
                                                prefixIcon: Icons.bolt_rounded,
                                              ),
                                              onSubmitted: (_) => _addSkill(),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColorsLight.textPrimary,
                                                  AppColorsLight.primary,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColorsLight.primary
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: isPublishing
                                                  ? null
                                                  : _addSkill,
                                              icon: const Icon(
                                                Icons.add_rounded,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      if (_skills.isEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.md,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                            border: Border.all(
                                              color: AppColorsLight.bgSurface,
                                            ),
                                          ),
                                          child: Text(
                                            'company.offers.no_skill_added'
                                                .tr(),
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: AppColorsLight
                                                      .textTertiary,
                                                ),
                                          ),
                                        )
                                      else
                                        Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.sm,
                                          children: _skills.map((skill) {
                                            return Chip(
                                              label: Text(
                                                skill,
                                                style: AppTypography.labelSmall
                                                    .copyWith(
                                                      color:
                                                          AppColorsLight.bgCard,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              backgroundColor: AppColorsLight
                                                  .primary
                                                  .withOpacity(0.1),
                                              side: BorderSide(
                                                color: AppColorsLight.primary
                                                    .withOpacity(0.25),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppSpacing.radiusFull,
                                                    ),
                                              ),
                                              deleteIcon: Icon(
                                                Icons.close_rounded,
                                                size: 16,
                                                color: AppColorsLight.bgCard,
                                              ),
                                              onDeleted: isPublishing
                                                  ? null
                                                  : () => setState(
                                                      () =>
                                                          _skills.remove(skill),
                                                    ),
                                            );
                                          }).toList(),
                                        ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Niveau d'éducation ───────────────────────
                                      _sectionLabel(
                                        'company.offers.education_label'.tr(),
                                        Icons.school_outlined,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      DropdownButtonFormField<String>(
                                        value: _minEducation,
                                        dropdownColor: AppColorsLight.bgCard,
                                        style: AppTypography.bodyLarge,
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppColorsLight.textTertiary,
                                        ),
                                        decoration: _decoration(''),
                                        items: _educationLevels.map((level) {
                                          return DropdownMenuItem(
                                            value: level,
                                            child: Text(level.toUpperCase()),
                                          );
                                        }).toList(),
                                        onChanged: isPublishing
                                            ? null
                                            : (value) {
                                                if (value != null) {
                                                  setState(
                                                    () => _minEducation = value,
                                                  );
                                                }
                                              },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Années d'expérience ──────────────────────────────────────────
                                      _sectionLabel(
                                        'company.offers.experience_label'.tr(),
                                        Icons.timeline_rounded,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColorsLight.bgCard,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusMd,
                                          ),
                                          border: Border.all(
                                            color: AppColorsLight.bgSurface,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Texte à gauche
                                            Expanded(
                                              child: Text(
                                                _yearsOfExp == 0
                                                    ? 'company.offers.no_experience'
                                                          .tr()
                                                    : _yearsOfExp > 1
                                                    ? 'company.offers.exp_min_plural'
                                                          .tr(
                                                            args: [
                                                              _yearsOfExp
                                                                  .toString(),
                                                            ],
                                                          )
                                                    : 'company.offers.exp_min_single'
                                                          .tr(
                                                            args: [
                                                              _yearsOfExp
                                                                  .toString(),
                                                            ],
                                                          ),
                                                style: AppTypography.bodyLarge,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            // Boutons à droite
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Bouton -
                                                GestureDetector(
                                                  onTap: isPublishing
                                                      ? null
                                                      : () {
                                                          if (_yearsOfExp > 0) {
                                                            setState(
                                                              () =>
                                                                  _yearsOfExp--,
                                                            );
                                                          }
                                                        },
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: _yearsOfExp > 0
                                                          ? AppColorsLight
                                                                .primary
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                          : AppColorsLight
                                                                .bgSurface,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: _yearsOfExp > 0
                                                            ? AppColorsLight
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.3,
                                                                  )
                                                            : AppColorsLight
                                                                  .bgSurface,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.remove_rounded,
                                                      size: 16,
                                                      color: _yearsOfExp > 0
                                                          ? AppColorsLight
                                                                .primary
                                                          : AppColorsLight
                                                                .textTertiary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Valeur
                                                Text(
                                                  '$_yearsOfExp',
                                                  style: AppTypography
                                                      .headingMedium
                                                      .copyWith(
                                                        color: AppColorsLight
                                                            .primary,
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Bouton +
                                                GestureDetector(
                                                  onTap: isPublishing
                                                      ? null
                                                      : () {
                                                          if (_yearsOfExp <
                                                              20) {
                                                            setState(
                                                              () =>
                                                                  _yearsOfExp++,
                                                            );
                                                          }
                                                        },
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          AppColorsLight
                                                              .textPrimary,
                                                          AppColorsLight
                                                              .primary,
                                                        ],
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.add_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Localisation ─────────────────────────────
                                      _sectionLabel(
                                        'company.offers.location_label'.tr(),
                                        Icons.location_on_outlined,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Autocomplete<String>(
                                        initialValue: TextEditingValue(
                                          text: _locationController.text,
                                        ),
                                        optionsBuilder:
                                            (
                                              TextEditingValue textEditingValue,
                                            ) {
                                              if (textEditingValue
                                                  .text
                                                  .isEmpty) {
                                                return const Iterable<
                                                  String
                                                >.empty();
                                              }
                                              return AppCities.cameroonCities
                                                  .where((String option) {
                                                    // Ignore case and accents in a simple way or just lowercase
                                                    return option
                                                        .toLowerCase()
                                                        .contains(
                                                          textEditingValue.text
                                                              .toLowerCase(),
                                                        );
                                                  });
                                            },
                                        onSelected: (String selection) {
                                          _locationController.text = selection;
                                          setState(() {});
                                        },
                                        fieldViewBuilder:
                                            (
                                              context,
                                              controller,
                                              focusNode,
                                              onEditingComplete,
                                            ) {
                                              return TextField(
                                                controller: controller,
                                                focusNode: focusNode,
                                                style: AppTypography.bodyLarge,
                                                enabled: !isPublishing,
                                                onEditingComplete:
                                                    onEditingComplete,
                                                onChanged: (val) {
                                                  _locationController.text =
                                                      val;
                                                  setState(() {});
                                                },
                                                decoration: _decoration(
                                                  'company.offers.location_hint_short'
                                                      .tr(),
                                                  prefixIcon: Icons
                                                      .location_on_outlined,
                                                ),
                                              );
                                            },
                                        optionsViewBuilder:
                                            (context, onSelected, options) {
                                              return Align(
                                                alignment: Alignment.topLeft,
                                                child: Material(
                                                  elevation: 4.0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSpacing.radiusMd,
                                                        ),
                                                  ),
                                                  child: Container(
                                                    width:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width -
                                                        (AppSpacing.lg * 2),
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxHeight: 220,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColorsLight.bgCard,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppSpacing.radiusMd,
                                                          ),
                                                    ),
                                                    child: ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      shrinkWrap: true,
                                                      itemCount: options.length,
                                                      itemBuilder:
                                                          (
                                                            BuildContext
                                                            context,
                                                            int index,
                                                          ) {
                                                            final String
                                                            option = options
                                                                .elementAt(
                                                                  index,
                                                                );
                                                            return InkWell(
                                                              onTap: () {
                                                                onSelected(
                                                                  option,
                                                                );
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      AppSpacing
                                                                          .md,
                                                                    ),
                                                                child: Text(
                                                                  option,
                                                                  style: AppTypography
                                                                      .bodyLarge,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      //  Durée (si stage)
                                      if (_offerType == 'stage_academique' ||
                                          _offerType ==
                                              'stage_professionnel') ...[
                                        _sectionLabel(
                                          'company.offers.duration_label'.tr(),
                                          Icons.calendar_month_rounded,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        TextField(
                                          controller: _durationController,
                                          style: AppTypography.bodyLarge,
                                          enabled: !isPublishing,
                                          keyboardType: TextInputType.number,
                                          decoration: _decoration(
                                            'company.offers.duration_hint_short'
                                                .tr(),
                                            prefixIcon:
                                                Icons.calendar_month_rounded,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                      ],

                                      //  Salaire (optionnel)
                                      _sectionLabel(
                                        'company.offers.salary_label'.tr(),
                                        Icons.payments_outlined,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      TextField(
                                        controller: _salaryController,
                                        style: AppTypography.bodyLarge,
                                        enabled: !isPublishing,
                                        decoration: _decoration(
                                          'company.offers.salary_hint_short'
                                              .tr(),
                                          prefixIcon: Icons.payments_outlined,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      // ── Assistant IA ─────────────────────────────
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppColorsLight.primary
                                                  .withOpacity(0.08),
                                              AppColorsLight.secondary
                                                  .withOpacity(0.08),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusLg,
                                          ),
                                          border: Border.all(
                                            color: AppColorsLight.primary
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColorsLight.primary,
                                                    AppColorsLight.secondary,
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.auto_awesome_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'company.offers.ai_assistant'
                                                        .tr(),
                                                    style: AppTypography
                                                        .labelSmall
                                                        .copyWith(
                                                          color: AppColorsLight
                                                              .primary,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'company.offers.ai_assistant_desc'
                                                        .tr(),
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                          color: AppColorsLight
                                                              .primary
                                                              .withOpacity(
                                                                0.85,
                                                              ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                    ],
                                  ),
                                ),
                              ),

                              // ── Bouton publier sticky ─────────────────────────────
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
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    gradient: isPublishing
                                        ? LinearGradient(
                                            colors: [
                                              AppColorsLight.primary
                                                  .withOpacity(0.5),
                                              AppColorsLight.secondary
                                                  .withOpacity(0.5),
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              AppColorsLight.textPrimary,
                                              AppColorsLight.primary,
                                            ],
                                          ),
                                    boxShadow: isPublishing
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
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: isPublishing ? null : _publish,
                                      child: Center(
                                        child: isPublishing
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                'company.offers.publish_btn'
                                                    .tr(),
                                                style: AppTypography.labelLarge
                                                    .copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ), // Close inner Container
                            ],
                          ), // Close Column
                        ), // Close ClipRRect
                      ), // Close Container
                    ), // Close BackdropFilter
                  ), // Close ClipRRect
                ), // Close Positioned.fill
              ],
            ), // Close Stack
          ); // Close Scaffold
        },
      ),
    );
  }
}
