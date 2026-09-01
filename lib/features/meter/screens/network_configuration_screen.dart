import 'package:flutter/material.dart';
import 'package:ideco_platform/core/theme/app_colors.dart';
import 'package:ideco_platform/features/meter/services/gprs_service.dart';

class NetworkConfigurationScreen extends StatefulWidget {
  final String? initialIp;
  final String? initialPort;
  final String? initialApn;
  final String? bluetoothAddress;
  final String? bluetoothName;

  const NetworkConfigurationScreen({
    super.key,
    this.initialIp,
    this.initialPort,
    this.initialApn,
    this.bluetoothAddress,
    this.bluetoothName,
  });

  @override
  State<NetworkConfigurationScreen> createState() => _NetworkConfigurationScreenState();
}

class _NetworkConfigurationScreenState extends State<NetworkConfigurationScreen> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  late final TextEditingController _apnController;
  
  String? _selectedPreset = 'إختر إعداد مسبق';
  bool _isSaving = false;
  bool _isReading = false;

  final List<String> _presets = [
    'إختر إعداد مسبق',
    'Holley - Production',
    'Hexing - Production',
    'Holley - Testing',
    'Hexing - Testing',
  ];

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.initialIp);
    _portController = TextEditingController(text: widget.initialPort);
    _apnController = TextEditingController(text: widget.initialApn);
    
    // محاولة القراءة تلقائياً عند فتح الشاشة كما في الكود الأصلي
    WidgetsBinding.instance.addPostFrameCallback((_) => _readCurrentConfiguration());
  }

  void _readCurrentConfiguration() async {
    setState(() => _isReading = true);
    try {
      final result = await GPRSService.readNetworkConfig(
        bluetoothAddress: widget.bluetoothAddress ?? "00:11:22:33:44:55",
        bluetoothName: widget.bluetoothName ?? "BSC-Probe-01",
      );

      if (mounted) {
        if (!result.contains("ERROR") && !result.contains("TIMEOUT")) {
          final parts = result.split(":");
          if (parts.length >= 3) {
            setState(() {
              _ipController.text = parts[0];
              _portController.text = parts[1];
              _apnController.text = parts[2];
            });
            _showSnackBar('تمت قراءة إعدادات العداد بنجاح', Colors.green);
          }
        }
        setState(() => _isReading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isReading = false);
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _apnController.dispose();
    super.dispose();
  }

  void _handleSaveConfiguration() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty || _apnController.text.isEmpty) {
      _showSnackBar('الرجاء التأكد من تعبئة جميع الحقول', AppColors.warning);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await GPRSService.writeNetworkConfig(
        bluetoothAddress: widget.bluetoothAddress ?? "00:11:22:33:44:55",
        bluetoothName: widget.bluetoothName ?? "BSC-Probe-01",
        ip: _ipController.text,
        port: _portController.text,
        apn: _apnController.text,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result.contains("بنجاح")) {
          _showSnackBar(result, AppColors.success);
        } else {
          _showSnackBar(result, AppColors.danger);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('خطأ في البرمجة: $e', AppColors.danger);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات برمجة الشبكة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isReading ? null : _readCurrentConfiguration,
          )
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            if (_isReading)
              const LinearProgressIndicator(backgroundColor: Colors.white, color: AppColors.primaryLight),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 25, offset: const Offset(0, 12))
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.settings_suggest_rounded, size: 60, color: AppColors.primaryLight),
                          const SizedBox(height: 10),
                          const Text(
                            'تعديل إعدادات GPRS',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 30),
                          
                          _buildPresetDropdown(),
                          const SizedBox(height: 16),
                          
                          _buildInputField(
                            controller: _ipController,
                            label: 'IP Address (العنوان)',
                            icon: Icons.lan_outlined,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputField(
                            controller: _portController,
                            label: 'Port (المنفذ)',
                            icon: Icons.numbers_rounded,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputField(
                            controller: _apnController,
                            label: 'APN (نقطة الوصول)',
                            icon: Icons.settings_input_antenna_rounded,
                          ),
                          
                          const SizedBox(height: 35),
                          
                          ElevatedButton(
                            onPressed: (_isSaving || _isReading) ? null : _handleSaveConfiguration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 4,
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'حفظ البرمجة للعداد',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    _buildInfoBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPreset,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          items: _presets.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedPreset = newValue;
              if (newValue != 'إختر إعداد مسبق') {
                if (newValue!.contains('Production')) {
                  _ipController.text = "10.10.20.50";
                  _portController.text = "4040";
                  _apnController.text = "ideco.m2m";
                } else if (newValue.contains('Testing')) {
                  _ipController.text = "192.168.10.15";
                  _portController.text = "8080";
                  _apnController.text = "test.apn";
                }
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.left,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'تأكد من بقاء جهاز الـ Probe متصلاً بالعداد أثناء عملية البرمجة.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
