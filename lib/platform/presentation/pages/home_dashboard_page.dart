/// # HomeDashboardPage
///
/// The platform home screen: company header, employee card, and the grid of
/// applications the signed-in employee is authorised to open.
///
/// The page is **data-driven end to end**. It asks the registry which of the
/// session's granted ids are renderable and lays them out; it contains no
/// reference to "inspection" or "meter reading". Registering a tenth
/// application changes nothing in this file.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../domain/entities/app_module.dart';
import '../../domain/entities/platform_session.dart';
import '../../registry/app_registry.dart';
import '../cubit/platform_auth_cubit.dart';
import '../widgets/app_modules_grid.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/employee_info_card.dart';
import '../widgets/no_access_view.dart';
import 'notifications_page.dart';
import '../../../features/settings/screens/settings_screen.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key, required this.session});

  final PlatformSession session;

  @override
  Widget build(BuildContext context) {
    // Only applications that are both granted by the server and present in
    // this build are rendered.
    final modules = AppRegistry.authorisedFor(session.grantedModuleIds);

    return Scaffold(
      body: Column(
        children: [
          DashboardHeader(
            greeting: _greeting(),
            isOffline: session.isOffline,
            onNotifications: () => _openNotifications(context),
            onSettings: () => _openSettings(context),
            onLogout: () => _confirmLogout(context),
          ),
          Expanded(
            child: modules.isEmpty
                ? NoAccessView(onLogout: () => _confirmLogout(context))
                : _buildBody(context, modules),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<AppModule> modules) {
    final padding = Responsive.pagePadding(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ContentBounds(
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, AppDimens.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overlaps the rounded header.
              Transform.translate(
                offset: const Offset(0, -AppDimens.xxl),
                child: FadeSlideIn(
                  child: EmployeeInfoCard(
                    employee: session.employee,
                    appCount: modules.length,
                  ),
                ),
              ),
              _buildSectionTitle(context, modules.length),
              const SizedBox(height: AppDimens.lg),
              AppModulesGrid(
                modules: modules,
                onOpen: (module) => _openModule(context, module),
              ),
              const SizedBox(height: AppDimens.xxl),
              Center(
                child: Text(
                  '${AppConstants.platformNameAr} — الإصدار ${AppConstants.platformVersion}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimens.sm),
        Text(
          'التطبيقات المتاحة',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: AppDimens.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  /// Opens a module, re-checking the entitlement at the moment of navigation so
  /// a stale card can never open an application the session does not grant.
  void _openModule(BuildContext context, AppModule module) {
    if (!session.canAccess(module.id)) {
      showAppMessage(
        context,
        message: 'لا تملك صلاحية الدخول إلى ${module.title}',
        isError: true,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: module.route),
        builder: (routeContext) => module.builder(routeContext, session),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final cubit = context.read<PlatformAuthCubit>();
    final confirmed = await showAppConfirm(
      context,
      title: 'تسجيل الخروج',
      message: 'سيتم إنهاء الجلسة لجميع التطبيقات. هل تريد المتابعة؟',
      confirmLabel: 'خروج',
      isDestructive: true,
    );
    if (confirmed == true) await cubit.signOut();
  }

  /// Time-of-day greeting; a small touch that makes the shell feel personal
  /// without inventing data.
  String _greeting() => DateTime.now().hour < 12 ? 'صباح الخير' : 'مساء الخير';
}
