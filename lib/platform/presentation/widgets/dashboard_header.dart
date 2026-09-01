/// # DashboardHeader
///
/// Brand header of the home dashboard: the company logo and name, the
/// notifications button and the logout button, on the corporate blue gradient
/// with rounded bottom corners.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.onNotifications,
    required this.onSettings,
    required this.onLogout,
    this.notificationCount = 0,
    this.isOffline = false,
  });

  /// Short line above the company name, e.g. "صباح الخير".
  final String greeting;

  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  /// Number shown on the notification badge; `0` hides the badge.
  final int notificationCount;

  /// Shows an "offline session" chip when the session was restored without
  /// connectivity.
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimens.headerRadius),
          bottomRight: Radius.circular(AppDimens.headerRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.pagePadding(context),
            AppDimens.md,
            Responsive.pagePadding(context),
            AppDimens.xxxl,
          ),
          child: ContentBounds(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildLogo(wide ? 52 : 46),
                    const SizedBox(width: AppDimens.md),
                    Expanded(child: _buildTitles(context)),
                    _buildNotificationsButton(),
                    const SizedBox(width: AppDimens.xs),
                    _buildIconButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'الإعدادات',
                      onPressed: onSettings,
                    ),
                    const SizedBox(width: AppDimens.xs),
                    _buildIconButton(
                      icon: Icons.logout_rounded,
                      tooltip: 'تسجيل الخروج',
                      onPressed: onLogout,
                    ),
                  ],
                ),
                if (isOffline) ...[
                  const SizedBox(height: AppDimens.lg),
                  _buildOfflineChip(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double size) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset('assets/images/logo3.png', fit: BoxFit.contain),
    );
  }

  Widget _buildTitles(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppConstants.companyNameAr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'الإشعارات',
          onPressed: onNotifications,
        ),
        if (notificationCount > 0)
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: Text(
                notificationCount > 99 ? '99+' : '$notificationCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.white, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        padding: const EdgeInsets.all(AppDimens.sm),
      ),
    );
  }

  Widget _buildOfflineChip() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
            SizedBox(width: AppDimens.sm),
            Text(
              'جلسة بدون اتصال — البيانات قد تكون غير محدثة',
              style: TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
