import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/engineer_entity.dart';
import '../repositories/inspection_inquiry_repository.dart';

class GetHelperWorkshopsUseCase {
  final InspectionInquiryRepository _repository;

  const GetHelperWorkshopsUseCase(this._repository);

  Future<Either<Failure, List<EngineerEntity>>> call() {
    return _repository.getHelperWorkshops();
  }
}
