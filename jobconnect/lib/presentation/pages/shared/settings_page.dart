import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  String _currentLanguageLabel(BuildContext context) {
    final locale = context.locale;
    if (locale.languageCode == 'en') return 'English';
    return 'Français';
  }

  void _showLanguagePicker(BuildContext context) {
    final currentLocale = context.locale;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
          AppSpacing.lg + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              'settings.select_language'.tr(),
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Français
            _LanguageOption(
              flag: '🇫🇷',
              label: 'Français',
              isSelected: currentLocale.languageCode == 'fr',
              onTap: () {
                context.setLocale(const Locale('fr'));
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // English
            _LanguageOption(
              flag: '🇬🇧',
              label: 'English',
              isSelected: currentLocale.languageCode == 'en',
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldPwdController = TextEditingController();
    final newPwdController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColorsLight.bgCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
              Text(
                'settings.change_password'.tr(),
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Champ ancien mot de passe
              TextField(
                controller: oldPwdController,
                obscureText: obscureOld,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'settings.current_password'.tr(),
                  filled: true,
                  fillColor: AppColorsLight.bgDark,
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColorsLight.textTertiary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureOld ? Icons.visibility_off : Icons.visibility,
                      color: AppColorsLight.textTertiary,
                    ),
                    onPressed: () {
                      setModalState(() {
                        obscureOld = !obscureOld;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Champ nouveau mot de passe
              TextField(
                controller: newPwdController,
                obscureText: obscureNew,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'settings.new_password'.tr(),
                  filled: true,
                  fillColor: AppColorsLight.bgDark,
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColorsLight.textTertiary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: AppColorsLight.textTertiary,
                    ),
                    onPressed: () {
                      setModalState(() {
                        obscureNew = !obscureNew;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsLight.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: () {
                    final oldPwd = oldPwdController.text.trim();
                    final newPwd = newPwdController.text.trim();
                    if (oldPwd.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('settings.password_empty'.tr()),
                          backgroundColor: AppColorsLight.error,
                        ),
                      );
                      return;
                    }
                    if (newPwd.length >= 6) {
                      _authBloc.add(AuthChangePasswordRequested(oldPwd, newPwd));
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('settings.password_too_short'.tr()),),
                      );
                    }
                  },
                  child: Text(
                    'settings.save_password'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
     },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordChangedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('settings.password_changed_success'.tr()),
              backgroundColor: AppColorsLight.success,
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColorsLight.error,
            ),
          );
        }
      },
      child: Scaffold(
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
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'settings.title'.tr(),
                            style: AppTypography.headingMedium.copyWith(color: Colors.white),
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
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
            // Notifications section
            _SectionTitle(title: 'settings.notifications'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _SwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'settings.push_notifications'.tr(),
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                const Divider(color: AppColorsLight.bgSurface, height: 1),
                _SwitchTile(
                  icon: Icons.email_outlined,
                  title: 'settings.email_notifications'.tr(),
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Preferences section
            _SectionTitle(title: 'settings.preferences'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.language_rounded,
                  title: 'settings.language'.tr(),
                  trailing: _currentLanguageLabel(context),
                  onTap: () => _showLanguagePicker(context),
                ),
                const Divider(color: AppColorsLight.bgSurface, height: 1),
                _NavTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'settings.change_password'.tr(),
                  onTap: () => _showChangePasswordSheet(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // About section
            _SectionTitle(title: 'settings.about'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.description_outlined,
                  title: 'settings.terms'.tr(),
                  onTap: () {},
                ),
                const Divider(color: AppColorsLight.bgSurface, height: 1),
                _NavTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'settings.privacy'.tr(),
                  onTap: () {},
                ),
                const Divider(color: AppColorsLight.bgSurface, height: 1),
                _NavTile(
                  icon: Icons.info_outline_rounded,
                  title: 'settings.version'.tr(),
                  trailing: '1.0.0',
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Danger zone
            _SectionTitle(title: 'settings.account'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'settings.delete_account'.tr(),
                  titleColor: AppColorsLight.error,
                  onTap: () {},
                ),
              ],
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
    ),
    ),
    );
  }
}

// ── Language Option Widget ──────────────────────────────────────────────────

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorsLight.primary.withOpacity(0.08)
              : AppColorsLight.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColorsLight.primary.withOpacity(0.4)
                : AppColorsLight.bgSurface,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColorsLight.primary
                      : AppColorsLight.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColorsLight.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Existing helper widgets (unchanged) ────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        color: AppColorsLight.textSecondary,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColorsLight.bgSurface),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColorsLight.textSecondary),
      title: Text(title, style: AppTypography.bodyMedium),
      trailing: Switch(
        value: value,
        activeColor: AppColorsLight.primary,
        onChanged: onChanged,
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColorsLight.textSecondary),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(color: titleColor),
      ),
      trailing: trailing != null
          ? Text(trailing!, style: AppTypography.bodySmall)
          : (onTap != null
              ? const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColorsLight.textTertiary)
              : null),
      onTap: onTap,
    );
  }
}