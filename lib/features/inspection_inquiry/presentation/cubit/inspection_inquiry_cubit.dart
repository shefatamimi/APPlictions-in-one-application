/// # InspectionInquiryCubit
///
/// Cubit managing the state of the inspection process note inquiry screen.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/engineer_entity.dart';
import '../../domain/usecases/get_engineers_usecase.dart';
import '../../domain/usecases/get_helper_workshops_usecase.dart';
import '../../domain/usecases/get_operation_usecase.dart';
import '../../domain/usecases/insert_process_note_usecase.dart';
import 'inspection_inquiry_state.dart';

class InspectionInquiryCubit extends Cubit<InspectionInquiryState> {
  final GetOperationUseCase _getOperation;
  final GetEngineersUseCase _getEngineers;
  final GetHelperWorkshopsUseCase _getHelperWorkshops;
  final InsertProcessNoteUseCase _insertProcessNote;

  List<EngineerEntity> _engineers = [];
  List<EngineerEntity> _workshops = [];

  InspectionInquiryCubit({
    required GetOperationUseCase getOperationUseCase,
    required GetEngineersUseCase getEngineersUseCase,
    required GetHelperWorkshopsUseCase getHelperWorkshopsUseCase,
    required InsertProcessNoteUseCase insertProcessNoteUseCase,
  })  : _getOperation = getOperationUseCase,
        _getEngineers = getEngineersUseCase,
        _getHelperWorkshops = getHelperWorkshopsUseCase,
        _insertProcessNote = insertProcessNoteUseCase,
        super(const InspectionInquiryInitial());

  // ── loadFormData ───────────────────────────────────────────────────────────

  /// Fetches engineers and workshops for the form.
  Future<void> loadFormData() async {
    final results = await Future.wait([
      _getEngineers(),
      _getHelperWorkshops(),
    ]);

    results[0].fold(
      (_) => _engineers = [],
      (engineers) => _engineers = engineers,
    );

    results[1].fold(
      (_) => _workshops = [],
      (workshops) => _workshops = workshops,
    );

    emit(FormReady(engineers: _engineers, helperWorkshops: _workshops));
  }

  // ── searchOperation ────────────────────────────────────────────────────────

  Future<void> searchOperation(String pid) async {
    if (pid.trim().isEmpty) return;
    emit(InspectionInquiryLoading(
        engineers: _engineers, helperWorkshops: _workshops));

    final result = await _getOperation(pid.trim());
    result.fold(
      (failure) => emit(InspectionInquiryFailure(
        message: failure.message,
        engineers: _engineers,
        helperWorkshops: _workshops,
      )),
      (operation) => emit(OperationLoaded(
        operation: operation,
        engineers: _engineers,
        helperWorkshops: _workshops,
      )),
    );
  }

  // ── submitProcessNote ──────────────────────────────────────────────────────

  Future<void> submitProcessNote({
    required String empNo,
    required String workshopNum,
    required String pid,
    required String stampNum,
    required String notes,
    required String engName,
    required String engNumber,
    required String helperWorkshopNum,
    required String driver,
    required String? base64Image,
  }) async {
    emit(InspectionSubmitting(
        engineers: _engineers, helperWorkshops: _workshops));

    final result = await _insertProcessNote(
      empNo: empNo,
      workshopNum: workshopNum,
      pid: pid,
      stampNum: stampNum,
      notes: notes,
      engName: engName,
      engNumber: engNumber,
      helperWorkshopNum: helperWorkshopNum,
      driver: driver,
      base64Image: base64Image,
    );

    result.fold(
      (failure) => emit(InspectionInquiryFailure(
        message: failure.message,
        engineers: _engineers,
        helperWorkshops: _workshops,
      )),
      (message) => emit(InspectionSuccess(
        message: message,
        engineers: _engineers,
        helperWorkshops: _workshops,
      )),
    );
  }

  // ── clearSearch ────────────────────────────────────────────────────────────

  void clearSearch() {
    emit(FormReady(engineers: _engineers, helperWorkshops: _workshops));
  }
}
