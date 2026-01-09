import 'package:intl/intl.dart';

class DateHelper {
  static String format(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}
