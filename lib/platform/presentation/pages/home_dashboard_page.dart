/// # HomeDashboardPage
///
/// The platform home screen: company header, employee card, and the grid of
/// applications the signed-in employee is authorised to open.
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
    final modules = AppRegistry.authorisedFor(session.grantedModuleIds);

    return Scaffold(
      backgroundColor: AppColors.background,
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
          padding: EdgeInsets.fromLTRB(padding, AppDimens.lg, padding, AppDimens.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimens.md),
              // بطاقة معلومات الموظف مع مسافة وترتيب ممتاز
              Transform.translate(
                offset: const Offset(0, 16),
                child: FadeSlideIn(
                  child: EmployeeInfoCard(
                    employee: session.employee,
                    appCount: modules.length,
                  ),
                ),
              ),
              const SizedBox(height: 48),
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            const Text(
              'التطبيقات المتاحة',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            '$count تطبيقات نشطة',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

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

  String _greeting() => DateTime.now().hour < 12 ? 'صباح الخير' : 'مساء الخير';
}
