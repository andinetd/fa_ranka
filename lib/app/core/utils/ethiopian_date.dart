class EthiopianDate {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final int millisecond;

  const EthiopianDate({
    required this.year,
    required this.month,
    required this.day,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.millisecond = 0,
  });

  static const monthNames = [
    'Meskerem', 'Ṭeqemt', 'Ḫedar', 'Taḫśaś', 'Ṭer', 'Yäkatit',
    'Mäggabit', 'Miyazya', 'Ginbot', 'Säné', 'Ḥamle', 'Naḥase', 'Pagumē',
  ];

  static const dayNames = [
    'Ehud', 'Säño', 'Maksäño', 'Räbu', 'Hamus', 'Arb', 'Qdamé',
  ];

  bool get isLeapYear => year % 4 == 0;
  int get daysInMonth => month == 13 ? (isLeapYear ? 6 : 5) : 30;

  static bool _isGregorianLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  static DateTime _ethiopianNewYear(int gregYear) {
    return DateTime(gregYear, 9, _isGregorianLeapYear(gregYear) ? 12 : 11);
  }

  static EthiopianDate fromGregorian(DateTime greg) {
    final date = DateTime(greg.year, greg.month, greg.day);

    final newYearThis = _ethiopianNewYear(greg.year);

    int ethYear;
    DateTime newYear;

    if (!date.isBefore(newYearThis)) {
      ethYear = greg.year - 7;
      newYear = newYearThis;
    } else {
      ethYear = greg.year - 8;
      newYear = _ethiopianNewYear(greg.year - 1);
    }

    final daysSince = date.difference(newYear).inDays;
    final ethMonth = (daysSince ~/ 30) + 1;
    final ethDay = (daysSince % 30) + 1;

    return EthiopianDate(
      year: ethYear,
      month: ethMonth,
      day: ethDay,
      hour: greg.hour,
      minute: greg.minute,
      second: greg.second,
      millisecond: greg.millisecond,
    );
  }

  DateTime toGregorian() {
    if (month == 13 && day > daysInMonth) {
      throw ArgumentError(
        'Day $day is out of range for Pagumē (max $daysInMonth)',
      );
    }
    final newYear = _ethiopianNewYear(year + 7);
    final daysOffset = (month - 1) * 30 + (day - 1);
    return newYear.add(Duration(days: daysOffset));
  }

  String format(String pattern) {
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm = hour < 12 ? 'AM' : 'PM';
    final buf = StringBuffer();
    int i = 0;

    while (i < pattern.length) {
      final ch = pattern[i];

      if (ch == 'M') {
        int count = 0;
        while (i < pattern.length && pattern[i] == 'M') { count++; i++; }
        if (count >= 3) {
          buf.write(monthNames[month - 1]);
        } else {
          buf.write(count == 2
              ? month.toString().padLeft(2, '0')
              : month.toString());
        }
      } else if (ch == 'E') {
        int count = 0;
        while (i < pattern.length && pattern[i] == 'E') { count++; i++; }
        buf.write(count >= 3 ? _dayName : '');
      } else if (ch == 'y') {
        int count = 0;
        while (i < pattern.length && pattern[i] == 'y') { count++; i++; }
        buf.write(count == 2
            ? (year % 100).toString().padLeft(2, '0')
            : year.toString());
      } else if (ch == 'd') {
        int count = 0;
        while (i < pattern.length && pattern[i] == 'd') { count++; i++; }
        buf.write(count >= 2 ? day.toString().padLeft(2, '0') : day.toString());
      } else if (ch == 'H') {
        int count = 0;
        while (i < pattern.length && pattern[i] == 'H') { count++; i++; }
        buf.write(count >= 2 ? hour.toString().padLeft(2, '0') : hour.toString());
      } else if (ch == 'h') {
        int count = 0;
        while (i < pattern.length && pattern[i] == 'h') { count++; i++; }
        buf.write(count >= 2 ? h12.toString().padLeft(2, '0') : h12.toString());
      } else if (ch == 'm') {
        int count = 0;
        while (i < pattern.length && pattern[i] == 'm') { count++; i++; }
        buf.write(count >= 2 ? minute.toString().padLeft(2, '0') : minute.toString());
      } else if (ch == 's') {
        int count = 0;
        while (i < pattern.length && pattern[i] == 's') { count++; i++; }
        buf.write(count >= 2 ? second.toString().padLeft(2, '0') : second.toString());
      } else if (ch == 'a') {
        i++;
        buf.write(amPm);
      } else {
        buf.write(ch);
        i++;
      }
    }

    return buf.toString();
  }

  String get _dayName {
    final greg = toGregorian();
    final weekday = greg.weekday;
    final ethIndex = weekday == 7 ? 0 : weekday;
    return dayNames[ethIndex];
  }

  @override
  String toString() => '${monthNames[month - 1]} $day, $year';
}
