import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../theme/neo_palette.dart';
import 'ui/pressable_scale.dart';

class FeatureTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int animationIndex;
  final bool isLocked;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.animationIndex = 0,
    this.isLocked = false,
  });

  @override
  State<FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<FeatureTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color;

    return PressableScale(
      scale: 0.96,
      onTap: widget.onTap,
      child: Opacity(
        opacity: widget.isLocked ? 0.72 : 1,
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NeoPalette.slateCard.withValues(alpha: 0.9),
                  NeoPalette.slateElevated.withValues(alpha: 0.65),
                ],
              ),
              border: Border.all(
                color: base.withValues(alpha: _pressed ? 0.55 : 0.3),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: base.withValues(alpha: _pressed ? 0.35 : 0.22),
                  blurRadius: _pressed ? 26 : 18,
                  offset: Offset(0, _pressed ? 10 : 7),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -18,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: base.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -12,
                  bottom: -20,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: base.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            base,
                            Color.lerp(base, NeoPalette.electricAmethyst, 0.4)!,
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        base.withValues(alpha: 0.9),
                                        Color.lerp(base, NeoPalette.electricAmethyst, 0.35)!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: base.withValues(alpha: 0.45),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: NeoPalette.textPrimary,
                                    size: 24,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: base.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: base.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Icon(
                                    widget.isLocked
                                        ? Icons.lock_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: widget.isLocked
                                        ? AppColors.textMuted
                                        : base,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: NeoPalette.textPrimary,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: NeoPalette.textSecondary,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (widget.animationIndex * 60).ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
