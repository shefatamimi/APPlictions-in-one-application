/// # CoordinateDetails
///
/// One row of `GET_COORDINATE_APP_DATA` — the record the technician looked up
/// before stamping its coordinates.
///
/// The four `label` fields are intentionally generic: the service returns
/// `LABEL1…LABEL4` and their meaning depends on the selected record type
/// (transaction / subscription / transformer / pole). The UI resolves the
/// captions, the model stays dumb.
library;

class CoordinateDetails {
  final String label1;
  final String label2;
  final String label3;
  final String label4;
  final String meterNo;
  final String operationNo;
  final String notes;
  final double? latitude;
  final double? longitude;

  const CoordinateDetails({
    this.label1 = '',
    this.label2 = '',
    this.label3 = '',
    this.label4 = '',
    this.meterNo = '',
    this.operationNo = '',
    this.notes = '',
    this.latitude,
    this.longitude,
  });

  /// `true` when the row carries a usable map position.
  bool get hasPosition =>
      latitude != null && longitude != null && latitude != 0 && longitude != 0;

  /// Labels in index order, so the UI can zip them with its captions.
  List<String> get labels => [label1, label2, label3, label4];
}
