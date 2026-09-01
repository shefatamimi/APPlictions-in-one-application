/// # App dialogs
///
/// Shared, RTL-correct feedback dialogs. Modules use these instead of rolling
/// their own so a message looks the same wherever in the platform it appears.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ## showAppMessage
///
/// **Description**: Modal acknowledgement dialog (the platform's replacement
/// for the modules' ad-hoc `showInfoDialog`).
///
/// **Parameters**:
/// - [message] — Arabic body text.
/// - [title] — optional heading.
/// - [isError] — paints the icon in the danger colour.
///
/// **Returns**: a future that completes when the dialog is dismissed.
Future<void> showAppMessage(
  BuildContext context, {
  required String message,
  String? title,
  bool isError = false,
}) {
  final color = isError ? AppColors.danger : AppColors.primary;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: color,
            size: 28,
          ),
        ),
        title: title == null ? null : Text(title, textAlign: TextAlign.center),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(dialogContext).textTheme.bodyLarge,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('حسناً'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// ## showAppConfirm
///
/// **Description**: Two-choice confirmation dialog, used for logout and other
/// irreversible actions.
///
/// **Returns**: `true` when the user confirms, `false`/`null` otherwise.
Future<bool?> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  bool isDestructive = false,
}) {
  final color = isDestructive ? AppColors.danger : AppColors.primary;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDestructive ? Icons.logout_rounded : Icons.help_outline_rounded,
            color: color,
            size: 26,
          ),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(dialogContext).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(120, 44),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}

/// ## showAppLoader
///
/// **Description**: Blocking progress overlay for a long SOAP round trip.
/// Dismiss it with `Navigator.of(context).pop()`.
void showAppLoader(BuildContext context,
    {String message = 'يرجى الانتظار...'}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.xxl,
            vertical: AppDimens.xl,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: AppDimens.lg),
              Text(message, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Floating snack bar with the platform's styling.
void showAppSnack(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: isError ? AppColors.danger : AppColors.primaryDark,
        margin: const EdgeInsets.all(AppDimens.lg),
      ),
    );
}
