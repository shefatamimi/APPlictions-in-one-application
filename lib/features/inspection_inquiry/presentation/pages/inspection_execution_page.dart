import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class InspectionExecutionScreen extends StatefulWidget {
  const InspectionExecutionScreen({super.key});

  @override
  State<InspectionExecutionScreen> createState() =>
      _InspectionExecutionScreenState();
}

class _InspectionExecutionScreenState extends State<InspectionExecutionScreen> {
  final Color primaryBlue = const Color(0xFF0288D1);
  final Color secondaryBlue = const Color(0xFF01579B);
  final Color bgLight = const Color(0xFFF5F7FA);

  // إعدادات الكاميرا والصورة
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  children: [
                    _buildInquiryCard(),
                    const SizedBox(height: 20),
                    _buildWorkshopInfoCard(),
                    const SizedBox(height: 20),
                    _buildDetailsCard(),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
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
      padding: const EdgeInsets.only(bottom: 25, top: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [secondaryBlue, primaryBlue]),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            const Expanded(
                child: Text("تنفيذ معاملة تفتيش",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold))),
            const Icon(Icons.assignment_turned_in_rounded,
                color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryCard() {
    return _buildSectionCard(
      title: "بيانات المشترك",
      icon: Icons.person_search_rounded,
      children: [
        _buildInfoRow("اسم المشترك", ""),
        _buildInfoRow("رقم الاشتراك", ""),
        _buildInfoRow("رقم العداد", ""),
      ],
    );
  }

  Widget _buildWorkshopInfoCard() {
    return _buildSectionCard(
      title: "بيانات الورشة",
      icon: Icons.engineering_rounded,
      children: [
        _buildInfoRow("اسم الورشة", ""),
        _buildInfoRow("رقم الورشة", ""),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return _buildSectionCard(
      title: "بيانات التنفيذ",
      icon: Icons.edit_note_rounded,
      children: [
        _buildModernField("اسم المهندس", Icons.person_outline_rounded),
        _buildModernField("مساعد الورشة", Icons.group_outlined),
        _buildModernField(
            "السائق المرافق", Icons.directions_car_filled_outlined),
        const SizedBox(height: 10),
        _buildImageUploader(),
        const SizedBox(height: 20),
        _buildModernField("رقم الختم", Icons.pin_outlined),
        _buildModernField("الملاحظات", Icons.comment_bank_outlined,
            maxLines: 3),
      ],
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: primaryBlue),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold))
          ]),
          const Divider(height: 30),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
      ]),
    );
  }

  Widget _buildModernField(String hint, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryBlue),
          filled: true,
          fillColor: bgLight,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildImageUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("صورة العملية الميدانية",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black54)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
              image: _image != null
                  ? DecorationImage(
                      image: FileImage(_image!), fit: BoxFit.cover)
                  : null,
            ),
            child: _image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded,
                          color: primaryBlue, size: 45),
                      const SizedBox(height: 10),
                      const Text("اضغط لالتقاط صورة من الموقع",
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم إرسال المعاملة بنجاح"))),
        style: ElevatedButton.styleFrom(
            backgroundColor: secondaryBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
        child: const Text("حفظ وإرسال",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
