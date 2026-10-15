import 'package:flutter/material.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0284C7);
    const bgGray = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        title: const Text('مزامنة البيانات',
            style: TextStyle(
                fontFamily: 'AdFont',
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _syncActionCard(
              context,
              label: 'جلب البيانات من قاعدة البيانات',
              icon: Icons.download_rounded,
              color: primaryBlue,
              onTap: () => _showDownloadWarning(context),
            ),
            const SizedBox(height: 24),
            _syncActionCard(
              context,
              label: 'ارسال البيانات لقاعدة البيانات',
              icon: Icons.upload_rounded,
              color: Colors.green.shade600,
              onTap: () => _handleUploadData(context),
            ),
            const Spacer(),
            const Text(
              'تأكد من توفر اتصال مستقر بالإنترنت',
              style: TextStyle(
                  fontFamily: 'AdFont', color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDownloadWarning(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تنويه',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
        content: const Text(
          'يرجى العلم بأن عملية جلب البيانات ستؤدي لفقدان جميع البيانات التي تم جلبها أو إدخالها مسبقا, حيث أنه من المفضل إجراء عملية إرسال البيانات في البداية. هل ترغب بالمتابعة و إجراء عملية جلب للبيانات ؟',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: 'AdFont', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لا', style: TextStyle(fontFamily: 'AdFont')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7)),
            onPressed: () {
              Navigator.pop(ctx);
              _showProcess(context, 'جاري جلب البيانات من السيرفر...');
            },
            child: const Text('نعم',
                style: TextStyle(fontFamily: 'AdFont', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleUploadData(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('جاري إرسال البيانات للسيرفر...',
                    style: TextStyle(fontFamily: 'AdFont')),
              ],
            ),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading

      // Success Dialog matching Java buildi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('نجاح',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontFamily: 'AdFont', fontWeight: FontWeight.bold)),
          content: const Text('تم الإرسال بنجاح',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'AdFont')),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Return from sync page
              },
              child: const Text('حسناً',
                  style: TextStyle(fontFamily: 'AdFont', color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }

  Widget _syncActionCard(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: color.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProcess(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(msg, style: const TextStyle(fontFamily: 'AdFont')),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      Navigator.pop(context);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت عملية جلب البيانات بنجاح')));
    });
  }
}
