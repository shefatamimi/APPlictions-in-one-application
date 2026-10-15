import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ideco_platform/features/submission/domain/entities/submission_entity.dart';
import 'package:ideco_platform/features/inquiry/domain/entities/customer_info_entity.dart';
import 'package:ideco_platform/core/widgets/barcode_scanner_screen.dart';

class InspectionMovementPage extends StatefulWidget {
  const InspectionMovementPage({super.key});

  @override
  State<InspectionMovementPage> createState() => _InspectionMovementPageState();
}

class _InspectionMovementPageState extends State<InspectionMovementPage> {
  static const Color primaryBlue = Color(0xFF0284C7);
  static const Color darkBlue = Color(0xFF0369A1);
  static const Color bgGray = Color(0xFFF1F5F9);

  final ImagePicker _picker = ImagePicker();
  dynamic _data;

  // ممسكات النصوص الأساسية والإضافية
  final _readingCtrl = TextEditingController();
  final _beneficiaryNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _breakerCapacityCtrl = TextEditingController();
  final _buildingComponentsCtrl = TextEditingController();
  final _tamperExplanationCtrl = TextEditingController();
  final _signatureCtrl = TextEditingController();

  final _policeNameCtrl = TextEditingController();
  final _policeNoteCtrl = TextEditingController();
  final _feederSubCtrl = TextEditingController();
  final _connSealNumCtrl = TextEditingController();
  final _boardSealNumCtrl = TextEditingController();
  final _assistantCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // صور التوثيق الشاملة
  final Map<String, File?> _images = {
    "صورة العداد (اجباري)": null,
    "صورة العبث": null,
    "تقرير الضابطة": null,
    "نموذج المراجعة": null,
    "حمل الفاز الأول": null,
    "الفاز الثاني": null,
    "الفاز الثالث": null,
    "حمل المتر": null,
    "صورة التلاعب": null,
    "تقرير الضابطة السابق": null,
    "نموذج المراجعة السابق": null,
  };

  // قيم القوائم المنسدلة والحقول
  String? _inspectionResult = '--اختر--';
  String? _phase = '--اختر--';
  String? _judicialPolice = '--اختر--';
  String? _inspectionReason = '--اختر--';
  String? _powerSource = '--اختر--';
  String? _connCoverSeal = '--اختر--';
  String? _boardSeal = '--اختر--';
  String? _futureAction = '--اختر--';
  String? _workTime = '--اختر--';
  String? _shiftType = '--اختر--';
  String? _tamperType = '--اختر--';
  String? _meterStatus = '--اختر--';
  String? _electricCar = '--اختر--';

  @override
  void dispose() {
    _readingCtrl.dispose();
    _beneficiaryNameCtrl.dispose();
    _phoneCtrl.dispose();
    _breakerCapacityCtrl.dispose();
    _buildingComponentsCtrl.dispose();
    _tamperExplanationCtrl.dispose();
    _signatureCtrl.dispose();
    _policeNameCtrl.dispose();
    _policeNoteCtrl.dispose();
    _feederSubCtrl.dispose();
    _connSealNumCtrl.dispose();
    _boardSealNumCtrl.dispose();
    _assistantCtrl.dispose();
    _driverCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data = ModalRoute.of(context)?.settings.arguments;
  }

  void _showPoliceNoteDialog() {
    final tempCtrl = TextEditingController(text: _policeNoteCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ملاحظة اسم الضابطة العدلية',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
        content: TextField(
          controller: tempCtrl,
          maxLines: 4,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظات الضابطة العدلية هنا...',
            filled: true,
            fillColor: bgGray,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'AdFont')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () {
              setState(() {
                _policeNoteCtrl.text = tempCtrl.text.trim();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم حفظ ملاحظة الضابطة العدلية',
                        textDirection: TextDirection.rtl)),
              );
            },
            child: const Text('حفظ',
                style: TextStyle(color: Colors.white, fontFamily: 'AdFont')),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRiskEmail(String riskType) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hamza.malkawi@ideco.com.jo,rawia.marwan@ideco.com.jo',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'إشعار نموذج المخاطر: $riskType',
        'body': 'تم رصد الحالة التالية أثناء التفتيش:\n$riskType\nرقم الاشتراك: $_subscriptionNum\nاسم المشترك: $_customerName',
      }),
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showRiskModelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نموذج المخاطر (TIC)',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('تم تركيب عداد بدون مرتجع',
                  style: TextStyle(fontFamily: 'AdFont', fontSize: 13)),
              leading:
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              onTap: () {
                Navigator.pop(ctx);
                _sendRiskEmail('تم تركيب عداد بدون مرتجع');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'تم إرسال إشعار نموذج المخاطر إلى حمزة ملكاوي وراوية مروان',
                          textDirection: TextDirection.rtl)),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('تم خلع عداد بدون تركيب عداد بديل',
                  style: TextStyle(fontFamily: 'AdFont', fontSize: 13)),
              leading: const Icon(Icons.error_outline_rounded, color: Colors.red),
              onTap: () {
                Navigator.pop(ctx);
                _sendRiskEmail('تم خلع عداد بدون تركيب عداد بديل');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'تم إرسال إشعار نموذج المخاطر إلى حمزة ملكاوي وراوية مروان',
                          textDirection: TextDirection.rtl)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'AdFont')),
          ),
        ],
      ),
    );
  }

  String get _customerName {
    if (_data is SubmissionEntity) {
      return (_data as SubmissionEntity).displayName;
    }
    if (_data is CustomerInfoEntity) {
      return (_data as CustomerInfoEntity).customerName;
    }
    return "غير معروف";
  }

  String get _subscriptionNum {
    if (_data is SubmissionEntity) {
      return (_data as SubmissionEntity).subscriptionNumber;
    }
    if (_data is CustomerInfoEntity) {
      return (_data as CustomerInfoEntity).formattedSubscription;
    }
    return "—";
  }

  Future<void> _pickImage(String label) async {
    try {
      final XFile? photo =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (photo != null) {
        setState(() => _images[label] = File(photo.path));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildFormSection(),
                    const SizedBox(height: 20),
                    _buildPhotoSection(),
                    const SizedBox(height: 20),
                    _buildNotesSection(),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
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
        gradient: LinearGradient(
          colors: [Color(0xFF38BDF8), primaryBlue, darkBlue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context)),
                  const Text('معلومات حركة تفتيش',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'AdFont',
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.flash_on_rounded,
                    color: Colors.white, size: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        children: [
          _infoRow(Icons.person_rounded, "المشترك", _customerName),
          const Divider(height: 24),
          _infoRow(Icons.tag_rounded, "رقم الاشتراك", _subscriptionNum),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                  child: _infoRow(Icons.home_repair_service_rounded, "الورشة",
                      "صيانة الشمال")),
              Expanded(child: _infoRow(Icons.numbers_rounded, "رقمها", "W-55")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryBlue),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey, fontFamily: 'AdFont')),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'AdFont')),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return _buildSectionCard(
      title: "بيانات التفتيش",
      icon: Icons.edit_document,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: _showRiskModelDialog,
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('نموذج المخاطر',
                style: TextStyle(fontFamily: 'AdFont')),
          ),
        ),
        const SizedBox(height: 10),
        _buildField(
            "اسم المنتفع الحالي", _beneficiaryNameCtrl, Icons.person_outline),
        _buildField("رقم الهاتف", _phoneCtrl, Icons.phone_rounded,
            type: TextInputType.phone),
        _buildDropdown("الفاز", Icons.electric_bolt_rounded,
            ['--اختر--', '1', '3'], _phase, (v) => setState(() => _phase = v)),
        _buildField("قدرة القاطع", _breakerCapacityCtrl, Icons.bolt_rounded,
            type: TextInputType.number),
        _buildField("مكونات البناء", _buildingComponentsCtrl,
            Icons.apartment_rounded),
        _buildField("قراءة العداد وقت الزيارة *", _readingCtrl,
            Icons.speed_rounded,
            type: TextInputType.number, isScanable: true),
        _buildDropdown(
            "نتيجة التفتيش على العداد *",
            Icons.fact_check_rounded,
            ['--اختر--', 'سليم', 'عبث', 'سليم بحاجة اجراء مستقبلي'],
            _inspectionResult,
            (v) => setState(() => _inspectionResult = v)),
        _buildDropdown(
            "نوع العبث *",
            Icons.warning_amber_rounded,
            ['--اختر--', 'تلاعب بالعداد', 'تلاعب بالكيبل', 'لا يوجد'],
            _tamperType,
            (v) => setState(() => _tamperType = v)),
        _buildField("شروحات العبث", _tamperExplanationCtrl, Icons.note_alt_rounded,
            maxLines: 5),
        _buildDropdown("ضابطة عدلية *", Icons.gavel_rounded,
            ['--اختر--', 'يوجد', 'لا يوجد'], _judicialPolice,
            (v) => setState(() => _judicialPolice = v)),
        Row(
          children: [
            Expanded(
              child: _buildField(
                  "اسم الضابطة العدلية", _policeNameCtrl, Icons.badge_rounded),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showPoliceNoteDialog,
              icon: Icon(
                _policeNoteCtrl.text.isNotEmpty
                    ? Icons.note_alt_rounded
                    : Icons.note_add_rounded,
                color:
                    _policeNoteCtrl.text.isNotEmpty ? Colors.green : primaryBlue,
              ),
              tooltip: 'إضافة أو تعديل ملاحظة',
            ),
          ],
        ),
        _buildDropdown("سبب التفتيش *", Icons.help_center_rounded,
            ['--اختر--', 'عشوائي', 'موجه', 'بلاغ'], _inspectionReason,
            (v) => setState(() => _inspectionReason = v)),
        _buildDropdown(
            "مصدر التغذية *",
            Icons.electrical_services_rounded,
            ['--اختر--', 'رسمي', 'عن طريق العبث', 'مفصول', 'من إشتراك مجاور'],
            _powerSource,
            (v) => setState(() => _powerSource = v)),
        _buildField("اشتراك المغذي", _feederSubCtrl, Icons.link_rounded),
        _buildDropdown("ختم غطاء التوصيلات *", Icons.lock_outline_rounded,
            ['--اختر--', 'يوجد', 'لا يوجد'], _connCoverSeal,
            (v) => setState(() => _connCoverSeal = v)),
        _buildField("رمز ختم التوصيلات", _connSealNumCtrl,
            Icons.confirmation_num_outlined),
        _buildDropdown("ختم اللوحة *", Icons.lock_person_rounded,
            ['--اختر--', 'يوجد', 'لا يوجد'], _boardSeal,
            (v) => setState(() => _boardSeal = v)),
        _buildField("رمز ختم اللوحة", _boardSealNumCtrl,
            Icons.confirmation_num_outlined),
        _buildDropdown("إجراء مستقبلي *", Icons.next_plan_rounded,
            ['--اختر--', 'يوجد', 'لا يوجد'], _futureAction,
            (v) => setState(() => _futureAction = v)),
        _buildDropdown("دوام رسمي *", Icons.work_history_rounded,
            ['--اختر--', 'داخل اوقات العمل الرسمي', 'خارج اوقات العمل الرسمي'],
            _workTime, (v) => setState(() => _workTime = v)),
        _buildDropdown("نوع الشفت *", Icons.schedule_rounded,
            ['--اختر--', 'نهاري', 'مسائي'], _shiftType,
            (v) => setState(() => _shiftType = v)),
        _buildDropdown("حالة العداد", Icons.settings_input_component_rounded,
            ['--اختر--', 'سليم', 'عاطل'], _meterStatus,
            (v) => setState(() => _meterStatus = v)),
        _buildDropdown("سيارة كهربائية", Icons.electric_car_rounded,
            ['--اختر--', 'يوجد', 'لا يوجد', 'لا يمكن التحديد'], _electricCar,
            (v) => setState(() => _electricCar = v)),
        _buildField("اسم المساعد (مساعد رئيس الورشة)", _assistantCtrl,
            Icons.person_add_alt_rounded),
        _buildField("اسم السائق المرافق", _driverCtrl, Icons.drive_eta_rounded),
        _buildField("التوقيع الفني", _signatureCtrl, Icons.draw_rounded),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return _buildSectionCard(
      title: "التوثيق الصوري",
      icon: Icons.camera_alt_rounded,
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 125,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: _images.keys.map((label) {
              return Container(
                width: 115,
                margin: const EdgeInsets.only(left: 10),
                child: _buildImagePicker(label),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSectionCard(
      title: "ملاحظات إضافية",
      icon: Icons.notes_rounded,
      children: [
        TextField(
          controller: _notesCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "أدخل أي ملاحظات هنا...",
            filled: true,
            fillColor: bgGray.withValues(alpha: 0.5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'AdFont'))
          ]),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text,
      bool isScanable = false,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: primaryBlue),
          suffixIcon: isScanable
              ? IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded,
                      color: primaryBlue, size: 20),
                  tooltip: 'مسح الباركود بالكاميرا',
                  onPressed: () async {
                    final scanned = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BarcodeScannerScreen()),
                    );
                    if (scanned != null && scanned.isNotEmpty) {
                      setState(() => ctrl.text = scanned);
                    }
                  },
                )
              : null,
          filled: true,
          fillColor: bgGray.withValues(alpha: 0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, List<String> items,
      String? value, ValueChanged<String?> onChanged) {
    final currentValue =
        (value != null && items.contains(value)) ? value : items.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        initialValue: currentValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: primaryBlue),
          filled: true,
          fillColor: bgGray.withValues(alpha: 0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: const TextStyle(fontSize: 13, fontFamily: 'AdFont'))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildImagePicker(String label) {
    File? imageFile = _images[label];
    return GestureDetector(
      onTap: () => _pickImage(label),
      child: Container(
        decoration: BoxDecoration(
          color: bgGray,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: imageFile != null ? primaryBlue : Colors.transparent,
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
                      color: primaryBlue.withValues(alpha: 0.5), size: 30),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AdFont'),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black26),
                child: const Center(
                    child: Icon(Icons.check_circle,
                        color: Colors.white, size: 30)),
                ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حفظ حركة التفتيش بنجاح")),
          );
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: darkBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            shadowColor: Colors.transparent),
        child: const Text("حفظ وإرسال المعاملة",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'AdFont')),
      ),
    );
  }
}
