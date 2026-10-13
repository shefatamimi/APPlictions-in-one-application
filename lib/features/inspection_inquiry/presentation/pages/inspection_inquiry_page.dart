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
import '../cubit/inspection_inquiry_cubit.dart';
import '../cubit/inspection_inquiry_state.dart';

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

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (photo != null) {
      setState(() => _image = File(photo.path));
    }
  }

  void _handleSave(Employee currentEmployee, OperationLoaded state) async {
    if (_selectedEngineer == null) {
      showAppSnack(context, 'يرجى اختيار المهندس', isError: true);
      return;
    }
    
    final base64Image = _image != null 
        ? base64Encode(await _image!.readAsBytes())
        : null;

    if (!mounted) return;
    
    context.read<InspectionInquiryCubit>().submitProcessNote(
      empNo: currentEmployee.employeeNumber,
      workshopNum: currentEmployee.workshopNumber,
      pid: state.operation.pid,
      stampNum: _stampCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      engName: _selectedEngineer!.name,
      engNumber: _selectedEngineer!.empNumber,
      helperWorkshopNum: _selectedHelper?.empNumber ?? '',
      driver: _driverCtrl.text.trim(),
      base64Image: base64Image,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InspectionInquiryCubit, InspectionInquiryState>(
      listener: (context, state) {
        if (state is InspectionSuccess) {
          showAppMessage(context, message: state.message, title: 'نجاح');
          _stampCtrl.clear();
          _notesCtrl.clear();
          _driverCtrl.clear();
          setState(() {
            _image = null;
            _selectedEngineer = null;
            _selectedHelper = null;
          });
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
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInquirySection(state),
                    if (state is OperationLoaded || state is InspectionSubmitting || state is InspectionSuccess) 
                      _buildExecutionForm(state),
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
            decoration: const InputDecoration(
              labelText: 'رقم العملية',
              prefixIcon: Icon(Icons.numbers, color: Color(0xFF0284C7)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: state is InspectionInquiryLoading 
                ? null 
                : () => context.read<InspectionInquiryCubit>().searchOperation(_pidCtrl.text),
            icon: state is InspectionInquiryLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            label: const Text('استعلام عن البيانات'),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionForm(InspectionInquiryState state) {
    final operation = state is OperationLoaded ? state.operation : null;
    if (operation == null && state is! InspectionSubmitting && state is! InspectionSuccess) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 16),
        if (operation != null) _buildOperationInfo(operation),
        const SizedBox(height: 16),
        _buildMainForm(state),
      ],
    );
  }

  Widget _buildOperationInfo(var operation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _infoRow('المدينة:', operation.city),
          const Divider(),
          _infoRow('رقم الاشتراك:', operation.subscriptionNum),
        ],
      ),
    );
  }

  Widget _buildMainForm(InspectionInquiryState state) {
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
            const Text('بيانات التنفيذ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            
            // المهندس
            Autocomplete<EngineerEntity>(
              displayStringForOption: (e) => e.name,
              optionsBuilder: (textValue) => state.engineers
                  .where((e) => e.name.contains(textValue.text)),
              onSelected: (e) => setState(() => _selectedEngineer = e),
              fieldViewBuilder: (ctx, ctrl, focus, onFieldSubmitted) => TextField(
                controller: ctrl,
                focusNode: focus,
                decoration: const InputDecoration(labelText: 'اسم المهندس', prefixIcon: Icon(Icons.person)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // مساعد الورشة
            Autocomplete<EngineerEntity>(
              displayStringForOption: (e) => e.name,
              optionsBuilder: (textValue) => state.helperWorkshops
                  .where((e) => e.name.contains(textValue.text)),
              onSelected: (e) => setState(() => _selectedHelper = e),
              fieldViewBuilder: (ctx, ctrl, focus, onFieldSubmitted) => TextField(
                controller: ctrl,
                focusNode: focus,
                decoration: const InputDecoration(labelText: 'مساعد الورشة (اختياري)', prefixIcon: Icon(Icons.group)),
              ),
            ),

            const SizedBox(height: 16),
            
            TextField(
              controller: _driverCtrl,
              decoration: const InputDecoration(labelText: 'اسم السائق', prefixIcon: Icon(Icons.drive_eta)),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _stampCtrl,
              decoration: const InputDecoration(labelText: 'رقم الختم', prefixIcon: Icon(Icons.confirmation_number)),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'الملاحظات', prefixIcon: Icon(Icons.note)),
            ),

            const SizedBox(height: 24),

            // الصورة
            Center(
              child: Column(
                children: [
                  if (_image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_image!, height: 150, width: 200, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      height: 150, width: 200,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
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
                if (authState is! PlatformAuthAuthenticated) return const SizedBox();
                
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: (state is InspectionSubmitting || state is! OperationLoaded)
                      ? null 
                      : () => _handleSave(authState.session.employee, state),
                  child: state is InspectionSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ المعاملة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
