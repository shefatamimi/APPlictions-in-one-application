/// # SubmissionRepositoryImpl
///
/// Implements [SubmissionRepository] by delegating to
/// [SubmissionRemoteDataSource] and wrapping errors in [Failure].
library;

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/submission_entity.dart';
import '../../domain/repositories/submission_repository.dart';
import '../datasources/submission_remote_datasource.dart';

class SubmissionRepositoryImpl implements SubmissionRepository {
  final SubmissionRemoteDataSource _remote;
  const SubmissionRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<SubmissionEntity>>> getSubmissions(
      String workshopId) async {
    try {
      final models = await _remote.getSubmissions(workshopId);
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
