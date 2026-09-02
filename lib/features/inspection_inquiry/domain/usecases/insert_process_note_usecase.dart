import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/inspection_inquiry_repository.dart';

class InsertProcessNoteUseCase {
  final InspectionInquiryRepository _repository;

  const InsertProcessNoteUseCase(this._repository);

  Future<Either<Failure, String>> call({
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
  }) {
    return _repository.insertProcessNote(
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
  }
}
