part of bullet.client.formatters;

typedef String DateBuilder(DateTime);

/**
 * Modified version of Angular's standard date formatter
 */
@Formatter(name: 'niceDate')
class NiceDate {

  static final _mappings = const <int, String> {
     -1: 'Yesterday',
      0: 'Today',
      1: 'Tomorrow'
  };

  int _daysSince(DateTime date) {
    DateTime removeTime(DateTime date) => new DateTime.utc(date.year, date.month, date.day);
    return removeTime(date).difference(removeTime(new DateTime.now())).inDays;
  }

  dynamic call(Object date) {
    if (date == '' || date == null) return date;
    if (date is String) date = DateTime.parse(date);
    if (date is num) date = new DateTime.fromMillisecondsSinceEpoch(date);
    if (date is! DateTime) return date;

    int diff = _daysSince(date);
    if (_mappings.containsKey(diff)) return '${_mappings[diff]}, ${new DateFormat('h:mm a').format(date)}';
    return new DateFormat('MMM d, y, h:mm a').format(date);
  }
}
