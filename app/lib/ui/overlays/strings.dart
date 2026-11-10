abstract final class GhOverlayStrings {
  static const datePreviousMonth = 'Previous month';
  static const dateNextMonth = 'Next month';
  static const dateAddDue = 'Add due date';

  static String dateChangeDue(String date) => 'Change due date: $date';

  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static String formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
