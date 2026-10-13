import 'package:xml/xml.dart' as xml;
import 'package:ideco_platform/core/api_client.dart';
import 'package:ideco_platform/core/constants/app_constants.dart';

class SettingsService {
  /// ## updatePassword
  /// 
  /// Updates the user's password using the `Update_User_Pass` SOAP method.
  static Future<String> updatePassword(String newPass, String userId) async {
    try {
      final data = "pw:$newPass,id:$userId,datatype:2";

      final response = await ApiClient.makeSoapRequest(
        AppConstants.soapUrl,
        "Update_User_Pass",
        ApiClient.encryptRSA(data),
      );

      final document = xml.XmlDocument.parse(response);
      final result = document.findAllElements("Update_User_PassResult");

      return result.isNotEmpty
          ? result.first.innerText
          : "فشل تحديث كلمة المرور";
    } catch (e) {
      return "خطأ في الاتصال: $e";
    }
  }
}
