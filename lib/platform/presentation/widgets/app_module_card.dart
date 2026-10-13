/// # AppModuleCard
///
/// Neat and structured module card.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../domain/entities/app_module.dart';

class AppModuleCard extends StatelessWidget {
  const AppModuleCard({
    super.key,
    required this.module,
    required this.onTap,
    this.isHero = false,
  });

  final AppModule module;
  final VoidCallback onTap;
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.accent(module.accent);
    final accent = gradient.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isHero ? 22 : 18),
            child: isHero
                ? _buildHeroContent(context, accent)
                : _buildTileContent(context, accent),
          ),
        ),
      ),
    );
  }

  Widget _buildTileContent(BuildContext context, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(module.icon, color: accent, size: 28),
            ),
            if (module.badge != null) _buildBadge(accent),
          ],
        ),
        const Spacer(),
        Text(
          module.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          module.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'فتح التطبيق',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_back_rounded, size: 14, color: accent),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(module.icon, color: accent, size: 32),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (module.badge != null) ...[
                    const SizedBox(width: 8),
                    _buildBadge(accent),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                module.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_rounded, size: 18, color: accent),
        ),
      ],
    );
  }

  Widget _buildBadge(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        module.badge!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }
}
