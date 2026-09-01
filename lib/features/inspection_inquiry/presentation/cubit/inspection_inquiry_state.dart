/// # InspectionInquiryState
///
/// Sealed state hierarchy for [InspectionInquiryCubit].
///
/// Flow:
/// ```
/// InspectionInquiryInitial
///   ↓ loadEngineers()
/// EngineersLoaded           (autocomplete ready)
///   ↓ searchOperation(pid)
/// InspectionInquiryLoading  (spinner)
///   ↓ result
/// OperationLoaded           (show result card)
///   or
/// InspectionInquiryFailure  (error message)
/// ```
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/engineer_entity.dart';
import '../../domain/entities/operation_entity.dart';

sealed class InspectionInquiryState extends Equatable {
  const InspectionInquiryState();
}

/// Initial state before screen interaction.
final class InspectionInquiryInitial extends InspectionInquiryState {
  const InspectionInquiryInitial();

  @override
  List<Object?> get props => [];
}

/// Engineer list loaded and form is ready.
final class EngineersLoaded extends InspectionInquiryState {
  final List<EngineerEntity> engineers;

  const EngineersLoaded(this.engineers);

  @override
  List<Object?> get props => [engineers];
}

/// A SOAP operation is in progress.
final class InspectionInquiryLoading extends InspectionInquiryState {
  const InspectionInquiryLoading();

  @override
  List<Object?> get props => [];
}

/// Operation lookup completed (may be not-found).
final class OperationLoaded extends InspectionInquiryState {
  final OperationEntity operation;
  final List<EngineerEntity> engineers;

  const OperationLoaded({
    required this.operation,
    required this.engineers,
  });

  @override
  List<Object?> get props => [operation, engineers];
}

/// A failure occurred (network or SOAP error).
final class InspectionInquiryFailure extends InspectionInquiryState {
  final String message;
  final List<EngineerEntity> engineers;

  const InspectionInquiryFailure({
    required this.message,
    this.engineers = const [],
  });

  @override
  List<Object?> get props => [message, engineers];
}
