import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_strings.dart';

/// "Just now", "5 min ago", "3 d ago", ... in the app language.
///
/// From a minute up to a month it counts seconds / minutes / hours / days;
/// beyond that it counts months and years, and [RelativeTimeLabel.showDate] is
/// true so the caller can add the exact date next to it.
class RelativeTime {
  RelativeTime._();

  static RelativeTimeLabel of(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);

    if (diff.inSeconds < 10) {
      return RelativeTimeLabel(AppStrings.timeJustNow.tr, false);
    }
    if (diff.inSeconds < 60) return _label(AppStrings.timeSecAgo, diff.inSeconds);
    if (diff.inMinutes < 60) return _label(AppStrings.timeMinAgo, diff.inMinutes);
    if (diff.inHours < 24) return _label(AppStrings.timeHourAgo, diff.inHours);
    if (diff.inDays < 30) return _label(AppStrings.timeDayAgo, diff.inDays);
    if (diff.inDays < 365) {
      return _label(AppStrings.timeMonthAgo, diff.inDays ~/ 30, showDate: true);
    }
    return _label(AppStrings.timeYearAgo, diff.inDays ~/ 365, showDate: true);
  }

  static RelativeTimeLabel _label(String key, int n, {bool showDate = false}) =>
      RelativeTimeLabel(key.trParams({'n': '$n'}), showDate);
}

class RelativeTimeLabel {
  const RelativeTimeLabel(this.text, this.showDate);

  final String text;

  /// Months or years: also show the exact date.
  final bool showDate;
}
