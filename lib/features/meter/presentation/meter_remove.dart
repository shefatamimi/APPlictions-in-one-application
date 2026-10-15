import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ideco_platform/core/theme/app_colors.dart';
import 'package:ideco_platform/features/inquiry/domain/entities/customer_info_entity.dart';
import 'package:ideco_platform/features/meter/services/meter_service.dart';
import 'package:ideco_platform/platform/presentation/cubit/platform_auth_cubit.dart';
import 'package:ideco_platform/platform/presentation/cubit/platform_auth_state.dart';

class MeterRemovalScreen extends StatefulWidget {
  const MeterRemovalScreen({super.key});

  @override
  State<MeterRemovalScreen> createState() => _MeterRemovalScreenState();
}

class _MeterRemovalScreenState extends State<MeterRemovalScreen> {
  final Color primarySkyBlue = AppColors.primary;
  final Color backgroundGray = const Color(0xFFF1F5F9);
  final ImagePicker _picker = ImagePicker();

  CustomerInfoEntity? _customer;
  bool _isFetchingProcess = false;

  // ممسكات النصوص الأساسية
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _techNameController = TextEditingController();
  final TextEditingController _processNumController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // ممسكات القراءات المستجرة (Import)
  final TextEditingController _importNormalController = TextEditingController();
  final TextEditingController _importPeakController = TextEditingController();
  final TextEditingController _importOffPeakController =
      TextEditingController();
  final TextEditingController _importPartial1Controller =
      TextEditingController();
  final TextEditingController _importPartial2Controller =
      TextEditingController();

  // ممسكات القراءات المصدرة (Export)
  final TextEditingController _exportNormalController = TextEditingController();
  final TextEditingController _exportPeakController = TextEditingController();
  final TextEditingController _exportOffPeakController =
      TextEditingController();
  final TextEditingController _exportPartial1Controller =
      TextEditingController();
  final TextEditingController _exportPartial2Controller =
      TextEditingController();

  final Map<String, bool> _checklist = {
    "ختم غطاء التوصيل": false,
    "الكيبل": false,
    "اللوحة": false,
    "علبة التوزيع": false,
    "العداد": false,
    "خزانة العدادات": false,
    "أختام العداد العلوية": false,
  };

  // تثبيت الـ 4 صور المطلوبة
  final Map<String, File?> _images = {
    "صورة العداد قبل الخلع": null,
    "صورة اللوحة بعد الخلع": null,
    "صورة الأختام": null,
    "صورة العداد الجديد": null,
  };

  @override
  void initState() {
    super.initState();
    _dateController.text =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_customer == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is CustomerInfoEntity) {
        _customer = args;
        _fetchRemovingProcess(_customer!.meterSerialNum);
      }
    }

    if (_techNameController.text.isEmpty) {
      try {
        final authState = context.read<PlatformAuthCubit>().state;
        if (authState is PlatformAuthAuthenticated) {
          final employee = authState.session.employee;
          _techNameController.text = employee.username.isNotEmpty
              ? employee.username
              : employee.displayName;
        }
      } catch (_) {}
    }
  }

  Future<void> _fetchRemovingProcess(String meterNum) async {
    setState(() => _isFetchingProcess = true);
    try {
      final pid = await MeterService.getRemovingCounterProcess(meterNum);
      if (!mounted) return;
      setState(() => _isFetchingProcess = false);

      if (pid.isNotEmpty) {
        _processNumController.text = pid;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "لم يتم العثور على معاملة خلع تلقائية، يرجى إدخال رقم المعاملة يدوياً"),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingProcess = false);
      }
    }
  }

  Future<void> _pickImage(String label) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        setState(() {
          _images[label] = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("عذراً، فشل فتح الكاميرا: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    final authState = context.read<PlatformAuthCubit>().state;
    final employee = authState is PlatformAuthAuthenticated
        ? authState.session.employee
        : null;
    final empName = employee?.fullName.isNotEmpty == true
        ? employee!.fullName
        : (employee?.username ?? 'فني');

    showDialog(
      context: context,
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
                Text('جاري حفظ وإرسال معاملة الخلع...',
                    style: TextStyle(fontFamily: 'AdFont')),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final cityCode = _customer?.cityCode ?? '';
      final mtrSerial = _customer?.meterSerialNum ?? '';
      final subSerial = _customer?.subscriptionSerial ?? '';

      // 1. Gather data parts (22 parts)
      final data = ":$empName;"
          ":${_dateController.text};"
          ":$cityCode;"
          ":$mtrSerial;"
          ":$subSerial;"
          ":${_processNumController.text};"
          ":${_importNormalController.text.trim()};"
          ":${_importPeakController.text.trim()};"
          ":${_importOffPeakController.text.trim()};"
          ":${_importPartial1Controller.text.trim()};"
          ":${_exportNormalController.text.trim()};"
          ":${_exportPeakController.text.trim()};"
          ":${_exportOffPeakController.text.trim()};"
          ":${_exportPartial1Controller.text.trim()};"
          ":${_checklist["ختم غطاء التوصيل"] == true ? "1" : "0"};"
          ":${_checklist["علبة التوزيع"] == true ? "1" : "0"};"
          ":${_checklist["الكيبل"] == true ? "1" : "0"};"
          ":${_checklist["خزانة العدادات"] == true ? "1" : "0"};"
          ":${_checklist["اللوحة"] == true ? "1" : "0"};"
          ":${_checklist["العداد"] == true ? "1" : "0"};"
          ":${_checklist["أختام العداد العلوية"] == true ? "1" : "0"};"
          ":${_notesController.text.trim()}";

      final data2 = "";

      // 2. Images (encoded1 to encoded8)
      List<String> encodedImages = [];
      final imageKeys = _images.keys.toList();
      for (int i = 0; i < 8; i++) {
        if (i < imageKeys.length && _images[imageKeys[i]] != null) {
          final bytes = await _images[imageKeys[i]]!.readAsBytes();
          encodedImages.add(base64Encode(bytes));
        } else {
          encodedImages.add("");
        }
      }

      final timeFlag = _customer?.hasTimeOfUse == true ? "1" : "0";
      final renFlag = _customer?.isRenewable == true ? "1" : "0";

      final result = await MeterService.insertRemoveCounterData(
        data: data,
        data2: data2,
        encoded1: encodedImages[0],
        encoded2: encodedImages[1],
        encoded3: encodedImages[2],
        encoded4: encodedImages[3],
        encoded5: encodedImages[4],
        encoded6: encodedImages[5],
        encoded7: encodedImages[6],
        encoded8: encodedImages[7],
        timeFlag: timeFlag,
        renFlag: renFlag,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('نتيجة خلع العداد',
                style: TextStyle(
                    fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
            content: Text(result, style: const TextStyle(fontFamily: 'AdFont')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('حسناً', style: TextStyle(fontFamily: 'AdFont')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: const Text('نموذج خلع عداد', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              _buildModernCard(
                title: "المعلومات الأساسية",
                icon: Icons.info_outline_rounded,
                children: [
                  _buildTextField("تاريخ العملية", Icons.calendar_today_rounded,
                      controller: _dateController, readOnly: true),
                  _buildTextField("اسم الفني المختص", Icons.person_outline_rounded,
                      controller: _techNameController),
                  _buildTextField(
                      "رقم المعاملة / العملية",
                      Icons.confirmation_num_outlined,
                      controller: _processNumController,
                      type: TextInputType.number,
                      suffixIcon: _isFetchingProcess
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            )
                          : null),
                ],
              ),
              _buildModernCard(
                title: "قائمة تفقد العداد والتوصيلات",
                icon: Icons.fact_check_outlined,
                children: _checklist.keys
                    .map((key) => _buildCheckItem(key))
                    .toList(),
              ),
              _buildModernCard(
                title: "قراءات الطاقة المستجرة (Import)",
                icon: Icons.login_rounded,
                children: [
                  _buildTextField("آخر قراءة مستجرة - كلي / عادي",
                      Icons.speed_rounded,
                      controller: _importNormalController,
                      type: TextInputType.number),
                  _buildTextField("آخر قراءة مستجرة - وقت الذروة",
                      Icons.trending_up_rounded,
                      controller: _importPeakController,
                      type: TextInputType.number),
                  _buildTextField("آخر قراءة مستجرة - خارج الذروة",
                      Icons.trending_down_rounded,
                      controller: _importOffPeakController,
                      type: TextInputType.number),
                  _buildTextField("آخر قراءة مستجرة - جزئي 1",
                      Icons.access_time_rounded,
                      controller: _importPartial1Controller,
                      type: TextInputType.number),
                  _buildTextField("آخر قراءة مستجرة - جزئي 2",
                      Icons.access_time_rounded,
                      controller: _importPartial2Controller,
                      type: TextInputType.number),
                ],
              ),
              _buildModernCard(
                title: "قراءات الطاقة المصدرة (Export)",
                icon: Icons.logout_rounded,
                children: [
                  _buildTextField("آخر قراءة مصدرة - كلي / عادي",
                      Icons.speed_rounded,
                      controller: _exportNormalController,
                      type: TextInputType.number),
                  _buildTextField("آخر قراءة مصدرة - وقت الذروة",
                      Icons.trending_up_rounded,
                      controller: _exportPeakController,
                      type: TextInputType.number),
                  _buildTextField("آخر قراءة مصدرة - خارج الذروة",
                      Icons.trending_down_rounded,
                      controller: _exportOffPeakController,
                      type: TextInputType.number),
                  _buildTextField("آخر قراءة مصدرة - جزئي 1",
                      Icons.access_time_rounded,
                      controller: _exportPartial1Controller,
                      type: TextInputType.number),
                  _buildTextField("آخر قراءة مصدرة - جزئي 2",
                      Icons.access_time_rounded,
                      controller: _exportPartial2Controller,
                      type: TextInputType.number),
                ],
              ),
              _buildModernCard(
                title: "الملاحظات الفنية",
                icon: Icons.notes_rounded,
                children: [
                  _buildTextField("أضف أي ملاحظات هنا...", Icons.edit_note_rounded,
                      controller: _notesController, maxLines: 3),
                ],
              ),
              _buildModernCard(
                title: "التوثيق الصوري (الكاميرا)",
                icon: Icons.camera_alt_outlined,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text("يرجى تصوير العداد والأختام بوضوح",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: _images.keys
                        .map((label) => _buildImagePickerItem(label))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: primarySkyBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: primarySkyBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon,
      {required TextEditingController controller,
      TextInputType type = TextInputType.text,
      bool readOnly = false,
      int maxLines = 1,
      Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: type,
            readOnly: readOnly,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primarySkyBlue, size: 20),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: backgroundGray.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primarySkyBlue, width: 1)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: backgroundGray.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12)),
      child: CheckboxListTile(
        title: Text(title,
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
        value: _checklist[title],
        activeColor: primarySkyBlue,
        checkboxShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onChanged: (v) => setState(() => _checklist[title] = v!),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildImagePickerItem(String label) {
    File? imageFile = _images[label];
    return GestureDetector(
      onTap: () => _pickImage(label),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundGray,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: imageFile != null ? primarySkyBlue : Colors.transparent,
              width: 2),
          image: imageFile != null
              ? DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover)
              : null,
        ),
        child: imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded,
                      color: primarySkyBlue.withValues(alpha: 0.5), size: 35),
                  const SizedBox(height: 8),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black26),
                child: const Center(
                    child: Icon(Icons.check_circle,
                        color: Colors.white, size: 40)),
              ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
            colors: [primarySkyBlue, primarySkyBlue.withValues(alpha: 0.8)]),
        boxShadow: [
          BoxShadow(
              color: primarySkyBlue.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _handleSave,
        icon: const Icon(Icons.save_rounded, color: Colors.white),
        label: const Text("حفظ وإرسال المعاملة",
            style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}
