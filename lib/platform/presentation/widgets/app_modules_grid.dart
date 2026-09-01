/// # AppModulesGrid
///
/// Responsive layout of the applications the signed-in employee may open.
///
/// Two shapes, chosen by the number of authorised applications:
///
/// * **one** → a single wide hero card (the requirement "if the employee has
///   access to only one application, only that application should appear" needs
///   no special case beyond this);
/// * **many** → a grid whose column count is derived from the viewport width
///   and a maximum tile width, with a fixed tile height.
///
/// Deriving columns from a maximum tile width rather than hard-coding them per
/// breakpoint is what keeps the cards identical in size for two applications or
/// twenty, on a phone or on a landscape tablet.
library;

import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../domain/entities/app_module.dart';
import 'app_module_card.dart';

class AppModulesGrid extends StatelessWidget {
  const AppModulesGrid({
    super.key,
    required this.modules,
    required this.onOpen,
  });

  final List<AppModule> modules;
  final void Function(AppModule module) onOpen;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) return const SizedBox.shrink();
    if (modules.length == 1) return _buildHero(context, modules.single);
    return _buildGrid(context);
  }

  Widget _buildHero(BuildContext context, AppModule module) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.appHeroMaxWidth(context),
        ),
        child: SizedBox(
          height: Responsive.appHeroHeight(context),
          child: FadeSlideIn(
            child: AppModuleCard(
              module: module,
              isHero: true,
              onTap: () => onOpen(module),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: Responsive.appTileMaxWidth(context),
        mainAxisExtent: Responsive.appTileHeight(context),
        crossAxisSpacing: AppDimens.lg,
        mainAxisSpacing: AppDimens.lg,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return FadeSlideIn(
          // Cascade the entrance so a long catalogue still feels ordered.
          delay: AppDimens.staggerStep * index,
          child: AppModuleCard(
            module: module,
            onTap: () => onOpen(module),
          ),
        );
      },
    );
  }
}
