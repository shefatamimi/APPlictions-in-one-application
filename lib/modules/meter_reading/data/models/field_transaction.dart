/// # FieldTransaction
///
/// One row of `GetWFTRANSACTIONSBiIllegalProcessNote` as consumed by the
/// meter-reading module's inquiry screen.
library;

class FieldTransaction {
  final String province;
  final String town;
  final String subscriptionNo;
  final String type;
  final String phase;
  final String transformerNo;
  final String employeeName;
  final String section;
  final String date;
  final String operationNo;
  final String meterNo;
  final String dls;

  /// Longitude as stored by the service (`COORD_X`).
  final String x;

  /// Latitude as stored by the service (`COORD_Y`).
  final String y;

  const FieldTransaction({
    this.province = '',
    this.town = '',
    this.subscriptionNo = '',
    this.type = '',
    this.phase = '',
    this.transformerNo = '',
    this.employeeName = '',
    this.section = '',
    this.date = '',
    this.operationNo = '',
    this.meterNo = '',
    this.dls = '',
    this.x = '',
    this.y = '',
  });

  /// `true` when the row can be handed back to the map screen.
  bool get hasPosition => x.isNotEmpty && y.isNotEmpty;
}
