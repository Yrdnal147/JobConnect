import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../../injection_container.dart';
import '../../../core/theme/theme_controller.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import 'user_avatar.dart';
import '../pages/shared/settings_page.dart';

// --- Student Drawer ---
class StudentDrawer extends StatelessWidget {
  final String userName;
  final String? photoUrl;
  
  const StudentDrawer({
    super.key,
    required this.userName,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseDrawer(
      userName: userName,
      photoUrl: photoUrl,
      role: 'student',
      menuItems: [
        _DrawerItem(
          icon: Icons.person_outline_rounded,
          title: 'nav.profile'.tr(),
          onTap: () {
            context.go('/student/profile');
            context.read<AdvancedDrawerController>().hideDrawer();
          },
        ),
        _DrawerItem(
          icon: Icons.notifications_outlined,
          title: 'settings.notifications'.tr(),
          onTap: () {
            context.read<AdvancedDrawerController>().hideDrawer();
            context.push('/notifications');
          },
        ),
        _DrawerItem(
          icon: Icons.emoji_events_outlined,
          title: 'profile.tooltip_success'.tr(),
          onTap: () {
            context.go('/student/success');
            context.read<AdvancedDrawerController>().hideDrawer();
          },
        ),
        _DrawerItem(
          icon: Icons.settings_outlined,
          title: 'settings.title'.tr(),
          onTap: () {
            context.read<AdvancedDrawerController>().hideDrawer();
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// --- Company Drawer ---
class CompanyDrawer extends StatelessWidget {
  final String companyName;
  final String? logoUrl;
  
  const CompanyDrawer({
    super.key,
    required this.companyName,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseDrawer(
      userName: companyName,
      photoUrl: logoUrl,
      role: 'company',
      menuItems: [
        _DrawerItem(
          icon: Icons.business_rounded,
          title: 'nav.profile'.tr(),
          onTap: () {
            context.go('/company/profile');
            context.read<AdvancedDrawerController>().hideDrawer();
          },
        ),
        _DrawerItem(
          icon: Icons.notifications_outlined,
          title: 'settings.notifications'.tr(),
          onTap: () {
            context.read<AdvancedDrawerController>().hideDrawer();
            context.push('/notifications');
          },
        ),
        _DrawerItem(
          icon: Icons.emoji_events_outlined,
          title: 'profile.tooltip_success'.tr(),
          onTap: () {
            context.push('/company/success');
            context.read<AdvancedDrawerController>().hideDrawer();
          },
        ),
        _DrawerItem(
          icon: Icons.settings_outlined,
          title: 'settings.title'.tr(),
          onTap: () {
            context.read<AdvancedDrawerController>().hideDrawer();
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// --- Base Drawer Widget ---
class _BaseDrawer extends StatelessWidget {
  final String userName;
  final String? photoUrl;
  final String role;
  final List<_DrawerItem> menuItems;

  const _BaseDrawer({
    required this.userName,
    required this.photoUrl,
    required this.role,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
      child: Container(
        padding: const EdgeInsets.only(top: 24.0, bottom: 24.0, left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Container(
              margin: const EdgeInsets.only(bottom: 24.0, left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    imageUrl: photoUrl,
                    radius: 36,
                    defaultIcon: role == 'student' 
                      ? Icons.person_rounded 
                      : Icons.business_rounded,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    userName,
                    style: AppTypography.headingMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: menuItems.map((item) => _buildMenuItem(item)).toList(),
              ),
            ),
            
            // Footer Actions (Dark Mode, Logout)
            const Divider(color: Colors.white24),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: sl<ThemeController>().themeModeNotifier,
              builder: (context, themeMode, _) {
                final isDark = themeMode == ThemeMode.dark;
                return ListTile(
                  onTap: () {
                    sl<ThemeController>().toggleTheme();
                  },
                  leading: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Colors.white70,
                  ),
                  title: Text(
                    isDark ? 'Mode clair' : 'Mode sombre',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                  ),
                );
              },
            ),
            ListTile(
              onTap: () {
                context.read<AdvancedDrawerController>().hideDrawer();
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              leading: const Icon(Icons.logout_rounded, color: AppColorsLight.error),
              title: Text(
                'profile.logout'.tr(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColorsLight.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMenuItem(_DrawerItem item) {
    return ListTile(
      onTap: item.onTap,
      leading: Icon(item.icon, color: Colors.white70),
      title: Text(
        item.title,
        style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
