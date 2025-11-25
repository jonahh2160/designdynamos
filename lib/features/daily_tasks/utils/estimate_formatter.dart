int? parseEstimateMinutes(String value) {
  final input = value.trim().toLowerCase();
  if (input.isEmpty) return null;

  //H:MM
  if (input.contains(':')) {
    final parts = input.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        final total = h * 60 + m;
        return total > 0 ? total : null;
      }
    }
  }

  //"1h 30m" or "1h30m"
  final matchHm = RegExp(r'^(\d+)h(?:\s*(\d+)m?)?$').firstMatch(input);
  if (matchHm != null) {
    final h = int.tryParse(matchHm.group(1) ?? '');
    final m = int.tryParse(matchHm.group(2) ?? '0');
    if (h != null && m != null) {
      final total = h * 60 + m;
      return total > 0 ? total : null;
    }
  }

  //"30m"
  final matchM = RegExp(r'^(\d+)m$').firstMatch(input);
  if (matchM != null) {
    final m = int.tryParse(matchM.group(1) ?? '');
    if (m != null && m > 0) return m;
  }

  //plain minutes
  final minutesOnly = int.tryParse(input);
  if (minutesOnly != null && minutesOnly > 0) return minutesOnly;
  return null;
}

String formatEstimateLabel(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes.remainder(60);
  if (hours > 0 && mins > 0) return '~${hours}h ${mins}m';
  if (hours > 0) return '~${hours}h';
  return '~${minutes}m';
}

String formatEstimateInput(int? minutes) {
  if (minutes == null) return '';
  if (minutes >= 60) {
    final h = minutes ~/ 60;
    final m = minutes.remainder(60).toString().padLeft(2, '0');
    return '$h:$m';
  }
  return minutes.toString();
}
