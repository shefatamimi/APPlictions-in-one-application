import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
    if (mounted) setState(() {});
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  void _switchCamera() {
    _controller.switchCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'مسح الباركود بالكاميرا',
          style: TextStyle(fontFamily: 'AdFont', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0369A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            tooltip: 'الفلاش',
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'تبديل الكاميرا',
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 70, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'الكاميرا معطلة أو حُظرت الصلاحية',
                        style: TextStyle(fontFamily: 'AdFont', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'في نظام أندرويد عند رفض الصلاحية، يجب تفعيل الكاميرا يدوياً من إعدادات الجهاز.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'AdFont', fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0369A1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await openAppSettings();
                        },
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text(
                          'افتح إعدادات الجهاز لتفعيل الكاميرا',
                          style: TextStyle(fontFamily: 'AdFont', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            onDetect: (capture) {
              if (_hasScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.trim().isNotEmpty) {
                  _hasScanned = true;
                  Navigator.of(context).pop(rawValue.trim());
                  break;
                }
              }
            },
          ),
          
          // Green Laser & Scanner Frame Box Overlay
          const Center(
            child: _ScannerFrameBox(),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.2),
                      blurRadius: 15,
                    )
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Colors.greenAccent, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'قم بتوجيه الكاميرا نحو الباركود',
                      style: TextStyle(
                        fontFamily: 'AdFont',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrameBox extends StatelessWidget {
  const _ScannerFrameBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 270,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        children: [
          // Green Corner Brackets
          Positioned(top: 0, left: 0, child: _corner(0)),
          Positioned(top: 0, right: 0, child: _corner(1)),
          Positioned(bottom: 0, left: 0, child: _corner(2)),
          Positioned(bottom: 0, right: 0, child: _corner(3)),
          // Center Animated Green Laser Line
          const Center(child: _ScannerAnimation()),
        ],
      ),
    );
  }

  Widget _corner(int index) {
    final bool isTop = index == 0 || index == 1;
    final bool isLeft = index == 0 || index == 2;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.greenAccent, width: 4.5) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.greenAccent, width: 4.5) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.greenAccent, width: 4.5) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.greenAccent, width: 4.5) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: index == 0 ? const Radius.circular(20) : Radius.zero,
          topRight: index == 1 ? const Radius.circular(20) : Radius.zero,
          bottomLeft: index == 2 ? const Radius.circular(20) : Radius.zero,
          bottomRight: index == 3 ? const Radius.circular(20) : Radius.zero,
        ),
      ),
    );
  }
}

class _ScannerAnimation extends StatefulWidget {
  const _ScannerAnimation();

  @override
  State<_ScannerAnimation> createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<_ScannerAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScannerLinePainter(_animController.value),
          child: const SizedBox(width: 250, height: 250),
        );
      },
    );
  }
}

class _ScannerLinePainter extends CustomPainter {
  final double progress;
  _ScannerLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Green Laser Line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.greenAccent.withValues(alpha: 0.1),
          Colors.greenAccent,
          Colors.greenAccent.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, y, size.width, 3))
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), linePaint);

    // Glowing Trail Effect below Laser Line
    if (progress > 0.05) {
      final glowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.greenAccent.withValues(alpha: 0.3),
            Colors.greenAccent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, y - 25, size.width, 25))
        ..style = PaintingStyle.fill;

      final glowRect = Rect.fromLTWH(10, y - 25, size.width - 20, 25);
      canvas.drawRect(glowRect, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
