import 'package:get/get.dart';

import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/shared/enums/app_language.dart';

/// Translates a GetEnumBundle option's English-only `name` (Gender,
/// Marital Status, Nominee Relation — the backend has no h/g variant for
/// these, unlike every other field on the registration wizard) into the
/// app's currently-selected language for DISPLAY only. The value actually
/// saved/sent to the API is always the option's `id`, never this label,
/// so this is purely cosmetic and safe to apply anywhere an enum option's
/// name is shown to the member.
///
/// Originally lived only on RegistrationPreviewScreen (as
/// `_translatedOptionName` / `_optionTranslations`) since that was the
/// first screen to need it; pulled out here so MemberRegistrationScreen's
/// own Gender radio group / Marital Status / Relationship dropdowns can
/// show the same translated labels instead of always rendering the raw
/// English name regardless of the selected app language.
class EnumOptionTranslator {
  EnumOptionTranslator._();

  static String translate(String englishName) {
    final language = Get.find<LanguageController>().currentAppLanguage;
    if (language == AppLanguage.english) return englishName;

    final entry = _translations[englishName.trim().toLowerCase()];
    if (entry == null) return englishName;

    final translated =
        language == AppLanguage.hindi ? entry['hi'] : entry['gu'];
    return (translated != null && translated.isNotEmpty)
        ? translated
        : englishName;
  }

  static const Map<String, Map<String, String>> _translations = {
    'male': {'hi': 'पुरुष', 'gu': 'પુરુષ'},
    'female': {'hi': 'महिला', 'gu': 'સ્ત્રી'},
    'other': {'hi': 'अन्य', 'gu': 'અન્ય'},
    'single': {'hi': 'अविवाहित', 'gu': 'અપરિણીત'},
    'married': {'hi': 'विवाहित', 'gu': 'પરિણીત'},
    'divorced': {'hi': 'तलाकशुदा', 'gu': 'છૂટાછેડા લીધેલ'},
    'widowed': {'hi': 'विधवा/विधुर', 'gu': 'વિધવા/વિધુર'},
    'father': {'hi': 'पिता', 'gu': 'પિતા'},
    'mother': {'hi': 'माता', 'gu': 'માતા'},
    'husband': {'hi': 'पति', 'gu': 'પતિ'},
    'wife': {'hi': 'पत्नी', 'gu': 'પત્ની'},
    'son': {'hi': 'बेटा', 'gu': 'દીકરો'},
    'daughter': {'hi': 'बेटी', 'gu': 'દીકરી'},
    'brother': {'hi': 'भाई', 'gu': 'ભાઈ'},
    'sister': {'hi': 'बहन', 'gu': 'બહેન'},
    'grandson': {'hi': 'पौत्र', 'gu': 'પૌત્ર'},
    'granddaughter': {'hi': 'पौत्री', 'gu': 'પૌત્રી'},
    'son in law': {'hi': 'दामाद', 'gu': 'જમાઈ'},
    'daughter in law': {'hi': 'बहू', 'gu': 'વહુ'},
    'father in law': {'hi': 'ससुर', 'gu': 'સસરા'},
    'mother in law': {'hi': 'सास', 'gu': 'સાસુ'},
    'other relative': {'hi': 'अन्य रिश्तेदार', 'gu': 'અન્ય સંબંધી'},
  };
}
