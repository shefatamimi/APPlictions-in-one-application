/// # CityModel
///
/// Data-layer model extending [CityEntity] with SOAP XML parsing.
///
/// ## SOAP Call
///
/// **Method**: `GetCityNumber`
/// **Query**: `City:1,DataType:3`
/// **SOAP Action**: `http://tempuri.org/IBillingWcfsrv/GetCityNumber`
/// **Response fields**: `CTYM_CODE`, `CTYM_NAME`
library;

import '../../domain/entities/city_entity.dart';
import 'customer_info_model.dart';

class CityModel extends CityEntity {
  const CityModel({required super.code, required super.name});

  /// ## fromXmlList
  ///
  /// **SOAP Method**: `GetCityNumber`
  /// **Query**: `City:1,DataType:3`
  ///
  /// **Description**: Parses the full SOAP response from `GetCityNumber` and
  /// returns a list of [CityModel] instances — one per city row in the
  /// .NET DataSet diffgram.
  ///
  /// **Parameters**:
  /// - [xmlBody] — Raw SOAP response XML string.
  ///
  /// **Returns**: List of [CityModel]; empty list if no rows or parse error.
  ///
  /// **Throws**: Never.
  static List<CityModel> fromXmlList(String xmlBody) {
    try {
      final rows = CustomerInfoModel.findAllRows(xmlBody);
      return rows
          .map((row) => CityModel(
                code: CustomerInfoModel.readText(row, 'CTYM_CODE'),
                name: CustomerInfoModel.readText(row, 'CTYM_NAME'),
              ))
          .where((c) => c.code.isNotEmpty && c.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
