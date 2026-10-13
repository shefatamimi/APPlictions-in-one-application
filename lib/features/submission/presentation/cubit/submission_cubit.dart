/// # SubmissionCubit
///
/// Manages state for the "إستعلام بلاغات" screen by loading all
/// illegal-notification records for the logged-in employee's workshop.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_submissions_usecase.dart';
import 'submission_state.dart';

class SubmissionCubit extends Cubit<SubmissionState> {
  final GetSubmissionsUseCase _getSubmissions;

  SubmissionCubit(this._getSubmissions) : super(const SubmissionInitial());

  // ── loadSubmissions ────────────────────────────────────────────────────────

  /// ## loadSubmissions
  ///
  /// Fetches all illegal-notification records for [workshopId] and emits
  /// [SubmissionLoaded] on success or [SubmissionFailure] on error.
  ///
  /// **Parameters**:
  /// - [workshopId] — The logged-in user's workshop number
  ///   (from `Employee.workshopNumber`).
  Future<void> loadSubmissions(String workshopId) async {
    emit(const SubmissionLoading());
    final result = await _getSubmissions(workshopId);
    result.fold(
      (failure) => emit(SubmissionFailure(failure.message)),
      (submissions) => emit(SubmissionLoaded(submissions)),
    );
  }
}
