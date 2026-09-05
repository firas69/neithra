class ActivityStreak {
  static int currentStreak(Iterable<DateTime> completedAtDates) {
    final activeDays = completedAtDates
        .map((date) => _localDay(date.toLocal()))
        .toSet();
    if (activeDays.isEmpty) return 0;

    final today = _localDay(DateTime.now());
    var cursor = activeDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;

    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static DateTime _localDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
