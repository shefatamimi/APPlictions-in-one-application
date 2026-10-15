/// # InquiryPage (Redesigned Version)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ideco_platform/injection_container.dart';
import 'package:ideco_platform/features/billing/screens/view_customer_bill_screen.dart';
import 'package:ideco_platform/features/inquiry/domain/entities/city_entity.dart';
import 'package:ideco_platform/features/inquiry/domain/entities/customer_info_entity.dart';
import 'package:ideco_platform/features/inquiry/presentation/cubit/inquiry_cubit.dart';
import 'package:ideco_platform/features/inquiry/presentation/cubit/inquiry_state.dart';
import 'package:ideco_platform/core/widgets/barcode_scanner_screen.dart';
import 'package:ideco_platform/platform/presentation/cubit/platform_auth_cubit.dart';
import 'package:ideco_platform/platform/presentation/cubit/platform_auth_state.dart';
import 'package:ideco_platform/features/direct_current/services/direct_current_service.dart';

enum InquiryMode {
  normal,
  inspectionMovements,
  meterRemoval,
  connectionMovements,
}

class InquiryPageArgs {
  final InquiryMode mode;
  final String? initialMeterNum;
  const InquiryPageArgs({
    this.mode = InquiryMode.normal,
    this.initialMeterNum,
  });
}

class InquiryPage extends StatelessWidget {
  const InquiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final pageArgs = args is InquiryPageArgs ? args : const InquiryPageArgs();
    return BlocProvider(
      create: (_) => sl<InquiryCubit>()..loadCities(),
      child: _InquiryView(
          mode: pageArgs.mode, initialMeterNum: pageArgs.initialMeterNum),
    );
  }
}

class _InquiryView extends StatefulWidget {
  const _InquiryView({required this.mode, this.initialMeterNum});
  final InquiryMode mode;
  final String? initialMeterNum;

  @override
  State<_InquiryView> createState() => _InquiryViewState();
}

class _InquiryViewState extends State<_InquiryView> {
  static const _primaryBlue = Color(0xFF0369A1);
  static const _accentBlue = Color(0xFF0EA5E9);
  static const _bgGray = Color(0xFFF8FAFC);
  static const _surfaceWhite = Colors.white;

  InquiryMode get _mode => widget.mode;

  final _cityNameCtrl = TextEditingController();
  final _cityCodeCtrl = TextEditingController();
  final _subSerial7Ctrl = TextEditingController();
  final _meterNumCtrl = TextEditingController();
  final _sub10Ctrl = TextEditingController();

  List<CityEntity> _filteredCities = [];
  List<CityEntity> _allCities = [];

  int _activeTab = 0;
  bool _hasResult = false;
  DateTime? _lastSearchTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialMeterNum != null && widget.initialMeterNum!.isNotEmpty) {
      _meterNumCtrl.text = widget.initialMeterNum!;
    }
  }

  @override
  void dispose() {
    _cityNameCtrl.dispose();
    _cityCodeCtrl.dispose();
    _subSerial7Ctrl.dispose();
    _meterNumCtrl.dispose();
    _sub10Ctrl.dispose();
    super.dispose();
  }

  void _onCityNameChanged(String value, List<CityEntity> cities) {
    setState(() {
      _filteredCities = cities
          .where((c) => c.name.contains(value) || c.code.startsWith(value))
          .take(10)
          .toList();
    });
  }

  void _selectCity(CityEntity city) {
    _cityNameCtrl.text = city.name;
    _cityCodeCtrl.text = city.code;
    setState(() => _filteredCities = []);
    FocusScope.of(context).unfocus();
  }

  void _onSearch(BuildContext ctx) {
    final now = DateTime.now();
    if (_lastSearchTime != null && now.difference(_lastSearchTime!).inMilliseconds < 800) {
      return; // Debounce guard against multiple rapid triggers from barcode scanners
    }
    _lastSearchTime = now;

    final cubit = ctx.read<InquiryCubit>();
    if (cubit.state is InquiryLoading) return;

    final cityCode = _cityCodeCtrl.text.trim();
    final subSerial = _subSerial7Ctrl.text.trim();
    final meterNum = _meterNumCtrl.text.trim();
    final sub10 = _sub10Ctrl.text.trim().replaceAll(RegExp(r'\s+'), '');

    if (sub10.isNotEmpty) {
      cubit.searchBy10Digit(sub10);
    } else if (meterNum.isNotEmpty) {
      cubit.searchByMeter(meterNum.trim());
    } else if (cityCode.isNotEmpty && subSerial.isNotEmpty) {
      cubit.searchBySubscription(cityCode, subSerial);
    } else {
      _showSimpleSnack(ctx, 'الرجاء إدخال بيانات البحث', Colors.orange);
    }
  }

  Future<void> _openCameraScanner(TextEditingController targetCtrl) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      targetCtrl.text = result;
      _onSearch(context);
    }
  }

  void _onClear(BuildContext ctx) {
    _cityNameCtrl.clear();
    _cityCodeCtrl.clear();
    _subSerial7Ctrl.clear();
    _meterNumCtrl.clear();
    _sub10Ctrl.clear();
    setState(() => _hasResult = false);
    ctx.read<InquiryCubit>().clearSearch();
  }

  void _showSimpleSnack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'AdFont')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (!mounted) return;
      _showSimpleSnack(context, 'تعذر إجراء المكالمة', Colors.red);
    }
  }

  Future<void> _openMap(String? lat, String? lng) async {
    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty || lat == '-1' || lng == '-1') {
      _showSimpleSnack(context, 'الإحداثيات غير متوفرة', Colors.orange);
      return;
    }
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSimpleSnack(context, 'تعذر فتح الخريطة', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return BlocConsumer<InquiryCubit, InquiryState>(
      listener: (ctx, state) {
        if (state is InquiryLoaded) setState(() => _hasResult = true);
        if (state is InquiryFailure) {
          _showSimpleSnack(ctx, state.message, Colors.red.shade700);
        }
        if (state is CitiesLoaded || state is InquiryLoaded) {
          _allCities = state is CitiesLoaded
              ? state.cities
              : (state as InquiryLoaded).cities;
        }
      },
      builder: (ctx, state) {
        final isLoading = state is InquiryLoading;
        final customer = state is InquiryLoaded ? state.customer : null;

        return Scaffold(
          backgroundColor: _bgGray,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              _buildHeader(ctx),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  child: Column(
                    children: [
                      if (!_hasResult) ...[
                        const SizedBox(height: 20),
                        _buildSearchTabs(),
                        const SizedBox(height: 16),
                        _buildSearchForm(ctx, isLoading),
                      ],
                      _buildResultsSection(ctx, state, customer, isLoading),
                      const SizedBox(height: 24),
                      _buildActionButtons(ctx, state),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext ctx) {
    final title = switch (_mode) {
      InquiryMode.normal => 'معلومات الإشتراك',
      InquiryMode.inspectionMovements => 'حركات التفتيش',
      InquiryMode.meterRemoval => 'معاملة خلع عداد',
      InquiryMode.connectionMovements => 'فصل و وصل',
    };

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentBlue, _primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerIconBtn(Icons.settings_outlined,
                      () => _showSimpleSnack(ctx, 'قيد التطوير', _primaryBlue)),
                  const Text(
                    'شركة كهرباء إربد',
                    style: TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 14,
                        color: Colors.white70),
                  ),
                  _headerIconBtn(Icons.arrow_back_ios_new_rounded,
                      () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'AdFont',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
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

  Widget _headerIconBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSearchTabs() {
    final tabs = [
      (icon: Icons.qr_code_scanner_rounded, label: 'رقم الاشتراك'),
      (icon: Icons.qr_code_rounded, label: 'رقم العداد'),
      (icon: Icons.manage_search_rounded, label: 'بحث متقدم'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isActive = _activeTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? _primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(tabs[i].icon,
                          color: isActive ? Colors.white : Colors.blueGrey,
                          size: 20),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontFamily: 'AdFont',
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.white : Colors.blueGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSearchForm(BuildContext ctx, bool disabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            if (_activeTab == 0)
              _modernInput(
                controller: _sub10Ctrl,
                hint: 'أدخل رقم الاشتراك',
                enabled: !disabled,
                type: TextInputType.number,
                maxLength: 10,
                icon: Icons.badge_outlined,
                suffixIcon: Icons.search_rounded,
                onSuffixTap: () => _onSearch(ctx),
                action: TextInputAction.search,
                onSubmitted: (_) => _onSearch(ctx),
              ),
            if (_activeTab == 1)
              _modernInput(
                controller: _meterNumCtrl,
                hint: 'امسح الباركود أو أدخل رقم العداد',
                enabled: !disabled,
                type: TextInputType.text,
                maxLength: 25,
                icon: Icons.qr_code_scanner_rounded,
                customSuffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: _primaryBlue, size: 22),
                      tooltip: 'مسح الباركود بالكاميرا',
                      onPressed: () => _openCameraScanner(_meterNumCtrl),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: _primaryBlue, size: 22),
                      tooltip: 'بحث',
                      onPressed: () => _onSearch(ctx),
                    ),
                  ],
                ),
                action: TextInputAction.search,
                onSubmitted: (_) => _onSearch(ctx),
              ),
            if (_activeTab == 2) ...[
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _modernInput(
                      controller: _cityCodeCtrl,
                      hint: 'الرمز',
                      enabled: !disabled,
                      type: TextInputType.number,
                      maxLength: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildCityAutocomplete(disabled)),
                ],
              ),
              const SizedBox(height: 12),
              _modernInput(
                controller: _subSerial7Ctrl,
                hint: 'رقم الإشتراك (7 خانات)',
                enabled: !disabled,
                type: TextInputType.number,
                maxLength: 7,
                icon: Icons.numbers_rounded,
                suffixIcon: Icons.search_rounded,
                onSuffixTap: () => _onSearch(ctx),
                action: TextInputAction.search,
                onSubmitted: (_) => _onSearch(ctx),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCityAutocomplete(bool disabled) {
    return Column(
      children: [
        _modernInput(
          controller: _cityNameCtrl,
          hint: 'إسم البلدة',
          enabled: !disabled,
          onChanged: (v) => _onCityNameChanged(v, _allCities),
          icon: Icons.location_city_rounded,
        ),
        if (_filteredCities.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.2)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredCities.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = _filteredCities[i];
                return ListTile(
                  title: Text(c.name,
                      style:
                          const TextStyle(fontFamily: 'AdFont', fontSize: 14)),
                  trailing: Text(c.code,
                      style: TextStyle(
                          color: _primaryBlue.withValues(alpha: 0.6))),
                  onTap: () => _selectCity(c),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildResultsSection(BuildContext ctx, InquiryState state,
      CustomerInfoEntity? customer, bool isLoading) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Text('نتائج البحث',
                  style: TextStyle(
                      fontFamily: 'AdFont',
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Spacer(),
              if (_hasResult)
                TextButton(
                  onPressed: () => _onClear(ctx),
                  child: const Text('مسح النتائج',
                      style: TextStyle(
                          fontFamily: 'AdFont', color: Colors.blueGrey)),
                ),
            ],
          ),
        ),
        if (isLoading)
          const Padding(
              padding: EdgeInsets.all(40), child: CircularProgressIndicator())
        else if (customer != null)
          _buildResultCard(ctx, customer)
        else if (!_hasResult)
          Opacity(
            opacity: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('لم يتم البحث بعد',
                      style: TextStyle(fontFamily: 'AdFont')),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext ctx, CustomerInfoEntity c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.hasIllegalNotification)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'تنبيه: يوجد بلاغ نشط لهذا الاشتراك',
                  style: TextStyle(
                    fontFamily: 'AdFont',
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Barcode & 10-digit subscription banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                borderRadius: c.hasIllegalNotification 
                    ? BorderRadius.zero 
                    : const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, color: _primaryBlue, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'باركود: ${c.formattedSubscription}',
                            style: const TextStyle(
                              fontFamily: 'AdFont',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.meterStatus.toLowerCase().contains('disconn') 
                          ? Colors.red.shade50 
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: c.meterStatus.toLowerCase().contains('disconn') 
                            ? Colors.red.shade200 
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      c.meterStatus.isEmpty ? 'Connected' : c.meterStatus,
                      style: TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: c.meterStatus.toLowerCase().contains('disconn') 
                            ? Colors.red.shade800 
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.customerName,
                    style: const TextStyle(
                      fontFamily: 'AdFont',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.townThenSubscription,
                    style: TextStyle(
                      fontFamily: 'AdFont',
                      fontSize: 13.5,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _simpleRow('البلدة', c.cityName),
                  _simpleRow('رقم العداد', c.meterSerialNum),
                  _simpleRow('نوع العداد', c.isSmart ? 'ذكـي' : 'عادي'),
                  _simpleRow('الفاز', c.phase),
                  _simpleRow('حمل الاشتراك (Load Profile)', c.loadProfile.isNotEmpty ? c.loadProfile : '---'),
                  _simpleRow('العنوان', c.address),
                  if (c.subscriptionType.isNotEmpty)
                    _simpleRow('نوع الاشتراك', c.subscriptionType),
                  
                  // Phone with call button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            'هاتف الدعم:',
                            style: TextStyle(fontFamily: 'AdFont', fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            c.supportPhone.isNotEmpty ? c.supportPhone : '---',
                            style: const TextStyle(fontFamily: 'AdFont', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        IconButton(
                          onPressed: c.supportPhone.isNotEmpty ? () => _makePhoneCall(c.supportPhone) : null,
                          icon: Icon(Icons.phone_rounded, color: c.supportPhone.isNotEmpty ? Colors.green : Colors.grey.shade400, size: 20),
                          tooltip: 'اتصال',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  _simpleRow('مقدم الدعم', c.supportProviderName.isNotEmpty ? c.supportProviderName : '---'),

                  if (c.readerName.isNotEmpty)
                    _simpleRow('القارئ', c.readerName),

                  if (c.lastReading.isNotEmpty)
                    _simpleRow('آخر قراءة', c.lastReading),

                  if (c.lastReadingDate.isNotEmpty)
                    _simpleRow('تاريخ آخر قراءة', c.lastReadingDate),

                  _simpleRow('آخر معاملة تفتيش', c.lastInspectionDate.isNotEmpty ? c.lastInspectionDate : '---'),

                  if (c.lastVisitDate.isNotEmpty)
                    _simpleRow('تاريخ آخر زيارة', c.lastVisitDate),

                  _simpleRow('حمل العداد الذكي', c.loadProfile.isNotEmpty ? c.loadProfile : '---'),

                  if (c.hasLocation)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              'موقع الاشتراك:',
                              style: TextStyle(fontFamily: 'AdFont', fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'X: ${c.posX}, Y: ${c.posY}',
                              style: const TextStyle(fontFamily: 'AdFont', fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openMap(c.posY, c.posX),
                            icon: const Icon(Icons.map_rounded, size: 16, color: _accentBlue),
                            label: const Text('الخريطة', style: TextStyle(fontFamily: 'AdFont', fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) => ViewCustomerBillScreen(
                              meterInfo: {
                                'MTR_CITY': c.cityCode,
                                'MTR_NUM': c.subscriptionSerial,
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: Text(
                        'فواتير المشترك ${c.hasLocation ? '(مع الإحداثيات)' : ''}',
                        style: const TextStyle(
                            fontFamily: 'AdFont',
                            fontWeight: FontWeight.bold,
                            color: _accentBlue),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _accentBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontFamily: 'AdFont',
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontFamily: 'AdFont',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext ctx, InquiryState state) {
    final m = _mode;
    final customer = state is InquiryLoaded ? state.customer : null;
    final isEnabled = customer != null;

    // وضعية خلع العداد
    if (m == InquiryMode.meterRemoval) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(color: Colors.white),
        child: _bigBtn(
            'إدخال معاملة الخلع', Icons.remove_circle_outline, isEnabled, () {
          Navigator.of(ctx).pushNamed('/meter-remove', arguments: customer);
        }),
      );
    }

    // وضعية حركات التفتيش (التصميم الشبكي الجديد 2x2 + مزامنة)
    if (m == InquiryMode.inspectionMovements) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: [
                _gridActionBtn('إدخال زيارة', Icons.visibility_rounded,
                    isEnabled, const Color(0xFF0EA5E9), () {
                  Navigator.of(ctx)
                      .pushNamed('/inspection-movement', arguments: customer);
                }),
                _gridActionBtn('إدخال معاملة التفتيش', Icons.assignment_rounded,
                    isEnabled, const Color(0xFF0369A1), () {
                  Navigator.of(ctx)
                      .pushNamed('/inspection-movement', arguments: customer);
                }),
                _gridActionBtn('حركة فصل', Icons.link_off,
                    isEnabled, const Color(0xFFE11D48), () {
                  _handleDisconnectionTransaction(ctx, customer);
                }),
                _gridActionBtn('إدخال تقرير تنفيذ', Icons.assignment_turned_in_rounded,
                    isEnabled, const Color(0xFF7C3AED), () {
                  _showSimpleSnack(ctx, 'قيد التطوير', const Color(0xFF7C3AED));
                }),
              ],
            ),
            const SizedBox(height: 12),
            _bigBtn('مزامنة البيانات', Icons.sync_rounded, true, () {
              Navigator.of(ctx).pushNamed('/sync');
            }, color: const Color(0xFF475569)),
          ],
        ),
      );
    }

    // الوضع الطبيعي أو وضعية "فصل و وصل" من الرئيسية
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m == InquiryMode.normal ||
              m == InquiryMode.connectionMovements) ...[
            Row(
              children: [
                Expanded(
                    child: _actionBtn('حركة وصل', Icons.link, isEnabled, () {
                  _handleConnectionTransaction(ctx, customer);
                })),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        _actionBtn('حركة فصل', Icons.link_off, isEnabled, () {
                  _handleDisconnectionTransaction(ctx, customer);
                })),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleConnectionTransaction(
      BuildContext ctx, CustomerInfoEntity? customer) async {
    // 1. فحص وجود رقم المستخدم و الورشة
    final authState = ctx.read<PlatformAuthCubit>().state;
    if (authState is! PlatformAuthAuthenticated) {
      _showSimpleSnack(ctx, 'يرجى تسجيل الدخول أولاً', Colors.red);
      return;
    }
    final employee = authState.session.employee;

    if (employee.oracleUser.trim().isEmpty || employee.oracleUser.trim() == '0') {
      _showSimpleSnack(ctx, 'لا يوجد رقم مستخدم لغايات الفصل و الوصل', Colors.orange);
      return;
    }

    if (employee.workshopNumber.trim().isEmpty) {
      _showSimpleSnack(ctx, 'لا يوجد رقم ورشة', Colors.orange);
      return;
    }

    if (customer == null || customer.meterSerialNum.trim().isEmpty) {
      _showSimpleSnack(ctx, 'يرجى الإستعلام عن عداد أولاً', Colors.orange);
      return;
    }

    // 2. إظهار مؤشر الانتظار
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('يرجى الإنتظار...', style: TextStyle(fontFamily: 'AdFont')),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final lat = double.tryParse(customer.posX ?? '0') ?? 0.0;
      final lng = double.tryParse(customer.posY ?? '0') ?? 0.0;

      final workshopId = employee.systemMinor.isNotEmpty
          ? employee.systemMinor
          : employee.workshopNumber;
      final workshopName = employee.workshopName.isNotEmpty
          ? employee.workshopName
          : employee.displayName;

      final responseMessage = await DirectCurrentService.connTrans(
        meterNum: customer.meterSerialNum,
        workshopId: workshopId,
        workshopName: workshopName,
        userName: employee.oracleUser,
        cityId: customer.cityCode,
        custId: customer.subscriptionSerial,
        lat: lat,
        lng: lng,
      );

      if (ctx.mounted) {
        Navigator.of(ctx).pop(); // إغلاق نافذة الإنتظار

        showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('نتيجة حركة الوصل', style: TextStyle(fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
            content: Text(responseMessage, style: const TextStyle(fontFamily: 'AdFont')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً', style: TextStyle(fontFamily: 'AdFont')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        Navigator.of(ctx).pop(); // إغلاق نافذة الإنتظار
        _showSimpleSnack(ctx, 'حدث خطأ بالإتصال يرجى التأكد من الشبكة وإعادة المحاولة', Colors.red);
      }
    }
  }

  Future<void> _handleDisconnectionTransaction(
      BuildContext ctx, CustomerInfoEntity? customer) async {
    // 1. فحص وجود رقم المستخدم والورشة
    final authState = ctx.read<PlatformAuthCubit>().state;
    if (authState is! PlatformAuthAuthenticated) {
      _showSimpleSnack(ctx, 'يرجى تسجيل الدخول أولاً', Colors.red);
      return;
    }
    final employee = authState.session.employee;

    if (employee.oracleUser.trim().isEmpty || employee.oracleUser.trim() == '0') {
      _showSimpleSnack(ctx, 'لا يوجد رقم مستخدم لغايات الفصل و الوصل', Colors.orange);
      return;
    }

    if (employee.workshopNumber.trim().isEmpty) {
      _showSimpleSnack(ctx, 'لا يوجد رقم ورشة', Colors.orange);
      return;
    }

    if (customer == null || customer.meterSerialNum.trim().isEmpty) {
      _showSimpleSnack(ctx, 'يرجى الإستعلام عن عداد أولا', Colors.orange);
      return;
    }

    // 2. إظهار نافذة إدخال ملاحظات سبب الفصل (dialog_discon_operation)
    final notesController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link_off, color: Colors.red),
            SizedBox(width: 8),
            Text('إدخال حركة فصل',
                style: TextStyle(
                    fontFamily: 'AdFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يرجى إدخال ملاحظات أو سبب الفصل:',
              style: TextStyle(fontFamily: 'AdFont', fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'أدخل الملاحظات هنا...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'AdFont')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('إرسال حركة الفصل',
                style: TextStyle(fontFamily: 'AdFont', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 3. إظهار نافذة جاري الإنتظار
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('يرجى الإنتظار...', style: TextStyle(fontFamily: 'AdFont')),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final lat = double.tryParse(customer.posX ?? '0') ?? 0.0;
      final lng = double.tryParse(customer.posY ?? '0') ?? 0.0;

      final workshopId = employee.systemMinor.isNotEmpty
          ? employee.systemMinor
          : employee.workshopNumber;
      final workshopName = employee.workshopName.isNotEmpty
          ? employee.workshopName
          : employee.displayName;

      final responseMessage = await DirectCurrentService.disConnTrans(
        meterNum: customer.meterSerialNum,
        workshopId: workshopId,
        workshopName: workshopName,
        userName: employee.oracleUser,
        cityId: customer.cityCode,
        custId: customer.subscriptionSerial,
        kind: '0',
        reason: '14',
        notes: notesController.text.trim(),
        lat: lat,
        lng: lng,
      );

      if (ctx.mounted) {
        Navigator.of(ctx).pop(); // إغلاق نافذة الإنتظار

        showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('نتيجة حركة الفصل',
                style: TextStyle(fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
            content: Text(responseMessage, style: const TextStyle(fontFamily: 'AdFont')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً', style: TextStyle(fontFamily: 'AdFont')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        Navigator.of(ctx).pop(); // إغلاق نافذة الإنتظار
        _showSimpleSnack(
            ctx,
            'لم تتم عملية الإرسال لحركة الفصل, يرجى المحاولة مجددا',
            Colors.red);
      }
    }
  }

  Widget _gridActionBtn(String label, IconData icon, bool isEnabled,
      Color color, VoidCallback onTap) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, bool isEnabled, VoidCallback onTap) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: OutlinedButton.icon(
        onPressed: isEnabled ? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(
                fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlue,
          side: const BorderSide(color: _primaryBlue),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _bigBtn(
      String label, IconData icon, bool isEnabled, VoidCallback onTap,
      {Color? color}) {
    final btnColor = color ?? _primaryBlue;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: isEnabled ? onTap : null,
          icon: Icon(icon, color: Colors.white, size: 22),
          label: Text(label,
              style: const TextStyle(
                  fontFamily: 'AdFont',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _modernInput({
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    TextInputType type = TextInputType.text,
    int? maxLength,
    IconData? icon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    Widget? customSuffix,
    TextInputAction? action,
    void Function(String)? onSubmitted,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: type,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: action,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.blueGrey.shade200,
            fontSize: 14,
            fontFamily: 'AdFont'),
        prefixIcon:
            icon != null ? Icon(icon, color: _primaryBlue, size: 20) : null,
        suffixIcon: customSuffix ??
            (suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, color: _primaryBlue, size: 22),
                    onPressed: onSuffixTap,
                  )
                : null),
        counterText: '',
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
      ),
    );
  }
}
