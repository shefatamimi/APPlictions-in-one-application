/// # SubmissionPage
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ideco_platform/injection_container.dart';
import 'package:ideco_platform/features/submission/domain/entities/submission_entity.dart';
import 'package:ideco_platform/features/submission/presentation/cubit/submission_cubit.dart';
import 'package:ideco_platform/features/submission/presentation/cubit/submission_state.dart';
import 'package:ideco_platform/features/inquiry/presentation/pages/inquiry_page.dart';

class SubmissionPageArgs {
  final String workshopId;
  const SubmissionPageArgs(this.workshopId);
}

class SubmissionPage extends StatelessWidget {
  const SubmissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final workshopId = args is SubmissionPageArgs ? args.workshopId : '';
    return BlocProvider(
      create: (_) => sl<SubmissionCubit>()..loadSubmissions(workshopId),
      child: _SubmissionView(workshopId: workshopId),
    );
  }
}

class _SubmissionView extends StatelessWidget {
  const _SubmissionView({required this.workshopId});
  final String workshopId;

  static const _primary = Color(0xFF0284C7);
  static const _darkBlue = Color(0xFF0369A1);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F5F9),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocConsumer<SubmissionCubit, SubmissionState>(
                listener: (ctx, state) {
                  if (state is SubmissionFailure) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'AdFont')),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                builder: (ctx, state) {
                  if (state is SubmissionLoading) return _buildLoader();
                  if (state is SubmissionLoaded) {
                    return RefreshIndicator(
                      color: _primary,
                      onRefresh: () => ctx
                          .read<SubmissionCubit>()
                          .loadSubmissions(workshopId),
                      child: state.submissions.isEmpty
                          ? _buildEmpty()
                          : _buildList(ctx, state.submissions),
                    );
                  }
                  return RefreshIndicator(
                    color: _primary,
                    onRefresh: () =>
                        ctx.read<SubmissionCubit>().loadSubmissions(workshopId),
                    child: _buildEmpty(),
                  );
                },
              ),
            ),
            _buildBottomSync(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF38BDF8), _primary, _darkBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white, size: 22),
                        onPressed: () {}),
                    const Text('شركة كهرباء إربد',
                        style: TextStyle(
                            fontFamily: 'AdFont',
                            fontSize: 14,
                            color: Colors.white70)),
                    IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('إستعلام عن البلاغات',
                    style: TextStyle(
                        fontFamily: 'AdFont',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() =>
      const Center(child: CircularProgressIndicator(color: _primary));

  Widget _buildEmpty() => const Center(
      child: Text('لا توجد بلاغات حالياً',
          style: TextStyle(fontFamily: 'AdFont')));

  Widget _buildList(BuildContext ctx, List<SubmissionEntity> items) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _SubmissionCard(submission: items[i]),
    );
  }

  Widget _buildBottomSync(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            ctx.read<SubmissionCubit>().loadSubmissions(workshopId);
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text("جاري مزامنة البيانات...",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'AdFont'))));
          },
          icon: const Icon(Icons.sync_rounded, color: Colors.white),
          label: const Text("مزامنة البيانات",
              style: TextStyle(
                  fontFamily: 'AdFont',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF475569),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatefulWidget {
  const _SubmissionCard({required this.submission});
  final SubmissionEntity submission;

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _expanded = false;
  SubmissionEntity get s => widget.submission;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF0284C7)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.displayName,
                              style: const TextStyle(
                                  fontFamily: 'AdFont',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.speed_outlined,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(s.meterNum,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.blueGrey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (s.posX.isNotEmpty && s.posX != '-1')
                      const Icon(Icons.location_on_rounded,
                          color: Colors.green, size: 20),
                  ],
                ),
              ),
            ),
            if (_expanded) _buildCardBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBody(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _detailRow('رقم الإشتراك', s.subscriptionNumber),
          _detailRow('العنوان', s.address),
          _detailRow('هاتف المشترك', s.mobile),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: [
              _gridBtn('ادخال حركه التفتيش', Icons.engineering_rounded,
                  const Color(0xFF0284C7), () {
                Navigator.of(ctx)
                    .pushNamed('/inspection-movement', arguments: s);
              }),
              _gridBtn('انشاء معاملة تفتيش', Icons.assignment_rounded,
                  const Color(0xFF0369A1), () {
                Navigator.of(ctx)
                    .pushNamed('/inspection-movement', arguments: s);
              }),
              _gridBtn(
                  'ادخال حركة فصل و وصل',
                  Icons.electrical_services_rounded,
                  const Color(0xFF00897B), () {
                Navigator.of(ctx).pushNamed('/inquiry',
                    arguments: InquiryPageArgs(
                        mode: InquiryMode.connectionMovements,
                        initialMeterNum: s.meterNum));
              }),
              _gridBtn('انشاء زيارة تفتيش', Icons.visibility_rounded,
                  const Color(0xFF0EA5E9), () {
                Navigator.of(ctx)
                    .pushNamed('/inspection-movement', arguments: s);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontFamily: 'AdFont',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0369A1))),
          Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'AdFont',
                      color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _gridBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontFamily: 'AdFont',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
