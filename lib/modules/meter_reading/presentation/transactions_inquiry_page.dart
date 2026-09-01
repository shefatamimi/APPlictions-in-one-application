/// # TransactionsInquiryPage
///
/// Filtered search over field transactions, ported from the standalone
/// `InquiryScreen`.
///
/// Two behavioural changes, both platform-related:
/// * the technician name is pre-filled from the single sign-on session instead
///   of being read back from local preferences;
/// * picking a result pops a typed [FieldTransaction] back to the capture
///   screen instead of an untyped `Map`.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../platform/domain/entities/platform_session.dart';
import '../data/coordinates_api.dart';
import '../data/models/field_transaction.dart';
import '../data/models/generic_type.dart';

class TransactionsInquiryPage extends StatefulWidget {
  const TransactionsInquiryPage({
    super.key,
    required this.api,
    required this.session,
  });

  final CoordinatesApi api;
  final PlatformSession session;

  @override
  State<TransactionsInquiryPage> createState() =>
      _TransactionsInquiryPageState();
}

class _TransactionsInquiryPageState extends State<TransactionsInquiryPage> {
  final _employeeController = TextEditingController();
  final _dateController = TextEditingController();
  final _sectionController = TextEditingController();
  final _subscriptionController = TextEditingController();
  final _meterController = TextEditingController();
  final _operationController = TextEditingController();

  List<GenericType> _types = const [];
  String? _selectedMinor;
  String? _selectedTypeName;

  List<FieldTransaction> _results = const [];
  bool _isLoadingTypes = true;
  bool _isSearching = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    // Single sign-on: the employee identity comes from the session instead of
    // local preferences. The section filter is deliberately left empty — the
    // service matches it against its own SECTION column, which does not always
    // equal the workshop name, and a wrong pre-filled filter would silently
    // return no rows.
    _employeeController.text = widget.session.employee.username;
    _loadTypes();
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _dateController.dispose();
    _sectionController.dispose();
    _subscriptionController.dispose();
    _meterController.dispose();
    _operationController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoadingTypes = true);
    try {
      final types = await widget.api.fetchRecordTypes();
      if (!mounted) return;
      setState(() {
        _types = types.isNotEmpty ? types : _fallbackTypes;
        _isLoadingTypes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _types = _fallbackTypes;
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _search() async {
    setState(() {
      _isSearching = true;
      _results = const [];
    });

    try {
      final results = await widget.api.searchTransactions(
        employeeName: _employeeController.text.trim(),
        date: _dateController.text.trim(),
        section: _sectionController.text.trim(),
        subscriptionNo: _subscriptionController.text.trim(),
        meterNo: _meterController.text.trim(),
        operationNo: _operationController.text.trim(),
        type: _selectedTypeName,
      );

      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
        _searched = true;
      });

      if (results.isEmpty) {
        showAppSnack(context, 'لا توجد نتائج تطابق هذا البحث');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searched = true;
      });
      showAppMessage(
        context,
        message: 'حدث خطأ في الاتصال بالخادم، يرجى المحاولة مرة أخرى',
        isError: true,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(
        () => _dateController.text = DateFormat('yyyy-MM-dd').format(picked),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعلام المعاملات')),
      body: SafeArea(
        child: ContentBounds(
          child: ListView(
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
            children: [
              _buildFilters(),
              const SizedBox(height: AppDimens.xl),
              if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else if (_results.isNotEmpty)
                ..._results.map(_buildResultCard)
              else if (_searched)
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimens.sm),
                Text('فلاتر البحث',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppDimens.lg),
            _field(_employeeController, 'اسم الفني', Icons.person_outline),
            _pairRow(
              _field(
                _dateController,
                'التاريخ',
                Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDate,
              ),
              _field(_sectionController, 'القسم', Icons.business_outlined),
            ),
            _pairRow(
              _field(_subscriptionController, 'رقم الاشتراك', Icons.tag),
              _field(_meterController, 'رقم العداد', Icons.speed_outlined),
            ),
            _field(_operationController, 'رقم العملية',
                Icons.confirmation_number_outlined),
            _buildTypeDropdown(),
            const SizedBox(height: AppDimens.sm),
            ElevatedButton.icon(
              onPressed: _isSearching ? null : _search,
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text('تطبيق البحث'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedMinor,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'نوع المعاملة',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: _isLoadingTypes ? 'جاري تحميل الأنواع...' : 'اختر النوع',
          suffixIcon: _isLoadingTypes
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.category_outlined,
                  color: AppColors.primary, size: 20),
        ),
        items: _types
            .map(
              (type) => DropdownMenuItem<String>(
                value: type.minor,
                child: Row(
                  children: [
                    Icon(iconForType(type.description),
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: Text(type.description, textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedMinor = value;
            _selectedTypeName =
                _types.firstWhere((t) => t.minor == value).description;
          });
        },
      ),
    );
  }

  Widget _buildResultCard(FieldTransaction result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(iconForType(result.type),
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Text(
                      result.type.isEmpty ? 'معاملة' : result.type,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (result.date.isNotEmpty)
                    Text(result.date,
                        style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              const Divider(height: AppDimens.xxl),
              _detailRow('رقم الاشتراك', result.subscriptionNo),
              _detailRow('رقم العداد', result.meterNo),
              _detailRow('رقم العملية', result.operationNo),
              _detailRow('الفني', result.employeeName),
              _detailRow('القسم', result.section),
              _detailRow(
                  'المنطقة',
                  [result.province, result.town]
                      .where((e) => e.isNotEmpty)
                      .join(' — ')),
              if (result.hasPosition) ...[
                const SizedBox(height: AppDimens.md),
                Container(
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('X: ${result.x}',
                          style: Theme.of(context).textTheme.labelMedium),
                      Text('Y: ${result.y}',
                          style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.md),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: () => Navigator.of(context).pop(result),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('اعتماد ونقل إلى الخريطة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.xxxl),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 46, color: AppColors.textTertiary),
          const SizedBox(height: AppDimens.md),
          Text('لا توجد نتائج', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppDimens.xs),
          Text('حاول تعديل الفلاتر ثم إعادة البحث',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // ─── Small building blocks ─────────────────────────────────────────────────

  Widget _pairRow(Widget first, Widget second) {
    if (!Responsive.isWide(context)) {
      return Column(children: [first, second]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: AppDimens.md),
        Expanded(child: second),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  static const List<GenericType> _fallbackTypes = [
    GenericType(description: 'معاملة', major: '324', minor: '1'),
    GenericType(description: 'اشتراك', major: '324', minor: '2'),
    GenericType(description: 'محول', major: '324', minor: '3'),
    GenericType(description: 'عمود', major: '324', minor: '4'),
  ];
}

/// Icon for a record type, matched on the Arabic description exactly as the
/// original module did (the service has no icon column).
IconData iconForType(String description) {
  final value = description.trim();
  if (value.contains('اشتراك') || value.contains('إشتراك')) {
    return Icons.assignment_ind_outlined;
  }
  if (value.contains('محول')) return Icons.settings_input_component;
  if (value.contains('عمود')) return Icons.vertical_align_top;
  if (value.contains('معاملة')) return Icons.receipt_long_outlined;
  if (value.contains('عداد')) return Icons.speed_outlined;
  return Icons.category_outlined;
}
