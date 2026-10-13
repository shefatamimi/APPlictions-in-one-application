/// # AppConstants
///
/// Central configuration file for the revamp_eletric application.
/// Contains all SOAP API endpoint details, encryption keys, and app-wide constants
/// extracted from the original Android project's `KSoapClass.java`.
library;

class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // SOAP / WCF Service Configuration
  // ---------------------------------------------------------------------------

  /// Production SOAP endpoint for the IDECO billing WCF service.
  ///
  /// Original source: `KSoapClass.java` line 10.
  /// Alt URL (commented in original): `https://idecoapi.ideco.com.jo/IDECO_API_PROD/IdecoWcfsrv.svc`
  /// Dev URL (commented in original): `http://192.168.14.18/WebSite/PortalPublicWS/IdecoWcfsrv.svc`
  static const String soapUrl =
      'https://ideco.com.jo/IDECO_API_PROD/IdecoWcfsrv.svc';

  /// XML namespace for all SOAP operations.
  static const String soapNamespace = 'http://tempuri.org/';

  /// WCF service interface name used in SOAPAction headers.
  static const String soapInterface = 'IBillingWcfsrv';

  /// SOAP envelope version: SOAP 1.1 (matches `SoapEnvelope.VER11` in ksoap2).
  static const String soapEnvelopeVersion = '1.1';

  // ---------------------------------------------------------------------------
  // Login SOAP Method
  // ---------------------------------------------------------------------------

  /// SOAP method name for employee login.
  static const String loginMethodName = 'GetAppLoginUser';

  /// Full SOAPAction header value for [loginMethodName].
  static const String loginSoapAction =
      'http://tempuri.org/IBillingWcfsrv/GetAppLoginUser';

  /// Application ID sent in the login query to identify this app on the server.
  /// Value `20` is hardcoded in the original `LoginActvity.java`.
  static const int appId = 20;

  // ---------------------------------------------------------------------------
  // RSA Encryption Keys
  // ---------------------------------------------------------------------------
  // Both keys are embedded in the original `KSoapClass.java` (lines 15–16).
  // Algorithm: RSA/None/PKCS1Padding
  // The public key is used to encrypt outgoing payloads.
  // The private key is used by RSA.setKey() — kept here for parity but
  // the Flutter implementation only uses the public key for encryption.

  /// RSA public key (X.509 / SubjectPublicKeyInfo, Base64-encoded).
  static const String rsaPublicKey =
      'MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtysuzG+lFQ5oDPIDIigJ'
      '7l9/kiCsU3qJ0MaNsPzQLXPlrnGlx4x29gSeP5V8d5VVJt2X2vu9oO7+6cKa1rx'
      'PERGwGIZyqv8DU59nf7pIUjcQ0IwXJwY0h5wBEcgv8TooYO9VqAvsbyNnrHvY4rg'
      'spFB3qjDhkO4IewSKtS5/LT+pIyymBh3/BvmjsSo9TrJ8vaMRFcvg4QumKmpOZyA'
      'PnRwPpKdoarjB3UyPzLJaMJUgKxWZYdeQL/5Rqd3BRXnZCYcGZXnLuyGOKf9x5Zo'
      'qeqyByYAt0brSWToTk4yCJoyd/gzg+IF/IeniQKNxpYXs1zlnDNJk6kjaRFAWSgK+'
      'xHxbSuI34pQZPlTRmdxthjBEl/rsKa8puRVf2OT4OO9OJpUbPwaLAISzpM6s6gN+'
      'UtQ0ke03e6Hiu12gApGUGwr9F7mDDrc3weYiODaySgBM35w3jYLtGe3BfxvPegUj'
      'cyBrKJY7jjZGI6w319s2cOcyDDtOvLs+ebqxsunWyjdJOYLZjAHjSTrq36cv5bVX'
      '/u3B5THvdkHfm99RyQvqjQzY1VF2plQvYwJ7KDkZP4v2gPbDaKdmf757Qi/1SCX8'
      'oZASc+gOXQpPf6TpTwu/FFkhOt0nwqc9cpwYkIMlFW6oxO12lPVxB/x9LpXanE1G'
      '+CdhPei3HP2ZYHEsi26ht8kCAwEAAQ==';

  /// RSA private key (PKCS#8, Base64-encoded).
  /// Retained for completeness — not used in Flutter RSA encrypt-only flow.
  static const String rsaPrivateKey =
      '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'
      '91DvTYdxGO3cmb5QyqoAX/RskmE=';

  // ---------------------------------------------------------------------------
  // Subscription / Meter Inquiry SOAP Methods
  // ---------------------------------------------------------------------------

  /// SOAP method for customer billing info — used for meter/subscription lookup.
  ///
  /// Supports multiple DataType values:
  /// - `DataType:31` → search by meter serial number
  /// - `DataType:12` → search by 10-digit subscription number (returns meter #)
  /// - `DataType:13` → extra subscription info (type, last reading, last date)
  static const String inquiryMethodName = 'GetCustomerBillingInfoEnc';

  /// Full SOAPAction header for [inquiryMethodName].
  static const String inquirySoapAction =
      'http://tempuri.org/IBillingWcfsrv/GetCustomerBillingInfoEnc';

  /// SOAP method for checking illegal notifications on a subscription.
  ///
  /// Query: `DataType:18;Where: and LPAD(city_id,3,'0')||LPAD(cust_id,7,'0') = '{sub}'`
  static const String illegalNotificationMethodName = 'GetIllegalNotification';

  /// Full SOAPAction header for [illegalNotificationMethodName].
  static const String illegalNotificationSoapAction =
      'http://tempuri.org/IBillingWcfsrv/GetIllegalNotification';

  /// SOAP method for fetching the list of city names and codes.
  ///
  /// Query: `City:1,DataType:3`
  static const String cityListMethodName = 'GetCityNumber';

  /// Full SOAPAction header for [cityListMethodName].
  static const String cityListSoapAction =
      'http://tempuri.org/IBillingWcfsrv/GetCityNumber';

  // ---------------------------------------------------------------------------
  // Inspection Inquiry / Process Note SOAP Methods
  // ---------------------------------------------------------------------------

  /// SOAP method for fetching workflow transactions by illegal process PID.
  ///
  /// Query: `DataType:2;Where: and t.MAIN_PID = {pid}`
  static const String wfTransactionMethodName =
      'GetWFTRANSACTIONSBiIllegalProcessNote';

  /// Full SOAPAction header for [wfTransactionMethodName].
  static const String wfTransactionSoapAction =
      'http://tempuri.org/IBillingWcfsrv/GetWFTRANSACTIONSBiIllegalProcessNote';

  /// SOAP method for fetching the illegal process note by PID.
  ///
  /// Query: `DataType:1;strWhereOracle:  and n.pid={pid}`
  static const String processNoteMethodName = 'GetBiIllegalProcessNote';

  /// Full SOAPAction header for [processNoteMethodName].
  static const String processNoteSoapAction =
      'http://tempuri.org/IBillingWcfsrv/GetBiIllegalProcessNote';

  /// SOAP method for inserting an illegal process note with photo and stamp.
  ///
  /// Payload includes: EmpNum, WORKSHOP_NUMBER, PID, STAMP_NUM, ILL_NOTES,
  /// ENG_EMP_NAME, ENG_EMP_NUMBER, HelperWrkShopNum, Driver.
  static const String insertProcessNoteMethodName = 'InsertIllegalProcessNote';

  /// Full SOAPAction header for [insertProcessNoteMethodName].
  static const String insertProcessNoteSoapAction =
      'http://tempuri.org/IBillingWcfsrv/InsertIllegalProcessNote';

  /// SOAP method for fetching engineer list (DataType:73, Major:721).
  static const String engineerListMethodName = 'GetGenericsDataTable';

  /// Full SOAPAction header for [engineerListMethodName].
  static const String engineerListSoapAction =
      'http://tempuri.org/IBillingWcfsrv/GetGenericsDataTable';

  /// SOAP method for fetching helper workshop list.
  ///
  /// Query: `wrk_type:8,office_id:0,minor:0,datatype:3`
  static const String helperWorkshopMethodName = 'GetIDECO_WorkshopMF';

  /// Full SOAPAction header for [helperWorkshopMethodName].
  static const String helperWorkshopSoapAction =
      'http://tempuri.org/IBillingWcfsrv/GetIDECO_WorkshopMF';

  // ---------------------------------------------------------------------------
  // App Info
  // ---------------------------------------------------------------------------

  /// Display name shown in the app and on the login screen header.
  static const String companyNameAr = 'شركة كهرباء محافظة إربد';

  /// Name of the unified platform, shown on the splash and login screens.
  static const String platformNameAr = 'منصة التطبيقات الموحدة';

  /// One-line description of the platform, shown under the login title.
  static const String platformTaglineAr =
      'تسجيل دخول واحد لجميع التطبيقات الميدانية';

  /// Sub-title of the inspection application (kept for its own screens).
  static const String appNameAr = 'التفتيش على المشتركين';

  /// Platform version string (matches `version` in `pubspec.yaml`).
  static const String platformVersion = '2.0.0';

  /// Legacy inspection app version, still shown inside that module.
  static const String appVersion = '1.1.2';
}
