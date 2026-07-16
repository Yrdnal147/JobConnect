import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:ui';

class CompanyShell extends StatelessWidget {
  final Widget child;
  const CompanyShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/company/offers/create')) return 2;
    if (location.startsWith('/company/offers')) return 1;
    if (location.startsWith('/company/messages')) return 3;
    if (location.startsWith('/company/profile')) return 4;
    return 0;
  }

  static const _items = [
    (icon: Icons.dashboard_outlined,          activeIcon: Icons.dashboard_rounded,         label: 'nav.dashboard'),
    (icon: Icons.work_outline_rounded,         activeIcon: Icons.work_rounded,              label: 'nav.offers'),
    (icon: Icons.post_add_rounded,   activeIcon: Icons.post_add_rounded,        label: 'nav.publish'),
    (icon: Icons.chat_bubble_outline_rounded,  activeIcon: Icons.chat_bubble_rounded,       label: 'nav.messages'),
    (icon: Icons.person_outline,            activeIcon: Icons.person_rounded,          label: 'nav.profile'),
  ];

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/company/dashboard');     break;
      case 1: context.go('/company/offers');        break;
      case 2: context.go('/company/offers/create'); break;
      case 3: context.go('/company/messages');      break;
      case 4: context.go('/company/profile');       break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _currentIndex(context);
    return Scaffold(
      backgroundColor: AppColorsLight.bgDark,
      extendBody: true, // Permet au contenu de glisser sous la barre
      body: child,
      bottomNavigationBar: _AnimatedNavBar(
        selected: selected,
        items: _items,
        onTap: (i) => _onTap(context, i),
      ),
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
     // Utilisation de dart:ui
    
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColorsLight.primary.withOpacity(0.15), // Ombre légèrement teintée
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 72, // Légèrement plus haut
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
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
// Item — pill + scale élastique + wiggle au tap
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final bool isActive;
  final ({IconData icon, IconData activeIcon, String label}) item;

  const _NavItem({required this.isActive, required this.item});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with TickerProviderStateMixin {

  // ── 1. Pill + scale (persist tant qu'actif) ──
  late final AnimationController _pillCtrl;
  late final Animation<double>   _scaleAnim;

  // ── 2. Wiggle vertical (joue une fois au tap) ──
  late final AnimationController _wiggleCtrl;
  late final Animation<double>   _translateY;

  // ── 3. Rotation subtile (joue une fois au tap) ──
  late final AnimationController _rotCtrl;
  late final Animation<double>   _rotation;

  @override
  void initState() {
    super.initState();

    // ── Pill / scale ──
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pillCtrl, curve: Curves.elasticOut),
    );
    if (widget.isActive) _pillCtrl.forward();

    // ── Wiggle Y (bounce amorti sur ~900ms) ──
    _wiggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _translateY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: -9.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: -9.0, end:  0.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: -5.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -5.0, end:  0.0), weight: 13),
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: -2.5), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -2.5, end:  0.0), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 0.0,  end:  0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _wiggleCtrl, curve: Curves.easeInOut));

    // ── Rotation (léger balancement gauche-droite sur ~700ms) ──
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,   end: -0.06), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -0.06, end:  0.06), weight: 25),
      TweenSequenceItem(tween: Tween(begin:  0.06, end: -0.03), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.03, end:  0.03), weight: 15),
      TweenSequenceItem(tween: Tween(begin:  0.03, end:  0.0),  weight: 25),
    ]).animate(CurvedAnimation(parent: _rotCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      // Pill
      _pillCtrl.forward(from: 0);
      // Animations de mouvement
      _wiggleCtrl.forward(from: 0);
      _rotCtrl.forward(from: 0);
    } else if (!widget.isActive && old.isActive) {
      _pillCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _pillCtrl.dispose();
    _wiggleCtrl.dispose();
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor   = AppColorsLight.primary;
    final inactiveColor = AppColorsLight.textTertiaryDark;

    return AnimatedBuilder(
      animation: Listenable.merge([_pillCtrl, _wiggleCtrl, _rotCtrl]),
      builder: (_, __) {
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
                  width:  widget.isActive ? 56 : 0,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColorsLight.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),

                // Icône : scale + translateY + rotation
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
                fontWeight: widget.isActive
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: color,
                fontFamily: 'Poppins',
              ),
              child: Text(widget.item.label.tr(context: context)),
            ),
          ],
        );
      },
    );
  }
}