import 'package:intl/intl.dart';

import 'package:faranka/app/core/providers/calendar_mode_provider.dart';
import 'package:faranka/app/core/utils/ethiopian_date.dart';

extension EthiopianFormatting on DateTime {
  String fmt(String pattern, CalendarMode mode) {
    if (mode == CalendarMode.ethiopian) {
      return EthiopianDate.fromGregorian(this).format(pattern);
    }
    return DateFormat(pattern).format(this);
  }
}
