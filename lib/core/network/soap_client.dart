/// # SoapClient
///
/// Low-level HTTP SOAP 1.1 client that replicates the behaviour of
/// `ksoap2-android` used in the original project (`HttpTransportSE` +
/// `SoapSerializationEnvelope`).
///
/// Builds a raw SOAP envelope XML string, POSTs it to the service endpoint,
/// and returns the response body as a [String] for the caller to parse.
///
/// **Protocol**: SOAP 1.1 over HTTPS
/// **Content-Type**: `text/xml; charset=utf-8`
/// **dotNet mode**: `true` (matches `envelope.dotNet = true` in original)
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

class SoapClient {
  final http.Client _httpClient;

  const SoapClient(this._httpClient);

  /// ## call
  ///
  /// **Description**: Sends a SOAP 1.1 request to the IDECO WCF service.
  ///
  /// **Endpoint**: [AppConstants.soapUrl]
  /// **Content-Type**: `text/xml; charset=utf-8`
  ///
  /// **Parameters**:
  /// - [methodName] — SOAP operation name (e.g. `GetAppLoginUser`).
  /// - [soapAction] — Value for the `SOAPAction` HTTP header.
  /// - [bodyProperties] — Map of property name → value pairs added inside
  ///   the method element (e.g. `{'data': '<base64-encrypted-string>'}`).
  ///
  /// **Returns**: Raw SOAP response XML [String].
  ///
  /// **Throws**: [http.ClientException] on network errors, [Exception] on
  /// non-200 HTTP status — callers map these to [ServerFailure].
  Future<String> call({
    required String methodName,
    required String soapAction,
    Map<String, String> bodyProperties = const {},
  }) async {
    final envelope = _buildEnvelope(methodName, bodyProperties);

    final response = await _httpClient.post(
      Uri.parse(AppConstants.soapUrl),
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
        'SOAPAction': '"$soapAction"',
      },
      body: utf8.encode(envelope),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'SOAP call failed: HTTP ${response.statusCode} — ${response.body}',
      );
    }

    return utf8.decode(response.bodyBytes);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds a SOAP 1.1 envelope string matching the ksoap2 `dotNet=true` format.
  ///
  /// Example output for `GetAppLoginUser` with a `data` property:
  /// ```xml
  /// <?xml version="1.0" encoding="utf-8"?>
  /// <v:Envelope xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
  ///             xmlns:d="http://www.w3.org/2001/XMLSchema"
  ///             xmlns:c="http://schemas.xmlsoap.org/soap/encoding/"
  ///             xmlns:v="http://schemas.xmlsoap.org/soap/envelope/">
  ///   <v:Header />
  ///   <v:Body>
  ///     <GetAppLoginUser xmlns="http://tempuri.org/">
  ///       <data>...</data>
  ///     </GetAppLoginUser>
  ///   </v:Body>
  /// </v:Envelope>
  /// ```
  String _buildEnvelope(
    String methodName,
    Map<String, String> bodyProperties,
  ) {
    final propertiesXml = bodyProperties.entries
        .map((e) => '      <${e.key}>${_escapeXml(e.value)}</${e.key}>')
        .join('\n');

    return '''<?xml version="1.0" encoding="utf-8"?>
<v:Envelope xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:d="http://www.w3.org/2001/XMLSchema"
            xmlns:c="http://schemas.xmlsoap.org/soap/encoding/"
            xmlns:v="http://schemas.xmlsoap.org/soap/envelope/">
  <v:Header />
  <v:Body>
    <$methodName xmlns="${AppConstants.soapNamespace}">
$propertiesXml
    </$methodName>
  </v:Body>
</v:Envelope>''';
  }

  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
