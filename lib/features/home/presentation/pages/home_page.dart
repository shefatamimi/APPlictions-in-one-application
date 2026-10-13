/// # HomePage
///
/// Dashboard of the **field inspection** application, hosted by the platform.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../platform/domain/entities/employee.dart';
import '../../../../features/inquiry/presentation/pages/inquiry_page.dart';
import '../../../../features/submission/presentation/pages/submission_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.user});

  final Employee? user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _primary = AppColors.primary;
  static const _darkBlue = AppColors.primaryDark;
  static const _bgColor = Color(0xFFF1F5F9);

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

  void _backToPlatform() => Navigator.of(context).maybePop();

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'AdFont'),
          textDirection: TextDirection.rtl),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _darkBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: _buildProfileCard(),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('الخدمات والعمليات الميدانية', Icons.grid_view_rounded),
                    const SizedBox(height: 4),
                    _buildFeatureGrid(),
                    const SizedBox(height: 24),
                    _buildBottomActions(),
                    const SizedBox(height: 20),
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

  Widget _buildHeader() {
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset('assets/images/logo3.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التفتيش الميداني',
                      style: TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'شركة كهرباء محافظة إربد',
                      style: TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _snack('الإعدادات قيد التطوير'),
                tooltip: 'الإعدادات',
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _backToPlatform,
                tooltip: 'رجوع إلى التطبيقات',
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = _user.displayName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF0284C7), size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'موظف ميداني' : name,
                  style: const TextStyle(
                    fontFamily: 'AdFont',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Text(
                      'الرقم الوظيفي: ${_user.employeeNumber.isEmpty ? "—" : _user.employeeNumber}',
                      style: const TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 12,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.green.shade200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
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
                    color: Colors.green.shade800,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'AdFont',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    const cardBg = Colors.white;

    final features = [
      _FeatureItem(
        label: 'إستعلام بلاغات',
        subtitle: 'بحث ومتابعة البلاغات',
        icon: Icons.search_rounded,
        color: const Color(0xFF0284C7),
        onTap: () => Navigator.of(context).pushNamed('/submission',
            arguments: SubmissionPageArgs(_user.workshopNumber)),
      ),
      _FeatureItem(
        label: 'حركات التفتيش',
        subtitle: 'سجل الحركات السابقة',
        icon: Icons.engineering_rounded,
        color: const Color(0xFFD97706),
        onTap: () => Navigator.of(context).pushNamed('/inquiry',
            arguments:
                const InquiryPageArgs(mode: InquiryMode.inspectionMovements)),
      ),
      _FeatureItem(
        label: 'تنفيذ تفتيش',
        subtitle: 'إدخال ملاحظة وحفظ',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF059669),
        onTap: () => Navigator.of(context).pushNamed('/inspection-inquiry'),
      ),
      _FeatureItem(
        label: 'فصل و وصل',
        subtitle: 'إدارة العدادات والاشتراكات',
        icon: Icons.electrical_services_rounded,
        color: const Color(0xFF4F46E5),
        onTap: () => Navigator.of(context).pushNamed('/inquiry',
            arguments:
                const InquiryPageArgs(mode: InquiryMode.connectionMovements)),
      ),
      _FeatureItem(
        label: 'خلع عداد',
        subtitle: 'إجراءات خلع العداد',
        icon: Icons.remove_circle_rounded,
        color: const Color(0xFFE11D48),
        onTap: () => Navigator.of(context).pushNamed('/inquiry',
            arguments: const InquiryPageArgs(mode: InquiryMode.meterRemoval)),
      ),
      _FeatureItem(
        label: 'معاملات التفتيش',
        subtitle: 'تقارير وقوائم',
        icon: Icons.list_alt_rounded,
        color: const Color(0xFF0891B2),
        onTap: () => _snack('قيد التطوير'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.25,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.color, size: 26),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: item.color.withValues(alpha: 0.6)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontFamily: 'AdFont',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontFamily: 'AdFont',
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _backToPlatform,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.apps_rounded, color: _darkBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'رجوع إلى قائمة التطبيقات',
                style: TextStyle(
                  fontFamily: 'AdFont',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _darkBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildVersionText() {
    return const Text(
      'إصدار التطبيق v2.0.0 — تفتيش ميداني',
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
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
