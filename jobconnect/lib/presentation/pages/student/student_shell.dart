import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:ui';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../blocs/profile/student_profile/student_profile_cubit.dart';
import '../../blocs/profile/student_profile/student_profile_state.dart';
import '../../widgets/app_drawer.dart';
import '../../../../injection_container.dart';

class StudentShell extends StatefulWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  final _advancedDrawerController = AdvancedDrawerController();

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/student/search')) return 1;
    if (location.startsWith('/student/applications')) return 2;
    if (location.startsWith('/student/messages')) return 3;
    if (location.startsWith('/student/profile')) return 4;
    return 0;
  }

  static const _items = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'nav.home',
    ),
    (
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'nav.search',
    ),
    (
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'nav.applications',
    ),
    (
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'nav.messages',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'nav.profile',
    ),
  ];

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/student/home');
        break;
      case 1:
        context.go('/student/search');
        break;
      case 2:
        context.go('/student/applications');
        break;
      case 3:
        context.go('/student/messages');
        break;
      case 4:
        context.go('/student/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _currentIndex(context);
    return BlocProvider<StudentProfileCubit>(
      create: (_) => sl<StudentProfileCubit>()..loadProfile(),
      child: ListenableProvider<AdvancedDrawerController>.value(
        value: _advancedDrawerController,
      child: AdvancedDrawer(
        backdrop: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColorsLight.primary,
        ),
        controller: _advancedDrawerController,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        animateChildDecoration: true,
        rtlOpening: false,
        disabledGestures: false,
        childDecoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        drawer: BlocBuilder<StudentProfileCubit, StudentProfileState>(
          builder: (context, state) {
            String userName = 'Student';
            String? photoUrl;
            if (state is StudentProfileLoaded) {
              userName = state.profile.fullName;
              photoUrl = state.profile.photoUrl;
            }
            return StudentDrawer(
              userName: userName,
              photoUrl: photoUrl,
            );
          },
        ),
        child: Scaffold(
          backgroundColor: AppColorsLight.bgDark,
          extendBody: true,
          body: widget.child,
      bottomNavigationBar: _AnimatedNavBar(
        selected: selected,
        items: _items,
        onTap: (i) => _onTap(context, i),
      ),
    ),
    ),
      )

    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barre Flottante Glassmorphism
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedNavBar extends StatelessWidget {
  final int selected;
  final List<({IconData icon, IconData activeIcon, String label})> items;
  final void Function(int) onTap;

  const _AnimatedNavBar({
    required this.selected,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Assurez-vous que dart:ui est importé en haut, ou on l'utilise directement ici si besoin (ImageFilter)

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColorsLight.primary.withValues(
                alpha: 0.15,
              ), // Ombre légèrement teintée
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 72, // Légèrement plus haut pour un aspect premium
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColorsLight.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: _NavItem(
                        isActive: index == selected,
                        item: items[index],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        ),
      );
  }
    
  }


// ─────────────────────────────────────────────────────────────────────────────
// Item animé
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final bool isActive;
  final ({IconData icon, IconData activeIcon, String label}) item;

  const _NavItem({required this.isActive, required this.item});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with TickerProviderStateMixin {
  // 1. Pill + scale (persiste tant qu'actif)
  late final AnimationController _pillCtrl;
  late final Animation<double> _scaleAnim;

  // 2. Bounce vertical (joue une fois au tap)
  late final AnimationController _bounceCtrl;
  late final Animation<double> _translateY;

  // 3. Rotation balancement (joue une fois au tap)
  late final AnimationController _rotCtrl;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    // ── Pill / scale élastique ──────────────────────────────────────
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _pillCtrl, curve: Curves.elasticOut));
    if (widget.isActive) _pillCtrl.forward();

    // ── Bounce Y amorti (~900ms) ────────────────────────────────────
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _translateY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -9.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: -9.0, end: 0.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 13),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -2.5), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -2.5, end: 0.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    // ── Rotation balancement gauche-droite (~700ms) ─────────────────
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.06), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.06), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.03), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.03), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _rotCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _pillCtrl.forward(from: 0);
      _bounceCtrl.forward(from: 0);
      _rotCtrl.forward(from: 0);
    } else if (!widget.isActive && old.isActive) {
      _pillCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _pillCtrl.dispose();
    _bounceCtrl.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColorsLight.primary;
    final inactiveColor = AppColorsLight.textTertiaryDark;

    return AnimatedBuilder(
      animation: Listenable.merge([_pillCtrl, _bounceCtrl, _rotCtrl]),
      builder: (_, child) {
        final color = widget.isActive ? activeColor : inactiveColor;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pill de fond
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: widget.isActive ? 56 : 0,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                // Icône : bounce + rotation + scale
                Transform.translate(
                  offset: Offset(0, _translateY.value),
                  child: RotationTransition(
                    turns: _rotation,
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Icon(
                        widget.isActive
                            ? widget.item.activeIcon
                            : widget.item.icon,
                        color: color,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                color: color,
                fontFamily: 'Poppins',
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.item.label.tr(context: context),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
