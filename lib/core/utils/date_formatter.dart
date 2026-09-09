import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • HH:mm');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _dayOfWeek = DateFormat('E');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatShort(DateTime date) => _shortDate.format(date);
  static String formatDayOfWeek(DateTime date) => _dayOfWeek.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return _dateFormat.format(date);
  }
}
