import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ideco_platform/core/theme/app_colors.dart';
import 'package:ideco_platform/core/widgets/app_dialogs.dart';
import 'package:ideco_platform/platform/domain/entities/employee.dart';
import 'package:ideco_platform/platform/presentation/cubit/platform_auth_cubit.dart';
import 'package:ideco_platform/platform/presentation/cubit/platform_auth_state.dart';
import 'package:ideco_platform/injection_container.dart';
import '../../domain/entities/engineer_entity.dart';
import '../../domain/entities/operation_entity.dart';
import '../cubit/inspection_inquiry_cubit.dart';
import '../cubit/inspection_inquiry_state.dart';
import 'package:ideco_platform/core/widgets/barcode_scanner_screen.dart';

class InspectionInquiryPage extends StatelessWidget {
  const InspectionInquiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InspectionInquiryCubit>(
      create: (context) => sl<InspectionInquiryCubit>()..loadFormData(),
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
  final _pidCtrl = TextEditingController();
  final _stampCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();

  TextEditingController? _engTextCtrl;
  TextEditingController? _helperTextCtrl;

  EngineerEntity? _selectedEngineer;
  EngineerEntity? _selectedHelper;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _pidCtrl.dispose();
    _stampCtrl.dispose();
    _notesCtrl.dispose();
    _driverCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _stampCtrl.clear();
    _notesCtrl.clear();
    _driverCtrl.clear();
    _engTextCtrl?.clear();
    _helperTextCtrl?.clear();
    setState(() {
      _image = null;
      _selectedEngineer = null;
      _selectedHelper = null;
    });
  }

  Future<void> _takePhoto() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (photo != null) {
      setState(() => _image = File(photo.path));
    }
  }

  void _handleSave(
      Employee currentEmployee, OperationEntity operation, List<EngineerEntity> engineers) async {
    EngineerEntity? engineer = _selectedEngineer;

    // Search in engineers if typed text matches an engineer name
    if (engineer == null && _engTextCtrl != null && _engTextCtrl!.text.isNotEmpty) {
      final typed = _engTextCtrl!.text.trim().toLowerCase();
      for (final e in engineers) {
        if (e.name.trim().toLowerCase() == typed ||
            '${e.name} - ${e.empNumber}'.trim().toLowerCase() == typed) {
          engineer = e;
          break;
        }
      }
    }

    if (engineer == null) {
      showAppSnack(context, 'لم يتم العثور على المهندس المسؤول', isError: true);
      return;
    }

    final base64Image =
        _image != null ? base64Encode(await _image!.readAsBytes()) : null;

    if (!mounted) return;

    final helperNum = (_selectedHelper != null && _selectedHelper!.empNumber != '-1')
        ? _selectedHelper!.empNumber
        : '-1';

    context.read<InspectionInquiryCubit>().submitProcessNote(
          empNo: currentEmployee.employeeNumber,
          workshopNum: currentEmployee.workshopNumber,
          pid: operation.pid,
          stampNum: _stampCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          engName: engineer.name,
          engNumber: engineer.empNumber,
          helperWorkshopNum: helperNum,
          driver: _driverCtrl.text.trim(),
          base64Image: base64Image,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InspectionInquiryCubit, InspectionInquiryState>(
      listener: (context, state) {
        if (state is InspectionInquiryFailure) {
          showAppSnack(context, state.message, isError: true);
        } else if (state is InspectionSuccess) {
          showAppMessage(context, message: state.message, title: 'نجاح');
          _resetForm();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنفيذ معاملة التفتيش'),
          backgroundColor: AppColors.primary,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocBuilder<InspectionInquiryCubit, InspectionInquiryState>(
            builder: (context, state) {
              final operation =
                  state is OperationLoaded ? state.operation : null;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInquirySection(state),
                    if (operation != null) ...[
                      const SizedBox(height: 16),
                      _buildOperationInfo(operation),
                      if (!operation.isAssigned) ...[
                        const SizedBox(height: 16),
                        _buildMainForm(state, operation),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInquirySection(InspectionInquiryState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          TextField(
            controller: _pidCtrl,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: 'رقم العملية (PID)',
              hintText: 'أدخل رقم العملية فقط',
              counterText: '',
              prefixIcon: const Icon(Icons.numbers, color: Color(0xFF0284C7)),
              suffixIcon: _pidCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _pidCtrl.clear();
                        _resetForm();
                        context.read<InspectionInquiryCubit>().clearSearch();
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: state is InspectionInquiryLoading
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    context
                        .read<InspectionInquiryCubit>()
                        .searchOperation(_pidCtrl.text);
                  },
            icon: state is InspectionInquiryLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            label: const Text('استعلام عن البيانات'),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationInfo(OperationEntity operation) {
    final bool isAssigned = operation.isAssigned;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAssigned ? Colors.orange.shade300 : Colors.grey.shade200,
          width: isAssigned ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssigned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هذه المعاملة منفذة / محولة مسبقاً',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _infoRow('اسم المهندس:', operation.engineerName),
            const Divider(),
            _infoRow('اسم الورشة:', operation.workshopName),
            const Divider(),
          ],
          _infoRow('رقم الاشتراك:', operation.subscriptionNum),
          const Divider(),
          _infoRow('المدينة:', operation.city),
          if (operation.engineerNote.isNotEmpty || operation.notes.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              'الملاحظات:',
              operation.engineerNote.isNotEmpty
                  ? operation.engineerNote
                  : operation.notes,
            ),
          ],
          if (operation.stampNumber.isNotEmpty) ...[
            const Divider(),
            _infoRow('رقم الختم:', operation.stampNumber),
          ],
          if (operation.date.isNotEmpty) ...[
            const Divider(),
            _infoRow('التاريخ:', operation.date),
          ],
        ],
      ),
    );
  }

  Widget _buildMainForm(InspectionInquiryState state, OperationEntity operation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('بيانات التنفيذ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),

          // المهندس مع فلترة تلقائية (AutoComplete Filter)
          Autocomplete<EngineerEntity>(
            displayStringForOption: (e) => e.name,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return state.engineers;
              }
              final query = textEditingValue.text.trim().toLowerCase();
              return state.engineers.where((e) =>
                  e.name.toLowerCase().contains(query) ||
                  e.empNumber.toLowerCase().contains(query));
            },
            onSelected: (e) => setState(() => _selectedEngineer = e),
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              _engTextCtrl = controller;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (val) {
                  if (_selectedEngineer != null &&
                      _selectedEngineer!.name != val) {
                    setState(() => _selectedEngineer = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'اسم المهندس المسؤول *',
                  hintText: 'اختر أو ابحث عن اسم المهندس',
                  prefixIcon:
                      const Icon(Icons.person, color: AppColors.primary),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            controller.clear();
                            setState(() => _selectedEngineer = null);
                          },
                        )
                      : null,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // مساعد الورشة مع فلترة تلقائية (AutoComplete Filter)
          Autocomplete<EngineerEntity>(
            displayStringForOption: (e) => e.empNumber == '-1'
                ? e.name
                : '${e.name} - ${e.empNumber}',
            optionsBuilder: (textEditingValue) {
              final helpers = [
                const EngineerEntity(empNumber: '-1', name: 'بدون مساعد ورشة'),
                ...state.helperWorkshops.where((e) => e.empNumber != '-1'),
              ];
              if (textEditingValue.text.isEmpty) {
                return helpers;
              }
              final query = textEditingValue.text.trim().toLowerCase();
              return helpers.where((e) =>
                  e.name.toLowerCase().contains(query) ||
                  e.empNumber.toLowerCase().contains(query));
            },
            onSelected: (e) {
              setState(() {
                _selectedHelper = e.empNumber == '-1' ? null : e;
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              _helperTextCtrl = controller;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (val) {
                  if (_selectedHelper != null &&
                      '${_selectedHelper!.name} - ${_selectedHelper!.empNumber}' !=
                          val &&
                      _selectedHelper!.name != val) {
                    setState(() => _selectedHelper = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'مساعد الورشة (اختياري)',
                  hintText: 'اختر أو ابحث عن مساعد الورشة',
                  prefixIcon: const Icon(Icons.group, color: AppColors.primary),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            controller.clear();
                            setState(() => _selectedHelper = null);
                          },
                        )
                      : null,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _driverCtrl,
            decoration: const InputDecoration(
              labelText: 'اسم السائق',
              prefixIcon: Icon(Icons.drive_eta),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _stampCtrl,
            decoration: InputDecoration(
              labelText: 'رقم الختم',
              prefixIcon: const Icon(Icons.confirmation_number),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.primary),
                tooltip: 'مسح الباركود بالكاميرا',
                onPressed: () async {
                  final scanned = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BarcodeScannerScreen()),
                  );
                  if (scanned != null && scanned.isNotEmpty) {
                    setState(() => _stampCtrl.text = scanned);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'الملاحظات',
              prefixIcon: Icon(Icons.note),
            ),
          ),

          const SizedBox(height: 24),

          // الصورة
          Center(
            child: Column(
              children: [
                if (_image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_image!,
                        height: 150, width: 200, fit: BoxFit.cover),
                  )
                else
                  Container(
                    height: 150,
                    width: 200,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.camera_alt,
                        size: 50, color: Colors.grey),
                  ),
                TextButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('التقاط صورة المعاملة'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // زر الحفظ
          BlocBuilder<PlatformAuthCubit, PlatformAuthState>(
            builder: (authCtx, authState) {
              if (authState is! PlatformAuthAuthenticated) {
                return const SizedBox();
              }

              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: state is InspectionSubmitting
                    ? null
                    : () => _handleSave(
                        authState.session.employee,
                        operation,
                        state.engineers),
                child: state is InspectionSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ المعاملة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
