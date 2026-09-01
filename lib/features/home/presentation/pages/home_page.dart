/// # HomePage
///
/// Dashboard of the **field inspection** application, hosted by the platform.
///
/// It is reached from the platform home screen, so it no longer owns the
/// session: the employee arrives already authenticated (via
/// `buildInspectionModule`), the back button returns to the application grid,
/// and signing out is the shell's responsibility.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../platform/domain/entities/employee.dart';
import '../../../../features/inquiry/presentation/pages/inquiry_page.dart';
import '../../../../features/submission/presentation/pages/submission_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.user});

  /// Employee resolved by the platform. When `null` the page falls back to the
  /// route argument, which keeps the legacy `/home` route working.
  final Employee? user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Brand colours (platform palette) ───────────────────────────────────────
  static const _primary = AppColors.primary;
  static const _darkBlue = AppColors.primaryDark;
  static const _bgColor = AppColors.background;

  /// Used when neither the constructor nor the route supplied an employee.
  static const _unknownUser = Employee(
    id: '',
    employeeNumber: '',
    username: '',
    fullName: '',
    department: '',
    workshopName: '',
    workshopNumber: '',
    oracleUser: '',
    systemMinor: '',
  );

  Employee _user = _unknownUser;

  @override
  void initState() {
    super.initState();
    // شريط الحالة
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fromWidget = widget.user;
    if (fromWidget != null) {
      _user = fromWidget;
      return;
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Employee) _user = args;
  }

  /// Returns to the platform application grid.
  void _backToPlatform() => Navigator.of(context).maybePop();

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'AdFont'),
          textDirection: TextDirection.rtl),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _darkBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildFeatureGrid(),
                    const SizedBox(height: 20),
                    _buildBottomActions(),
                    const SizedBox(height: 30),
                    _buildVersionText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _darkBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _backToPlatform,
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white),
                    tooltip: 'رجوع إلى التطبيقات',
                  ),
                  const Text(
                    'التفتيش الميداني',
                    style: TextStyle(
                      fontFamily: 'AdFont',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _snack('الإعدادات قيد التطوير'),
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/images/logo3.png'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'شركة كهرباء محافظة إربد',
                style: TextStyle(
                  fontFamily: 'AdFont',
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    // عرض اسم الموظف من fullName (الاسم الكامل) أو username كاحتياط
    final name = _user.displayName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: _primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'AdFont',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الرقم الوظيفي: ${_user.employeeNumber}',
                  style: const TextStyle(
                    fontFamily: 'AdFont',
                    fontSize: 13,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'نشط',
                  style: TextStyle(
                    fontFamily: 'AdFont',
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Feature grid ───────────────────────────────────────────────────────────

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(
        label: 'إستعلام بلاغات',
        icon: Icons.search_rounded,
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.of(context).pushNamed('/submission',
            arguments: SubmissionPageArgs(_user.workshopNumber)),
      ),
      _FeatureItem(
        label: 'حركات التفتيش',
        icon: Icons.engineering_rounded,
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.of(context).pushNamed('/inquiry',
            arguments:
                const InquiryPageArgs(mode: InquiryMode.inspectionMovements)),
      ),
      _FeatureItem(
        label: 'تنفيذ تفتيش',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF10B981),
        onTap: () => Navigator.of(context).pushNamed('/inspection-inquiry'),
      ),
      _FeatureItem(
        label: 'فصل و وصل',
        icon: Icons.electrical_services_rounded,
        color: const Color(0xFF3B82F6),
        onTap: () => Navigator.of(context).pushNamed('/inquiry',
            arguments:
                const InquiryPageArgs(mode: InquiryMode.connectionMovements)),
      ),
      _FeatureItem(
        label: 'خلع عداد',
        icon: Icons.remove_circle_rounded,
        color: const Color(0xFFEF4444),
        onTap: () => Navigator.of(context).pushNamed('/inquiry',
            arguments: const InquiryPageArgs(mode: InquiryMode.meterRemoval)),
      ),
      _FeatureItem(
        label: 'معاملات التفتيش',
        icon: Icons.list_alt_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => _snack('قيد التطوير'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          elevation: 0,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'AdFont',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Bottom action tiles ────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Column(
      children: [
        // Signing out belongs to the platform shell, so the module only offers
        // a way back to the application grid.
        _bottomButton(
          label: 'رجوع إلى التطبيقات',
          icon: Icons.apps_rounded,
          color: _darkBlue,
          onTap: _backToPlatform,
        ),
      ],
    );
  }

  Widget _bottomButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'AdFont',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Version text ───────────────────────────────────────────────────────────

  Widget _buildVersionText() {
    return const Text(
      'إصدار v1.0.0',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'AdFont',
        fontSize: 12,
        color: Colors.blueGrey,
      ),
    );
  }
}

class _FeatureItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
