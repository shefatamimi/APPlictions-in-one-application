import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ideco_platform/features/billing/services/billing_service.dart';
import 'package:ideco_platform/features/billing/models/billing_item.dart';
import 'package:ideco_platform/core/theme/app_colors.dart';
import 'package:ideco_platform/injection_container.dart';
import 'package:ideco_platform/features/inquiry/domain/usecases/search_by_meter_usecase.dart';
import 'package:ideco_platform/core/widgets/barcode_scanner_screen.dart';

class ViewCustomerBillScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const ViewCustomerBillScreen({super.key, required this.meterInfo});

  @override
  State<ViewCustomerBillScreen> createState() => _ViewCustomerBillScreenState();
}

class _ViewCustomerBillScreenState extends State<ViewCustomerBillScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BillingItem> _bills = [];
  bool _isLoading = false;
  double _sumRequired = 0.0;

  @override
  void initState() {
    super.initState();
    final cityId = widget.meterInfo['MTR_CITY'] ?? "";
    final subNum = widget.meterInfo['MTR_NUM'] ?? "";
    if (cityId.isNotEmpty && subNum.isNotEmpty) {
      _searchCtrl.text = cityId.padLeft(3, '0') + subNum.padLeft(7, '0');
    } else if (subNum.isNotEmpty) {
      _searchCtrl.text = subNum;
    }

    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _fetchBills();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCameraScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      _searchCtrl.text = result;
      _performSearch(result);
    }
  }

  Future<void> _fetchBills() async {
    final cityId = widget.meterInfo['MTR_CITY'] ?? "";
    final subNum = widget.meterInfo['MTR_NUM'] ?? "";
    if (cityId.isNotEmpty || subNum.isNotEmpty) {
      await _performSearch(_searchCtrl.text.isNotEmpty ? _searchCtrl.text : '$cityId$subNum');
    }
  }

  Future<void> _performSearch(String query) async {
    final s = query.trim().replaceAll(RegExp(r'\s+'), '');
    if (s.isEmpty) return;

    setState(() => _isLoading = true);

    List<BillingItem> results = [];

    // إذا كان المدخل 10 خانات أو أكثر (بار كود أو رقم اشتراك كامل)
    if (s.length >= 10) {
      final clean10 = s.length > 10 ? s.substring(s.length - 10) : s;
      final cityId = clean10.substring(0, 3);
      final subNum = clean10.substring(3);
      results = await BillingService.getMeterInvoices(cityId, subNum);
    } else {
      // بحث من خلال رقم العداد (أقل من 10 خانات)
      try {
        final searchByMeter = sl<SearchByMeterUseCase>();
        final res = await searchByMeter(s);
        await res.fold(
          (failure) async {
            results = await BillingService.getMeterInvoices("", s);
          },
          (customer) async {
            results = await BillingService.getMeterInvoices(
              customer.cityCode,
              customer.subscriptionSerial,
            );
          },
        );
      } catch (_) {
        results = await BillingService.getMeterInvoices("", s);
      }
    }

    double sum = 0.0;
    for (var bill in results) {
      if (bill.payFlag == "0") {
        double remain = double.tryParse(bill.bilRemain) ?? 0.0;
        sum += remain;
        sum = double.parse(sum.toStringAsFixed(3));
      }
    }

    if (mounted) {
      setState(() {
        _bills = results;
        _sumRequired = sum;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            // --- Header (Logo + Title) ---
            _buildHeader(),

            // --- Search Bar (رقم العداد أو الباركود) ---
            _buildSearchBar(),

            // --- Summary Bar (المطلوب) ---
            if (!_isLoading) _buildSummaryBar(),

            // --- Expandable List ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                  : _bills.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _bills.length,
                          itemBuilder: (ctx, index) => _buildExpandableBillCard(_bills[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (val) => _performSearch(val),
        decoration: InputDecoration(
          hintText: 'البحث برقم العداد أو الباركود...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                ),
              IconButton(
                icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
                tooltip: 'مسح الباركود بالكاميرا',
                onPressed: _openCameraScanner,
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                tooltip: 'بحث',
                onPressed: () => _performSearch(_searchCtrl.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: AppColors.success.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'لا توجد فواتير مستحقة حالياً',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'تم تسديد كافة الذمم المطلوبة أو لم يتم العثور على فواتير',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              // Circular Logo
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/images/images.jpg', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'إستعراض الفواتير',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.primaryLight.withValues(alpha: 0.9)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'المجموع المطلوب: ',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: '$_sumRequired دينار',
                style: const TextStyle(
                  color: Color(0xFF06F106),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableBillCard(BillingItem bill) {
    bool isUnpaid = bill.payFlag == "0";
    String payStatusText = isUnpaid ? "غير مدفوعة" : "مدفوعة";
    Color payStatusColor = isUnpaid ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            children: [
              Text(
                'فاتورة شهر : ${bill.bilIssuYm}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: payStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: payStatusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  payStatusText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: payStatusColor),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bill.bilRemain.isEmpty ? '0.0' : bill.bilRemain,
                style: TextStyle(
                  color: isUnpaid ? const Color(0xFF06F106) : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Text(
                'المتبقي',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 15),
                  if (bill.bilNum.isNotEmpty)
                    _detailRow(Icons.tag_rounded, 'رقم الفاتورة', bill.bilNum),
                  _detailRow(
                    Icons.speed_rounded,
                    'كمية الإستهلاك',
                    bill.bilQty.isEmpty ? '—' : '${bill.bilQty} (ك.و)',
                  ),
                  if (bill.bilAmt.isNotEmpty)
                    _detailRow(Icons.receipt_outlined, 'قيمة الاستهلاك', '${bill.bilAmt} دينار'),
                  _detailRow(Icons.account_balance_wallet_outlined, 'القيمة الكلية', '${bill.bilTot} دينار'),
                  if (bill.bilPayTot.isNotEmpty)
                    _detailRow(Icons.payments_outlined, 'المبلغ المدفوع', '${bill.bilPayTot} دينار'),
                  _detailRow(
                    Icons.event_available_rounded,
                    'تاريخ التسديد',
                    bill.bilLpayDate.isEmpty ? 'غير مسددة' : bill.bilLpayDate,
                  ),
                  _detailRow(
                    Icons.calendar_today_rounded,
                    'تاريخ الفاتورة',
                    bill.bilBilDate.isEmpty ? '—' : bill.bilBilDate,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
        ],
      ),
    );
  }
}
