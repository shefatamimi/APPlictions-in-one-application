/// # EngineerModel
///
/// Data-layer model extending [EngineerEntity] with SOAP XML parsing.
///
/// **SOAP Method**: `GetGenericsDataTable`
/// **Query**: `DataType:73,Major:721`
/// **Fields**: `SYS_DESCL` (employee number), `SYS_DESC` (name)
library;

import 'package:xml/xml.dart';

import '../../domain/entities/engineer_entity.dart';

class EngineerModel extends EngineerEntity {
  const EngineerModel({required super.empNumber, required super.name});

  /// ## fromXmlList
  ///
  /// **SOAP Method**: `GetGenericsDataTable`
  /// **Query**: `DataType:73,Major:721`
  ///
  /// **Description**: Parses the full SOAP response and returns a list of
  /// [EngineerModel] instances — one per engineer row in the .NET DataSet.
  ///
  /// **Parameters**:
  /// - [xmlBody] — Raw SOAP response XML string.
  ///
  /// **Returns**: List of [EngineerModel]; empty list on parse failure.
  ///
  /// **Throws**: Never.
  static List<EngineerModel> fromXmlList(String xmlBody) {
    try {
      final document = XmlDocument.parse(xmlBody);
      final diffgram = document.descendants
          .whereType<XmlElement>()
          .where((e) => e.localName == 'diffgram')
          .firstOrNull;
      if (diffgram == null) return [];
      final dataSet = diffgram.childElements.firstOrNull;
      if (dataSet == null) return [];

      return dataSet.childElements
          .map((row) => EngineerModel(
                empNumber: _txt(row, 'SYS_DESCL'),
                name: _txt(row, 'SYS_DESC'),
              ))
          .where((e) => e.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _txt(XmlElement el, String tag) {
    try {
      return el.childElements
          .firstWhere((c) => c.localName == tag)
          .innerText
          .trim();
    } catch (_) {
      return '';
    }
  }
}
