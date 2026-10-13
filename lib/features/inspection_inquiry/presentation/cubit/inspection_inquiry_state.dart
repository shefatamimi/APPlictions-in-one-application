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
  final List<EngineerEntity> engineers;
  final List<EngineerEntity> helperWorkshops;

  const InspectionInquiryState({
    this.engineers = const [],
    this.helperWorkshops = const [],
  });

  @override
  List<Object?> get props => [engineers, helperWorkshops];
}

/// Initial state before screen interaction.
final class InspectionInquiryInitial extends InspectionInquiryState {
  const InspectionInquiryInitial();
}

/// Lists loaded and form is ready.
final class FormReady extends InspectionInquiryState {
  const FormReady({
    super.engineers,
    super.helperWorkshops,
  });
}

/// A SOAP operation is in progress.
final class InspectionInquiryLoading extends InspectionInquiryState {
  const InspectionInquiryLoading({
    super.engineers,
    super.helperWorkshops,
  });
}

/// Operation lookup completed (may be not-found).
final class OperationLoaded extends InspectionInquiryState {
  final OperationEntity operation;

  const OperationLoaded({
    required this.operation,
    super.engineers,
    super.helperWorkshops,
  });

  @override
  List<Object?> get props => [operation, ...super.props];
}

/// Submission started.
final class InspectionSubmitting extends InspectionInquiryState {
  const InspectionSubmitting({
    super.engineers,
    super.helperWorkshops,
  });
}

/// Submission succeeded.
final class InspectionSuccess extends InspectionInquiryState {
  final String message;

  const InspectionSuccess({
    required this.message,
    super.engineers,
    super.helperWorkshops,
  });

  @override
  List<Object?> get props => [message, ...super.props];
}

/// A failure occurred (network or SOAP error).
final class InspectionInquiryFailure extends InspectionInquiryState {
  final String message;

  const InspectionInquiryFailure({
    required this.message,
    super.engineers,
    super.helperWorkshops,
  });

  @override
  List<Object?> get props => [message, ...super.props];
}
