/// # CoordinateCapturePage
///
/// Entry screen of the meter-reading module: locate the record, verify GPS
/// accuracy, attach a field photo and store the position.
///
/// Ported from the standalone `Coordinates` application with its field logic
/// intact — same record types, same 15 m accuracy gate, same today's-points
/// overlay, same SOAP payloads. What changed is the shell: identity comes from
/// the platform session, the styling comes from the platform theme, and logging
/// out is the platform's job, not the module's.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../platform/domain/entities/platform_session.dart';
import '../data/coordinates_api.dart';
import '../data/models/coordinate_details.dart';
import '../data/models/field_transaction.dart';
import '../data/models/generic_type.dart';
import 'transactions_inquiry_page.dart';

class CoordinateCapturePage extends StatefulWidget {
  const CoordinateCapturePage({
    super.key,
    required this.api,
    required this.session,
  });

  final CoordinatesApi api;
  final PlatformSession session;

  @override
  State<CoordinateCapturePage> createState() => _CoordinateCapturePageState();
}

class _CoordinateCapturePageState extends State<CoordinateCapturePage> {
  /// Maximum tolerated GPS error. Above this the save is refused — a stamped
  /// asset is worthless if the position is a guess.
  static const double _accuracyThresholdMeters = 15;

  /// Fallback camera position (Irbid) until the first GPS fix arrives.
  static const LatLng _defaultCenter = LatLng(32.5568, 35.8469);

  GoogleMapController? _mapController;
  LatLng _userLocation = _defaultCenter;
  String _longitude = '0.0';
  String _latitude = '0.0';
  double _accuracy = 0;
  bool _hasFix = false;
  bool _locationGranted = false;
  MapType _mapType = MapType.normal;
  Set<Marker> _todayMarkers = const {};

  List<GenericType> _types = const [];
  bool _isLoadingTypes = true;
  String? _selectedMinor;
  String? _selectedTypeName;

  final _recordController = TextEditingController();
  final _meterController = TextEditingController();
  final _operationController = TextEditingController();
  final _notesController = TextEditingController();

  CoordinateDetails? _record;
  bool _showRecord = false;
  File? _photo;
  String _photoBase64 = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTypes();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadTodayPoints();
      await _requestLocation();
      if (_locationGranted) _listenToLocation();
    });
  }

  @override
  void dispose() {
    _recordController.dispose();
    _meterController.dispose();
    _operationController.dispose();
    _notesController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Location ──────────────────────────────────────────────────────────────

  Future<void> _requestLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        showAppSnack(context, 'يرجى تفعيل خدمة الموقع (GPS) لضمان دقة الرصد');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!granted) {
        if (mounted) {
          showAppSnack(context, 'لم يتم منح صلاحية الموقع', isError: true);
        }
        return;
      }

      if (mounted) setState(() => _locationGranted = true);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _applyPosition(position);
      _centerOnUser();
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'تعذر تحديد الموقع الحالي', isError: true);
      }
    }
  }

  void _listenToLocation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((position) {
      if (mounted) _applyPosition(position);
    });
  }

  void _applyPosition(Position position) {
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _longitude = position.longitude.toString();
      _latitude = position.latitude.toString();
      _accuracy = position.accuracy;
      _hasFix = true;
    });
  }

  void _centerOnUser() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLocation, zoom: 18),
      ),
    );
  }

  void _centerOn(double latitude, double longitude) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(latitude, longitude), zoom: 18),
      ),
    );
  }

  bool get _accuracyIsGood =>
      _hasFix && _accuracy > 0 && _accuracy <= _accuracyThresholdMeters;

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadTypes() async {
    setState(() => _isLoadingTypes = true);
    try {
      final types = await widget.api.fetchRecordTypes();
      if (!mounted) return;
      setState(() {
        _types = types.isNotEmpty ? types : _fallbackTypes;
        _isLoadingTypes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _types = _fallbackTypes;
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _loadTodayPoints() async {
    try {
      final points =
          await widget.api.fetchTodayPoints(widget.session.employee.username);
      if (!mounted) return;
      setState(() {
        _todayMarkers = points
            .map(
              (point) => Marker(
                markerId:
                    MarkerId('today_${point.latitude}_${point.longitude}'),
                position: LatLng(point.latitude, point.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'نقطة تم رصدها اليوم'),
              ),
            )
            .toSet();
      });
    } catch (_) {
      // A failed overlay must not block capture — the markers are advisory.
    }
  }

  Future<void> _searchRecord() async {
    final value = _recordController.text.trim();
    if (_selectedMinor == null) {
      showAppSnack(context, 'يرجى اختيار النوع أولاً');
      return;
    }
    if (value.isEmpty) {
      showAppSnack(context, 'يرجى إدخال الرقم المطلوب');
      return;
    }

    showAppLoader(context);
    try {
      final rows = await widget.api.searchRecord(
        typeMinor: _selectedMinor!,
        value: value,
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loader

      if (rows.isEmpty) {
        setState(() {
          _showRecord = false;
          _record = null;
        });
        showAppMessage(context, message: _notFoundMessage, isError: true);
        return;
      }

      final row = rows.first;
      setState(() {
        _record = row;
        _showRecord = true;
        if (row.meterNo.isNotEmpty) _meterController.text = row.meterNo;
        if (row.operationNo.isNotEmpty) {
          _operationController.text = row.operationNo;
        }
        if (row.notes.isNotEmpty) _notesController.text = row.notes;
      });

      if (row.hasPosition) _centerOn(row.latitude!, row.longitude!);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppMessage(
        context,
        message: 'حدث خطأ في الاتصال بالخادم، يرجى المحاولة مرة أخرى',
        isError: true,
      );
    }
  }

  String get _notFoundMessage => switch (_selectedMinor) {
        '1' => 'رقم المعاملة غير صحيح',
        '2' => 'رقم الاشتراك غير صحيح',
        '3' => 'رقم المحول غير صحيح',
        '4' => 'رقم العمود غير صحيح',
        _ => 'الرقم غير صحيح',
      };

  Future<void> _takePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photo = file;
      _photoBase64 = base64Encode(bytes);
    });
  }

  Future<void> _save() async {
    if (!_hasFix) {
      showAppMessage(
        context,
        message: 'لم يتم تحديد موقعك بعد، يرجى الانتظار حتى يظهر مؤشر الدقة',
        isError: true,
      );
      return;
    }
    if (!_accuracyIsGood) {
      showAppMessage(
        context,
        message:
            'دقة الموقع الحالية (${_accuracy.toStringAsFixed(1)} متر) ضعيفة. '
            'يرجى الانتظار حتى تصبح ${_accuracyThresholdMeters.toInt()} متر أو أقل.',
        isError: true,
      );
      return;
    }
    if (_selectedMinor == null || _recordController.text.trim().isEmpty) {
      showAppMessage(
        context,
        message: 'يجب اختيار النوع وإدخال الرقم',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    showAppLoader(context, message: 'جاري حفظ الإحداثيات...');

    try {
      final result = await widget.api.insertCoordinates(
        longitude: _longitude,
        latitude: _latitude,
        entryUser: widget.session.employee.username,
        typeMinor: _selectedMinor!,
        typeName: _selectedTypeName ?? '',
        recordNumber: _recordController.text.trim(),
        meterNo: _meterController.text.trim(),
        operationNo: _operationController.text.trim(),
        note: _notesController.text.trim(),
        imageBase64: _photoBase64,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loader
      setState(() => _isSaving = false);

      // Only an explicit negative result means the service refused the record;
      // an unreadable result element is treated as stored, as before.
      if (result != null && result < 0) {
        showAppMessage(
          context,
          message: 'لم يتم حفظ البيانات، يرجى المحاولة مرة أخرى',
          isError: true,
        );
        return;
      }

      _resetForm();
      _loadTodayPoints();
      showAppMessage(context, message: 'تم حفظ الإحداثيات بنجاح');
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isSaving = false);
      showAppMessage(
        context,
        message: 'خطأ في الحفظ، يرجى التحقق من الاتصال والمحاولة مرة أخرى',
        isError: true,
      );
    }
  }

  void _resetForm() {
    setState(() {
      _recordController.clear();
      _meterController.clear();
      _operationController.clear();
      _notesController.clear();
      _photo = null;
      _photoBase64 = '';
      _record = null;
      _showRecord = false;
    });
  }

  Future<void> _openInquiry() async {
    final result = await Navigator.of(context).push<FieldTransaction>(
      MaterialPageRoute(
        builder: (_) => TransactionsInquiryPage(
          api: widget.api,
          session: widget.session,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _recordController.text = result.subscriptionNo;
      if (result.meterNo.isNotEmpty) _meterController.text = result.meterNo;
      if (result.operationNo.isNotEmpty) {
        _operationController.text = result.operationNo;
      }

      final match = _types
          .where((t) => t.description.trim() == result.type.trim())
          .firstOrNull;
      if (match != null) {
        _selectedMinor = match.minor;
        _selectedTypeName = match.description;
      }
    });

    if (_selectedMinor != null && _recordController.text.isNotEmpty) {
      await _searchRecord();
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قراءة العدادات والإحداثيات'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              _loadTypes();
              _loadTodayPoints();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'استعلام المعاملات',
            onPressed: _openInquiry,
            icon: const Icon(Icons.manage_search_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Responsive.isWide(context)
            ? _buildWideLayout()
            : _buildNarrowLayout(),
      ),
    );
  }

  /// Phone layout: map on top, form underneath, one scroll view.
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 280, child: _buildMap()),
          _buildAccuracyBanner(),
          Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: _buildForm(),
          ),
        ],
      ),
    );
  }

  /// Tablet / desktop layout: map and form side by side so the technician can
  /// see the pin move while typing.
  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(child: _buildMap()),
              _buildAccuracyBanner(),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
            child: _buildForm(),
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        GoogleMap(
          mapType: _mapType,
          initialCameraPosition:
              CameraPosition(target: _userLocation, zoom: 18),
          onMapCreated: (controller) {
            _mapController = controller;
            if (_hasFix) _centerOnUser();
          },
          markers: _buildMarkers(),
          myLocationEnabled: _locationGranted,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          top: AppDimens.md,
          right: AppDimens.md,
          child: Column(
            children: [
              _mapButton(
                heroTag: 'mapType',
                icon: _mapType == MapType.normal
                    ? Icons.layers_rounded
                    : Icons.map_rounded,
                tooltip: 'تبديل نوع الخريطة',
                onPressed: () => setState(
                  () => _mapType = _mapType == MapType.normal
                      ? MapType.satellite
                      : MapType.normal,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              _mapButton(
                heroTag: 'myLocation',
                icon: Icons.my_location_rounded,
                tooltip: 'موقعي الحالي',
                onPressed: _centerOnUser,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapButton({
    required String heroTag,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      tooltip: tooltip,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primary,
      elevation: 3,
      onPressed: onPressed,
      child: Icon(icon, size: 20),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{..._todayMarkers};
    final record = _record;
    if (record != null && record.hasPosition) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_record'),
          position: LatLng(record.latitude!, record.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'موقع البحث: ${record.label1}'),
          zIndexInt: 5,
        ),
      );
    }
    return markers;
  }

  Widget _buildAccuracyBanner() {
    final good = _accuracyIsGood;
    final color = good ? AppColors.success : AppColors.warning;
    final background = good
        ? AppColors.successSurface
        : AppColors.warning.withValues(alpha: 0.10);

    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(good ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              size: 18, color: color),
          const SizedBox(width: AppDimens.sm),
          Flexible(
            child: Text(
              _hasFix
                  ? 'دقة الموقع: ${_accuracy.toStringAsFixed(1)} متر'
                      '${good ? '' : ' — انتظر لتحسين الدقة'}'
                  : 'جاري تحديد الموقع...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeDropdown(),
            const SizedBox(height: AppDimens.lg),
            TextField(
              controller: _recordController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (_showRecord) setState(() => _showRecord = false);
              },
              onSubmitted: (_) => _searchRecord(),
              decoration: InputDecoration(
                labelText: 'رقم ${_selectedTypeName ?? 'المعاملة'}',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: IconButton(
                  tooltip: 'بحث',
                  icon: const Icon(Icons.search_rounded,
                      color: AppColors.primary),
                  onPressed: _searchRecord,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            TextField(
              controller: _meterController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'رقم العداد (اختياري)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: Icon(Icons.speed_outlined,
                    size: 20, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            TextField(
              controller: _operationController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'رقم العملية (اختياري)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: Icon(Icons.confirmation_number_outlined,
                    size: 20, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            TextField(
              controller: _notesController,
              textAlign: TextAlign.right,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                alignLabelWithHint: true,
              ),
            ),
            if (_showRecord && _record != null) ...[
              const Divider(height: AppDimens.xxxl),
              _buildRecordSummary(_record!),
              const SizedBox(height: AppDimens.xl),
              _buildPhotoPicker(),
            ],
            const SizedBox(height: AppDimens.xxl),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_rounded, size: 20),
              label: const Text('حفظ الإحداثيات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedMinor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'نوع السجل',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: _isLoadingTypes ? 'جاري تحميل القائمة...' : 'اختر النوع',
        suffixIcon: _isLoadingTypes
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: 'تحديث القائمة',
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _loadTypes,
              ),
      ),
      items: _types
          .map(
            (type) => DropdownMenuItem<String>(
              value: type.minor,
              child: Row(
                children: [
                  Icon(iconForType(type.description),
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Text(type.description, textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedMinor = value;
          _selectedTypeName =
              _types.firstWhere((t) => t.minor == value).description;
          _showRecord = false;
        });
      },
    );
  }

  Widget _buildRecordSummary(CoordinateDetails record) {
    final captions = _captionsForSelectedType();

    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppDimens.sm),
              Text('بيانات السجل',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppDimens.md),
          for (var i = 0; i < captions.length; i++)
            if (captions[i].isNotEmpty && record.labels[i].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(captions[i],
                          style: Theme.of(context).textTheme.labelMedium),
                    ),
                    Expanded(
                      child: Text(
                        record.labels[i],
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /// Captions of `LABEL1…LABEL4` for the selected record type — the service
  /// returns positional columns whose meaning depends on the type.
  List<String> _captionsForSelectedType() {
    final description = _selectedTypeName?.trim() ?? '';

    if (_selectedMinor == '1' || description.contains('معاملة')) {
      return const ['اسم المشترك', 'المدينة', 'نوع المعاملة', ''];
    }
    if (_selectedMinor == '2' || description.contains('اشتراك')) {
      return const ['اسم المشترك', 'المدينة', 'نوع الاشتراك', 'رقم العداد'];
    }
    if (_selectedMinor == '3' || description.contains('محول')) {
      return const ['الرقم التسلسلي', 'الموقع', 'نوع المحول', ''];
    }
    if (_selectedMinor == '4' || description.contains('عمود')) {
      return const ['رقم العمود', 'الموقع', 'نوع العمود', ''];
    }
    return const ['', '', '', ''];
  }

  Widget _buildPhotoPicker() {
    final hasPhoto = _photo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppDimens.sm),
            Text('صورة الميدان', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: AppDimens.md),
        InkWell(
          onTap: _takePhoto,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: AnimatedContainer(
            duration: AppDimens.fast,
            height: 160,
            decoration: BoxDecoration(
              color: hasPhoto ? null : AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                color: hasPhoto ? AppColors.success : AppColors.outline,
                width: hasPhoto ? 2 : 1.4,
              ),
            ),
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd - 2),
                    child: Image.file(_photo!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 38, color: AppColors.primary),
                      const SizedBox(height: AppDimens.sm),
                      Text('اضغط لالتقاط صورة',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  static const List<GenericType> _fallbackTypes = [
    GenericType(description: 'معاملة', major: '324', minor: '1'),
    GenericType(description: 'اشتراك', major: '324', minor: '2'),
    GenericType(description: 'محول', major: '324', minor: '3'),
    GenericType(description: 'عمود', major: '324', minor: '4'),
  ];
}
