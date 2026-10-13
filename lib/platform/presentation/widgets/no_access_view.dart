/// # NoAccessView
///
/// Shown when the employee is authenticated but the server granted no
/// application — a real situation on a shared account whose permissions were
/// revoked. Better an explicit message than an empty grid.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

class NoAccessView extends StatelessWidget {
  const NoAccessView({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 42, color: AppColors.danger),
            ),
            const SizedBox(height: AppDimens.xl),
            Text(
              'لا توجد تطبيقات متاحة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.sm),
            Text(
              'تم التحقق من حسابك، لكن لم يتم منحك صلاحية الدخول إلى أي تطبيق.\n'
              'يرجى مراجعة قسم الحاسوب لتحديث الصلاحيات.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimens.xxl),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('تسجيل الخروج'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
