import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:ideco_platform/features/submission/domain/entities/submission_entity.dart';
import 'package:ideco_platform/features/inquiry/domain/entities/customer_info_entity.dart';

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

  // ممسكات النصوص
  final _readingCtrl = TextEditingController();
  final _policeNameCtrl = TextEditingController();
  final _feederSubCtrl = TextEditingController();
  final _connSealNumCtrl = TextEditingController();
  final _boardSealNumCtrl = TextEditingController();
  final _assistantCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // صور التوثيق
  final Map<String, File?> _images = {
    "صورة العبث": null,
    "تقرير الضابطة": null,
    "نموذج المراجعة": null,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data = ModalRoute.of(context)?.settings.arguments;
  }

  String get _customerName {
    if (_data is SubmissionEntity)
      return (_data as SubmissionEntity).displayName;
    if (_data is CustomerInfoEntity)
      return (_data as CustomerInfoEntity).customerName;
    return "غير معروف";
  }

  String get _subscriptionNum {
    if (_data is SubmissionEntity)
      return (_data as SubmissionEntity).subscriptionNumber;
    if (_data is CustomerInfoEntity)
      return (_data as CustomerInfoEntity).formattedSubscription;
    return "—";
  }

  Future<void> _pickImage(String label) async {
    try {
      final XFile? photo =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (photo != null) setState(() => _images[label] = File(photo.path));
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)
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
        _buildField("قراءة العداد *", _readingCtrl, Icons.speed_rounded,
            type: TextInputType.number),
        _buildDropdown(
            "ضابطة عدلية *", Icons.gavel_rounded, ["يوجد", "لا يوجد"]),
        _buildField("إسم الضابطة", _policeNameCtrl, Icons.badge_rounded),
        _buildDropdown(
            "شرطة *", Icons.local_police_rounded, ["يوجد", "لا يوجد"]),
        _buildDropdown("عدد أفراد الشرطة", Icons.people_alt_rounded,
            ["0", "1", "2", "3", "4", "5", "6+"]),
        _buildDropdown("سبب التفتيش *", Icons.help_center_rounded,
            ["عشوائي", "موجه", "بلاغ"]),
        _buildDropdown("مصدر التغذية *", Icons.electrical_services_rounded,
            ["رسمي", "عن طريق العبث", "مفصول", "من إشتراك مجاور"]),
        _buildField("إشتراك المغذي", _feederSubCtrl, Icons.link_rounded),
        _buildDropdown("ختم غطاء التوصيلات *", Icons.lock_outline_rounded,
            ["سليم", "عاطل"]),
        _buildField("رقم ختم التوصيلات", _connSealNumCtrl,
            Icons.confirmation_num_outlined),
        _buildDropdown(
            "ختم اللوحة *", Icons.lock_person_rounded, ["سليم", "عاطل"]),
        _buildField("رقم ختم اللوحة", _boardSealNumCtrl,
            Icons.confirmation_num_outlined),
        _buildDropdown("إجراء مستقبلي *", Icons.next_plan_rounded,
            ["لا يوجد", "متابعة", "فصل"]),
        _buildDropdown("دوام رسمي *", Icons.work_history_rounded,
            ["داخل الأوقات", "خارج الأوقات"]),
        _buildDropdown(
            "نوع الشفت *", Icons.schedule_rounded, ["نهاري", "مسائي"]),
        _buildDropdown("نوع العبث *", Icons.warning_amber_rounded,
            ["تلاعب بالعداد", "تلاعب بالكيبل", "لا يوجد"]),
        _buildDropdown(
            "رسالة نصية", Icons.sms_rounded, ["يلزم الإرسال", "لا يلزم"]),
        _buildDropdown("حالة العداد *", Icons.settings_input_component_rounded,
            ["سليم", "عاطل"]),
        _buildDropdown("سيارة كهربائية", Icons.electric_car_rounded,
            ["يوجد", "لا يوجد", "لا يمكن التحديد"]),
        _buildField(
            "مساعد الورشة", _assistantCtrl, Icons.person_add_alt_rounded),
        _buildField("السائق المرافق", _driverCtrl, Icons.drive_eta_rounded),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return _buildSectionCard(
      title: "التوثيق الصوري",
      icon: Icons.camera_alt_rounded,
      children: [
        const SizedBox(height: 10),
        Row(
          children: _images.keys
              .map((label) => Expanded(
                    child: _buildImagePicker(label),
                  ))
              .toList(),
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
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
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(fontSize: 14),
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
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: primaryBlue),
          filled: true,
          fillColor: bgGray.withValues(alpha: 0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
            .toList(),
        onChanged: (v) {},
      ),
    );
  }

  Widget _buildImagePicker(String label) {
    File? img = _images[label];
    return GestureDetector(
      onTap: () => _pickImage(label),
      child: Container(
        margin: const EdgeInsets.all(4),
        height: 100,
        decoration: BoxDecoration(
            color: bgGray,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: img != null ? primaryBlue : Colors.transparent,
                width: 1.5)),
        child: img == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_a_photo_rounded,
                    color: Colors.grey, size: 24),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center)
              ])
            : ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(img, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(colors: [primaryBlue, darkBlue]),
          boxShadow: [
            BoxShadow(
                color: primaryBlue.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: ElevatedButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("جاري حفظ البيانات...", textAlign: TextAlign.center))),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
        child: const Text('حفـظ الحركـة',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'AdFont')),
      ),
    );
  }
}
