import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ideco_platform/core/theme/app_colors.dart';

class BluetoothDeviceListDialog extends StatefulWidget {
  const BluetoothDeviceListDialog({super.key});

  @override
  State<BluetoothDeviceListDialog> createState() => _BluetoothDeviceListDialogState();
}

class _BluetoothDeviceListDialogState extends State<BluetoothDeviceListDialog> {
  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results.where((r) => r.device.platformName.isNotEmpty).toList();
        });
      }
    });
    _startScan();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint("Scan Error: $e");
    }
    if (mounted) setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('أجهزة البلوتوث المتاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isScanning)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(icon: const Icon(Icons.refresh), onPressed: _startScan),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _scanResults.isEmpty
              ? const Center(child: Text('لم يتم العثور على أجهزة'))
              : ListView.separated(
                  itemCount: _scanResults.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final result = _scanResults[index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth, color: AppColors.primary),
                      title: Text(result.device.platformName),
                      subtitle: Text(result.device.remoteId.str),
                      onTap: () => Navigator.pop(context, result.device),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}
