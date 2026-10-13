/// # LoginPage
///
/// The platform's **only** login screen.
///
/// One submission authenticates the employee and resolves, in the same step,
/// which applications the server authorises — the employee never sees a second
/// credential prompt, whichever application they open afterwards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../cubit/platform_auth_cubit.dart';
import '../cubit/platform_auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialUsername = ''});

  /// Username of the previous session, pre-filled for convenience.
  final String initialUsername;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController =
      TextEditingController(text: widget.initialUsername);
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<PlatformAuthCubit>().signIn(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlatformAuthCubit, PlatformAuthState>(
      listenWhen: (_, current) => current is PlatformAuthFailed,
      listener: (context, state) async {
        if (state is! PlatformAuthFailed) return;
        _passwordController.clear();
        await showAppMessage(
          context,
          title: 'تعذر تسجيل الدخول',
          message: state.message,
          isError: true,
        );
        if (context.mounted) context.read<PlatformAuthCubit>().clearError();
      },
      builder: (context, state) {
        final isBusy = state is PlatformAuthAuthenticating;

        return Scaffold(
          body: Stack(
            children: [
              _buildBackdrop(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.pagePadding(context),
                      vertical: AppDimens.xxl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: FadeSlideIn(
                        offset: 24,
                        child: Column(
                          children: [
                            _buildBrand(),
                            const SizedBox(height: AppDimens.xxxl),
                            _buildFormCard(isBusy),
                            const SizedBox(height: AppDimens.xl),
                            Text(
                              'الإصدار ${AppConstants.platformVersion}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Brand gradient behind the top third of the screen.
  Widget _buildBackdrop() {
    return Column(
      children: [
        Container(
          height: MediaQuery.sizeOf(context).height * 0.38,
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(AppDimens.huge),
              bottomRight: Radius.circular(AppDimens.huge),
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo3.png',
            width: 74,
            height: 74,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppDimens.lg),
        const Text(
          AppConstants.companyNameAr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppDimens.xs),
        Text(
          AppConstants.platformNameAr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isBusy) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimens.xxl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تسجيل الدخول',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.xs),
            Text(
              AppConstants.platformTaglineAr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimens.xxl),
            TextFormField(
              controller: _usernameController,
              enabled: !isBusy,
              textAlign: TextAlign.right,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'يرجى إدخال اسم المستخدم'
                  : null,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !isBusy,
              obscureText: _obscurePassword,
              textAlign: TextAlign.right,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'يرجى إدخال كلمة المرور'
                  : null,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.primary),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'إظهار' : 'إخفاء',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.xxl),
            ElevatedButton(
              onPressed: isBusy ? null : _submit,
              child: isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('دخول'),
            ),
            const SizedBox(height: AppDimens.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: AppDimens.xs),
                Flexible(
                  child: Text(
                    'يتم تحديد التطبيقات المتاحة حسب صلاحياتك',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
