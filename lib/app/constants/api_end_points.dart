// lib/core/network/api_end_points.dart

import 'package:psf_application/app/config/env/env.dart';

class ApiEndPoints {
  ApiEndPoints._();

  static String get baseUrl => Env.config.baseUrl;

  // Api
  static String get getEnumBundle => '$baseUrl/api/Api/GetEnumBundle';

  // Banner
  static String get getBannerListByType => '$baseUrl/api/Banner/GetBannerListByType';

  static String get saveMemberStep1 =>
      '$baseUrl/api/Member/SaveMemberStep1';

  static String get getSingleMemberByRegisteredStatus =>
      '$baseUrl/api/Member/GetSingleMemberByRegistredStatus';

  static String get saveDocument =>
      '$baseUrl/api/Document/SaveDocument';

  // Language & Translation APIs
  static String get englishToHindi => '$baseUrl/api/translation/en-hi';
  static String get englishToGujarati => '$baseUrl/api/translation/en-gu';
  static String get hindiToEnglish => '$baseUrl/api/Language/HindiToEnglish';
  static String get hindiToGujarati => '$baseUrl/api/Language/HindiToGujarati';
  static String get gujaratiToEnglish => '$baseUrl/api/Language/GujaratiToEnglish';
  static String get gujaratiToHindi => '$baseUrl/api/Language/GujaratiToHindi';

  /// Dynamic translation endpoint fallback
  static String translateEndpoint(String fromCode, String toCode) =>
      '$baseUrl/api/translation?from=$fromCode&to=$toCode';
}