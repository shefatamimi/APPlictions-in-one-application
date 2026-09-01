/// # NotificationsPage
///
/// Destination of the header's notification button.
///
/// The shared service exposes no notification operation today, so this screen
/// deliberately shows an honest empty state instead of sample data. When a
/// notifications endpoint exists, this is the only file that has to change:
/// replace the empty state with the list, and feed
/// `DashboardHeader.notificationCount` from the same source.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimens.xl),
              Text(
                'لا توجد إشعارات',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                'سيتم عرض إشعارات التطبيقات هنا عند تفعيل خدمة الإشعارات على الخادم.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
