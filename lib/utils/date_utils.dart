import 'package:intl/intl.dart';

class AppDateUtils {
  static String toLocalDateKey(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  static DateTime startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  static DateTime endOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('EEE, MMM d').format(dt);
  }

  static List<DateTime> weekDays(DateTime startOfWeek) {
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  static DateTime startOfWeekFor(DateTime dt, {int firstDayOfWeek = 1}) {
    final d = startOfDay(dt);
    final diff = (d.weekday - firstDayOfWeek + 7) % 7;
    return d.subtract(Duration(days: diff));
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}