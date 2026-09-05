// Helpers za kupanga maandishi na tarehe.

/// TSh 1,000,000 — weka koma za maelfu.
String money(num amount) {
  final fixed = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < fixed.length; i++) {
    final remaining = fixed.length - i;
    buffer.write(fixed[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return 'TSh $buffer';
}

/// 5/3/2026 saa 09:41
String formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} saa $hour:$minute';
}

/// 5/3/2026 — au '--' kama hakuna tarehe.
String formatDate(DateTime? date) =>
    date == null ? '--' : '${date.day}/${date.month}/${date.year}';
