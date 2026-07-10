import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_palette.dart';
import '../../utils/responsive_layout.dart';

class PremiumBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PremiumBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Expenses'),
    (Icons.insights_rounded, Icons.insights_outlined, 'Analytics'),
    (Icons.grid_view_rounded, Icons.grid_view_outlined, 'Menu'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final navHeight = ResponsiveLayout.bottomNavBarHeight(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? 4 : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
          child: Container(
            height: navHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NeoPalette.slateCard.withValues(alpha: 0.88),
                  NeoPalette.obsidianSlate.withValues(alpha: 0.72),
                ],
              ),
              border: Border.all(
                color: NeoPalette.cyberMint.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: NeoPalette.electricAmethyst.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / _items.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                      left: 6 + selectedIndex * tabWidth,
                      top: 8,
                      bottom: 8,
                      width: tabWidth - 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 340),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  NeoPalette.cyberMint.withValues(alpha: 0.18),
                                  NeoPalette.electricAmethyst.withValues(alpha: 0.12),
                                ],
                              ),
                              border: Border.all(
                                color: NeoPalette.cyberMint.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: NeoPalette.cyberMint.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_items.length, (index) {
                        final selected = index == selectedIndex;
                        final item = _items[index];
                        return Expanded(
                          child: _NavItem(
                            selected: selected,
                            filledIcon: item.$1,
                            outlineIcon: item.$2,
                            label: item.$3,
                            onTap: () {
                              if (index != selectedIndex) {
                                hapticSelect();
                                onSelected(index);
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData filledIcon;
  final IconData outlineIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.filledIcon,
    required this.outlineIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: ResponsiveLayout.bottomNavBarHeight(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  selected ? filledIcon : outlineIcon,
                  key: ValueKey('$filledIcon-$selected'),
                  size: 23,
                  color: selected ? NeoPalette.cyberMint : AppColors.textMuted,
                  shadows: selected
                      ? [
                          Shadow(
                            color: NeoPalette.cyberMint.withValues(alpha: 0.6),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? NeoPalette.cyberMint : AppColors.textMuted,
                letterSpacing: selected ? -0.2 : 0,
                shadows: selected
                    ? [
                        Shadow(
                          color: NeoPalette.cyberMint.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
