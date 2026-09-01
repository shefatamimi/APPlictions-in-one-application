/// # InspectionInquiryRepositoryImpl
///
/// Concrete implementation of [InspectionInquiryRepository] that chains two
/// SOAP calls for operation lookup and maps exceptions to [Failure] types.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/engineer_entity.dart';
import '../../domain/entities/operation_entity.dart';
import '../../domain/repositories/inspection_inquiry_repository.dart';
import '../datasources/inspection_inquiry_remote_datasource.dart';

class InspectionInquiryRepositoryImpl implements InspectionInquiryRepository {
  final InspectionInquiryRemoteDataSource _remote;

  const InspectionInquiryRepositoryImpl(this._remote);

  // ── getOperation ───────────────────────────────────────────────────────────

  /// **SOAP chain**: DataType:2 (WF transaction) → DataType:1 (process note)
  ///
  /// Fetches the workflow transaction first to get city + subscription, then
  /// merges in process note data (engineer, workshop, stamp, notes).
  @override
  Future<Either<Failure, OperationEntity>> getOperation(String pid) async {
    try {
      // Step 1: WF transaction (city + subscriptionNum)
      var model = await _remote.getWfTransaction(pid);

      // Step 2: merge process note (engineer, workshop, notes, stamp)
      if (model.isFound) {
        try {
          final noteXml = await _remote.getProcessNoteXml(pid);
          model = model.withProcessNote(noteXml);
        } catch (_) {
          // Non-fatal — return partial data
        }
      }

      return Right(model);
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  // ── getEngineers ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<EngineerEntity>>> getEngineers() async {
    try {
      final engineers = await _remote.getEngineers();
      return Right(engineers);
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
