/// # InspectionInquiryCubit
///
/// Cubit managing the state of the inspection process note inquiry screen.
///
/// ## Responsibilities
/// - Loads engineer list for the autocomplete on screen entry.
/// - Dispatches operation lookup on form submit.
/// - Handles clearing results for a new search.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/engineer_entity.dart';
import '../../domain/usecases/get_engineers_usecase.dart';
import '../../domain/usecases/get_operation_usecase.dart';
import 'inspection_inquiry_state.dart';

class InspectionInquiryCubit extends Cubit<InspectionInquiryState> {
  final GetOperationUseCase _getOperation;
  final GetEngineersUseCase _getEngineers;

  List<EngineerEntity> _engineers = [];

  InspectionInquiryCubit({
    required GetOperationUseCase getOperationUseCase,
    required GetEngineersUseCase getEngineersUseCase,
  })  : _getOperation = getOperationUseCase,
        _getEngineers = getEngineersUseCase,
        super(const InspectionInquiryInitial());

  // ── loadEngineers ──────────────────────────────────────────────────────────

  /// ## loadEngineers
  ///
  /// **SOAP Method**: `GetGenericsDataTable` (DataType:73, Major:721)
  ///
  /// **Description**: Fetches the engineer list on screen init so the
  /// autocomplete dropdown is populated for the process note form.
  ///
  /// **Emits**: [EngineersLoaded] on success; silently emits [EngineersLoaded]
  /// with empty list on error (non-blocking).
  Future<void> loadEngineers() async {
    final result = await _getEngineers();
    result.fold(
      (_) {
        _engineers = [];
        emit(const EngineersLoaded([]));
      },
      (engineers) {
        _engineers = engineers;
        emit(EngineersLoaded(engineers));
      },
    );
  }

  // ── searchOperation ────────────────────────────────────────────────────────

  /// ## searchOperation
  ///
  /// **SOAP chain**: `GetWFTRANSACTIONSBiIllegalProcessNote` (DataType:2)
  ///                 → `GetBiIllegalProcessNote` (DataType:1)
  ///
  /// **Description**: Looks up the illegal inspection process operation
  /// identified by [pid] and emits the result.
  ///
  /// **Parameters**:
  /// - [pid] — Numeric operation identifier string.
  ///
  /// **Emits**: [InspectionInquiryLoading] →
  /// [OperationLoaded] | [InspectionInquiryFailure].
  Future<void> searchOperation(String pid) async {
    if (pid.trim().isEmpty) return;
    emit(const InspectionInquiryLoading());

    final result = await _getOperation(pid.trim());
    result.fold(
      (failure) => emit(InspectionInquiryFailure(
          message: failure.message, engineers: _engineers)),
      (operation) =>
          emit(OperationLoaded(operation: operation, engineers: _engineers)),
    );
  }

  // ── clearSearch ────────────────────────────────────────────────────────────

  /// ## clearSearch
  ///
  /// **Description**: Resets the screen to its ready state so a new operation
  /// number can be entered. Called when the user taps "مسح".
  void clearSearch() {
    emit(EngineersLoaded(_engineers));
  }
}
