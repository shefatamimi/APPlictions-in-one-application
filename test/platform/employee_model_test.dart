/// Parsing and merging of the `GetAppLoginUser` rows.
///
/// The two hosted applications return different row names and different
/// columns, and the dashboard depends on both being understood, so this is the
/// behaviour worth pinning down.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ideco_platform/platform/data/models/employee_model.dart';

/// Response shape of `app_id = 20` (field inspection): `<Table>` rows.
String inspectionResponse() => '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetAppLoginUserResponse xmlns="http://tempuri.org/">
      <GetAppLoginUserResult>
        <diffgr:diffgram xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1">
          <NewDataSet>
            <Table>
              <ID>4321</ID>
              <EMP_NO>1187</EMP_NO>
              <USERNAME>a.alsharif</USERNAME>
              <WORK_NAME>قسم مكافحة سرقات التيار</WORK_NAME>
              <WRK_SHOP_NUM>7</WRK_SHOP_NUM>
              <ORACLE_USER>IDECO_APP</ORACLE_USER>
              <SYS_MINOR>3</SYS_MINOR>
              <SYS_DESC>أسعد الشريف</SYS_DESC>
            </Table>
          </NewDataSet>
        </diffgr:diffgram>
      </GetAppLoginUserResult>
    </GetAppLoginUserResponse>
  </soap:Body>
</soap:Envelope>
''';

/// Response shape of `app_id = 49` (meter reading): `<tblusers>` rows with a
/// different column set — no name, but a workshop name.
String meterReadingResponse() => '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetAppLoginUserResponse xmlns="http://tempuri.org/">
      <GetAppLoginUserResult>
        <diffgr:diffgram xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1">
          <NewDataSet>
            <tblusers>
              <ID>4321</ID>
              <GM_FLAG>0</GM_FLAG>
              <EMP_NO>1187</EMP_NO>
              <WRK_SHOP_NAME>ورشة إربد الشمالية</WRK_SHOP_NAME>
              <WRK_SHOP_NUM>7</WRK_SHOP_NUM>
              <PER_ID>55</PER_ID>
            </tblusers>
          </NewDataSet>
        </diffgr:diffgram>
      </GetAppLoginUserResult>
    </GetAppLoginUserResponse>
  </soap:Body>
</soap:Envelope>
''';

/// What the service returns when the employee has no permission for the
/// requested `app_id` — the signal the platform uses to hide a card.
String emptyResponse() => '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetAppLoginUserResponse xmlns="http://tempuri.org/">
      <GetAppLoginUserResult>
        <diffgr:diffgram xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1" />
      </GetAppLoginUserResult>
    </GetAppLoginUserResponse>
  </soap:Body>
</soap:Envelope>
''';

void main() {
  group('EmployeeModel.fromXml', () {
    test('parses the inspection row (<Table>)', () {
      final employee = EmployeeModel.fromXml(inspectionResponse());

      expect(employee, isNotNull);
      expect(employee!.id, '4321');
      expect(employee.employeeNumber, '1187');
      expect(employee.username, 'a.alsharif');
      expect(employee.fullName, 'أسعد الشريف');
      expect(employee.department, 'قسم مكافحة سرقات التيار');
      expect(employee.workshopNumber, '7');
      expect(employee.workshopName, isEmpty);
    });

    test('parses the meter-reading row (<tblusers>)', () {
      final employee = EmployeeModel.fromXml(meterReadingResponse());

      expect(employee, isNotNull);
      expect(employee!.employeeNumber, '1187');
      expect(employee.workshopName, 'ورشة إربد الشمالية');
      expect(employee.department, isEmpty);
    });

    test('returns null for an empty result set (no entitlement)', () {
      expect(EmployeeModel.fromXml(emptyResponse()), isNull);
    });

    test('returns null for junk instead of throwing', () {
      expect(EmployeeModel.fromXml('not xml at all'), isNull);
      expect(EmployeeModel.fromXml(''), isNull);
    });
  });

  group('Employee.mergeWith', () {
    test('unions the columns of both applications', () {
      final merged = EmployeeModel.fromXml(inspectionResponse())!
          .mergeWith(EmployeeModel.fromXml(meterReadingResponse())!);

      expect(merged.fullName, 'أسعد الشريف');
      expect(merged.department, 'قسم مكافحة سرقات التيار');
      expect(merged.workshopName, 'ورشة إربد الشمالية');
      expect(merged.displayWorkshop, 'ورشة إربد الشمالية');
    });

    test('never overwrites a populated field with an empty one', () {
      final full = EmployeeModel.fromXml(inspectionResponse())!;
      final merged = full.mergeWith(EmployeeModel.empty);

      expect(merged.department, full.department);
      expect(merged.username, full.username);
    });

    test('falls back to the workshop number when no name is returned', () {
      final inspectionOnly = EmployeeModel.fromXml(inspectionResponse())!;
      expect(inspectionOnly.displayWorkshop, 'ورشة 7');
    });

    test('display helpers never render an empty string', () {
      const blank = EmployeeModel.empty;
      expect(blank.displayDepartment, '—');
      expect(blank.displayWorkshop, '—');
      expect(blank.initials, isNotEmpty);
    });
  });
}
