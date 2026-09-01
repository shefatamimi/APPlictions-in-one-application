/// # SubmissionState
///
/// Sealed state class for [SubmissionCubit].
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/submission_entity.dart';

sealed class SubmissionState extends Equatable {
  const SubmissionState();
  @override
  List<Object?> get props => [];
}

/// Initial state — no data loaded yet.
final class SubmissionInitial extends SubmissionState {
  const SubmissionInitial();
}

/// Data is being fetched from the server.
final class SubmissionLoading extends SubmissionState {
  const SubmissionLoading();
}

/// Data was fetched successfully.
final class SubmissionLoaded extends SubmissionState {
  final List<SubmissionEntity> submissions;
  const SubmissionLoaded(this.submissions);
  @override
  List<Object?> get props => [submissions];
}

/// The fetch failed; [message] contains the Arabic error description.
final class SubmissionFailure extends SubmissionState {
  final String message;
  const SubmissionFailure(this.message);
  @override
  List<Object?> get props => [message];
}
