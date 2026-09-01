String dayKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime parseDayKey(String key) => DateTime.parse(key);

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int daysBetween(DateTime from, DateTime to) {
  final a = dateOnly(from);
  final b = dateOnly(to);
  return b.difference(a).inDays;
}
