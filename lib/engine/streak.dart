// Day-streak maths, kept pure so it can be unit-tested without a clock.

/// Formats a [DateTime] as the local calendar day key used for streaks.
String dayKey(DateTime date) {
  final DateTime d = DateTime(date.year, date.month, date.day);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// The current consecutive-day streak ending today (or yesterday, so a streak
/// is not "lost" until a full day is missed).
///
/// Counts back from [today] while each preceding day is present in [days]. If
/// the user has not practised today but did yesterday, the streak still stands.
int currentStreak(Set<String> days, DateTime today) {
  if (days.isEmpty) return 0;
  final DateTime start = DateTime(today.year, today.month, today.day);

  // Anchor: today if present, otherwise yesterday if present, else no streak.
  DateTime cursor;
  if (days.contains(dayKey(start))) {
    cursor = start;
  } else if (days.contains(dayKey(start.subtract(const Duration(days: 1))))) {
    cursor = start.subtract(const Duration(days: 1));
  } else {
    return 0;
  }

  int streak = 0;
  while (days.contains(dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
