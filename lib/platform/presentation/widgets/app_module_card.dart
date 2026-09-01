/// # AppModuleCard
///
/// The application card of the home dashboard.
///
/// It renders whatever [AppModule] it is handed — icon, colour, title,
/// description — so the catalogue can grow without this file ever changing.
/// Two layouts share the same code: a portrait tile inside the grid, and a wide
/// "hero" row when the employee is entitled to a single application.
///
/// Material 3 details: tonal icon plate with the module accent, rounded 20 dp
/// corners, hairline border plus a soft ambient shadow, an ink ripple on press
/// and a 2 % scale-down for tactile feedback.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../domain/entities/app_module.dart';

class AppModuleCard extends StatefulWidget {
  const AppModuleCard({
    super.key,
    required this.module,
    required this.onTap,
    this.isHero = false,
  });

  final AppModule module;
  final VoidCallback onTap;

  /// Wide single-application layout.
  final bool isHero;

  @override
  State<AppModuleCard> createState() => _AppModuleCardState();
}

class _AppModuleCardState extends State<AppModuleCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.accent(widget.module.accent);
    final accent = gradient.first;

    return AnimatedScale(
      scale: _pressed ? 0.975 : 1,
      duration: AppDimens.fast,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: AppDimens.fast,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(
            color:
                _pressed ? accent.withValues(alpha: 0.35) : AppColors.outline,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: _pressed ? 0.16 : 0.10),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 3 : 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            splashColor: accent.withValues(alpha: 0.12),
            highlightColor: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            child: Padding(
              padding: EdgeInsets.all(
                widget.isHero ? AppDimens.xl : AppDimens.lg,
              ),
              child: widget.isHero
                  ? _buildHeroContent(context, gradient)
                  : _buildTileContent(context, gradient),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Layouts ───────────────────────────────────────────────────────────────

  Widget _buildTileContent(BuildContext context, List<Color> gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(gradient, size: 54, iconSize: 28),
            if (widget.module.badge != null) _buildBadge(gradient.first),
          ],
        ),
        const Spacer(),
        Text(
          widget.module.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimens.xs),
        Text(
          widget.module.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppDimens.md),
        _buildOpenRow(context, gradient.first),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context, List<Color> gradient) {
    return Row(
      children: [
        _buildIcon(gradient, size: 64, iconSize: 34),
        const SizedBox(width: AppDimens.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.module.badge != null) ...[
                    const SizedBox(width: AppDimens.sm),
                    _buildBadge(gradient.first),
                  ],
                ],
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                widget.module.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.md),
        _buildChevron(gradient.first),
      ],
    );
  }

  // ─── Pieces ────────────────────────────────────────────────────────────────

  Widget _buildIcon(
    List<Color> gradient, {
    required double size,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(widget.module.icon, color: Colors.white, size: iconSize),
    );
  }

  Widget _buildOpenRow(BuildContext context, Color accent) {
    return Row(
      children: [
        // Flexible so a long label (or a large system font scale) shortens
        // instead of overflowing the tile.
        Flexible(
          child: Text(
            'فتح التطبيق',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(width: AppDimens.xs),
        Icon(Icons.arrow_back_rounded, size: 15, color: accent),
      ],
    );
  }

  Widget _buildChevron(Color accent) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_back_rounded, size: 20, color: accent),
    );
  }

  Widget _buildBadge(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Text(
        widget.module.badge!,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }
}
