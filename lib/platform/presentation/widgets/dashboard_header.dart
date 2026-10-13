/// # DashboardHeader
///
/// Brand header of the home dashboard with prominent, larger font sizing.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';

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

  final String greeting;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final int notificationCount;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.pagePadding(context),
            16,
            Responsive.pagePadding(context),
            24,
          ),
          child: ContentBounds(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildLogo(wide ? 52 : 46),
                    const SizedBox(width: 14),
                    Expanded(child: _buildTitles(context)),
                    _buildNotificationsButton(),
                    const SizedBox(width: 6),
                    _buildIconButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'الإعدادات',
                      onPressed: onSettings,
                    ),
                    const SizedBox(width: 6),
                    _buildIconButton(
                      icon: Icons.logout_rounded,
                      tooltip: 'تسجيل الخروج',
                      onPressed: onLogout,
                    ),
                  ],
                ),
                if (isOffline) ...[
                  const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            fontSize: 13.5,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            AppConstants.companyNameAr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
                  fontSize: 10,
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
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildOfflineChip() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'جلسة بدون اتصال',
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
