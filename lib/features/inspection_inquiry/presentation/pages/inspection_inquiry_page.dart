/// # InspectionInquiryPage
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../injection_container.dart';
import '../../domain/entities/engineer_entity.dart';
import '../../domain/entities/operation_entity.dart';
import '../cubit/inspection_inquiry_cubit.dart';
import '../cubit/inspection_inquiry_state.dart';

class InspectionInquiryPage extends StatelessWidget {
  const InspectionInquiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InspectionInquiryCubit>()..loadEngineers(),
      child: const _InspectionInquiryView(),
    );
  }
}

class _InspectionInquiryView extends StatefulWidget {
  const _InspectionInquiryView();

  @override
  State<_InspectionInquiryView> createState() => _InspectionInquiryViewState();
}

class _InspectionInquiryViewState extends State<_InspectionInquiryView> {
  static const _primaryBlue = Color(0xFF0284C7);
  static const _darkText = Color(0xFF0F172A);
  static const _labelGrey = Color(0xFF475569);
  static const _bgGray = Color(0xFFF8FAFC);

  final _pidCtrl = TextEditingController();
  final _stampCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _helperWorkshopCtrl = TextEditingController();
  final _engSearchCtrl = TextEditingController();

  List<EngineerEntity> _allEngineers = [];
  List<EngineerEntity> _filteredEngineers = [];
  EngineerEntity? _selectedEngineer;
  bool _hasResult = false;

  @override
  void dispose() {
    _pidCtrl.dispose();
    _stampCtrl.dispose();
    _notesCtrl.dispose();
    _driverCtrl.dispose();
    _helperWorkshopCtrl.dispose();
    _engSearchCtrl.dispose();
    super.dispose();
  }

  void _onEngSearch(String value) {
    setState(() {
      _filteredEngineers = _allEngineers
          .where((e) => e.name.contains(value) || e.empNumber.contains(value))
          .take(8)
          .toList();
    });
  }

  void _selectEngineer(EngineerEntity eng) {
    _engSearchCtrl.text = '${eng.name} (${eng.empNumber})';
    setState(() {
      _selectedEngineer = eng;
      _filteredEngineers = [];
    });
    FocusScope.of(context).unfocus();
  }

  void _onSearch(BuildContext ctx) {
    if (_pidCtrl.text.trim().isEmpty) {
      _snack(ctx, 'الرجاء إدخال رقم العملية');
      return;
    }
    ctx.read<InspectionInquiryCubit>().searchOperation(_pidCtrl.text.trim());
  }

  void _onClear(BuildContext ctx) {
    _pidCtrl.clear();
    _stampCtrl.clear();
    _notesCtrl.clear();
    _driverCtrl.clear();
    _helperWorkshopCtrl.clear();
    _engSearchCtrl.clear();
    setState(() {
      _selectedEngineer = null;
      _hasResult = false;
      _filteredEngineers = [];
    });
    ctx.read<InspectionInquiryCubit>().clearSearch();
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
        backgroundColor: _primaryBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onSave(BuildContext ctx) {
    if (_selectedEngineer == null) {
      _snack(ctx, 'الرجاء اختيار المهندس');
      return;
    }
    if (_stampCtrl.text.trim().isEmpty) {
      _snack(ctx, 'الرجاء إدخال رقم الختم');
      return;
    }
    _snack(ctx, 'قيد التطوير — حفظ البيانات');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InspectionInquiryCubit, InspectionInquiryState>(
      listener: (ctx, state) {
        if (state is OperationLoaded) {
          _allEngineers = state.engineers;
          if (!state.operation.isFound) {
            _snack(ctx, 'لا يوجد معاملة بهذا الرقم');
          } else {
            setState(() => _hasResult = true);
          }
        }
        if (state is EngineersLoaded) _allEngineers = state.engineers;
        if (state is InspectionInquiryFailure) {
          _allEngineers = state.engineers;
          _snack(ctx, state.message);
        }
      },
      builder: (ctx, state) {
        final isLoading = state is InspectionInquiryLoading;
        final customerOp = state is OperationLoaded ? state.operation : null;

        return Scaffold(
          backgroundColor: _bgGray,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            surfaceTintColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _darkText, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: const Text('تنفيذ معاملة تفتيش',
                style: TextStyle(
                    fontFamily: 'AdFont',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkText)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildSearchSection(ctx, isLoading),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    children: [
                      if (isLoading)
                        _buildSimpleLoader()
                      else if (customerOp != null && customerOp.isFound) ...[
                        _buildBasicDataSection(customerOp),
                        const SizedBox(height: 20),
                        if (customerOp.isAssigned)
                          _buildSummaryView(ctx, customerOp)
                        else
                          _buildExecutionForm(ctx, customerOp),
                      ] else if (!_hasResult)
                        _buildWelcomeState(),
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

  Widget _buildSearchSection(BuildContext ctx, bool isLoading) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رقم العملية المراد تفتيشها',
              style: TextStyle(
                  fontFamily: 'AdFont',
                  fontSize: 13,
                  color: _labelGrey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1))),
                  child: TextField(
                    controller: _pidCtrl,
                    enabled: !isLoading && !_hasResult,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _darkText),
                    decoration: const InputDecoration(
                        hintText: 'أدخل الرقم هنا',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _hasResult ? const Color(0xFF94A3B8) : _primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: isLoading
                      ? null
                      : () => _hasResult ? _onClear(ctx) : _onSearch(ctx),
                  child: Text(_hasResult ? 'مسح' : 'استعلام',
                      style: const TextStyle(
                          fontFamily: 'AdFont',
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicDataSection(OperationEntity op) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          _simpleInfoRow('اسم المهندس', op.engineerName),
          _simpleInfoRow('اسم الورشة', op.workshopName),
          _simpleInfoRow('البلدة', op.city),
          _simpleInfoRow('رقم الاشتراك', op.subscriptionNum, isLast: true),
        ],
      ),
    );
  }

  Widget _simpleInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'AdFont', fontSize: 13, color: _labelGrey))),
          const SizedBox(width: 12),
          Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontFamily: 'AdFont',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _darkText))),
        ],
      ),
    );
  }

  Widget _buildExecutionForm(BuildContext ctx, OperationEntity op) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.only(right: 4, bottom: 16),
            child: Text('تكملة بيانات التفتيش',
                style: TextStyle(
                    fontFamily: 'AdFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _darkText))),
        _inputLabel('المهندس المسؤول عن التنفيذ'),
        _buildEngAutocomplete(),
        const SizedBox(height: 16),
        _inputLabel('مساعد الورشة'),
        _cleanField(_helperWorkshopCtrl, 'اسم المساعد'),
        const SizedBox(height: 16),
        _inputLabel('رقم الختم المستعمل'),
        _cleanField(_stampCtrl, 'أدخل رقم الختم', type: TextInputType.number),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _onSave(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: const Text('حفظ البيانات وإرسال',
                style: TextStyle(
                    fontFamily: 'AdFont',
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryView(BuildContext ctx, OperationEntity op) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text('تم تنفيذ المعاملة مسبقاً',
                style: TextStyle(
                    fontFamily: 'AdFont',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.green))
          ]),
          const SizedBox(height: 20),
          _simpleInfoRow('رقم الختم', op.stampNumber),
          _simpleInfoRow('تاريخ التنفيذ', op.date),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(ctx)
                  .pushNamed('/inspection-movement', arguments: op),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _primaryBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('عرض معلومات حركة التفتيش الكاملة',
                  style: TextStyle(
                      fontFamily: 'AdFont',
                      fontWeight: FontWeight.bold,
                      color: _primaryBlue)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'AdFont',
              fontSize: 13,
              color: _darkText,
              fontWeight: FontWeight.bold)));

  Widget _cleanField(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      style: const TextStyle(
          fontFamily: 'AdFont',
          fontSize: 15,
          color: _darkText,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)))),
    );
  }

  Widget _buildEngAutocomplete() {
    return Column(
      children: [
        _cleanField(_engSearchCtrl, 'ابحث بالاسم أو الرقم الوظيفي'),
        if (_filteredEngineers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1))),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filteredEngineers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final eng = _filteredEngineers[i];
                return ListTile(
                    title: Text(eng.name,
                        style: const TextStyle(
                            fontFamily: 'AdFont',
                            fontSize: 14,
                            color: _darkText,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(eng.empNumber),
                    onTap: () => _selectEngineer(eng));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleLoader() => const Center(
      child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child:
              CircularProgressIndicator(color: _primaryBlue, strokeWidth: 4)));

  Widget _buildWelcomeState() => Center(
      child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(children: [
            const Icon(Icons.search_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            const Text('أدخل رقم العملية لعرض البيانات',
                style: TextStyle(
                    fontFamily: 'AdFont',
                    color: _labelGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold))
          ])));
}
