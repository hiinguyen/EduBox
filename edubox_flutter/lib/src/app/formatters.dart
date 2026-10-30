import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:intl/intl.dart';

/// Vietnamese date and time formatting (app-direction section 3.3). Every
/// visible date or time goes through here; times are local and 24-hour.
abstract final class EduFormat {
  static const _locale = 'vi';

  /// "Thứ Năm, 29/10/2026".
  static String weekdayDate(DateTime local) =>
      DateFormat('EEEE, dd/MM/yyyy', _locale).format(local);

  /// "14:30".
  static String time(DateTime local) =>
      DateFormat('HH:mm', _locale).format(local);

  /// "09:14" today, otherwise "28/10, 09:14".
  static String lastGood(DateTime cachedAt, DateTime now) {
    final local = cachedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    return day == today
        ? time(local)
        : DateFormat('dd/MM, HH:mm', _locale).format(local);
  }

  /// A whole-number figure in `vi` ("1.250"); a real zero prints "0".
  static String figure(int value) =>
      NumberFormat.decimalPattern(_locale).format(value);

  /// Joins data values (subjects, class names) for one line of text.
  static String joinValues(Iterable<String> values) => values.join(', ');

  /// The given name: the last word of a Vietnamese full name
  /// ("Nguyễn Minh An" -> "An"). Empty when the name is blank.
  static String givenName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.last;
  }

  /// Up to two initials for the account disc ("Nguyễn Minh An" -> "NA").
  static String initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    final first = parts.first.characters.first;
    if (parts.length == 1) return first.toUpperCase();
    return (first + parts.last.characters.first).toUpperCase();
  }
}

/// Vietnamese-aware ordering: compares with diacritics folded first
/// (so "Đọc" sorts with "D", after "Dạy"), then by the raw text.
int compareVietnamese(String a, String b) {
  final folded = _fold(a).compareTo(_fold(b));
  return folded != 0 ? folded : a.compareTo(b);
}

String _fold(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_base[char] ?? char);
  }
  return buffer.toString();
}

/// Lower-case Vietnamese letters mapped to their base letter. "đ" maps to
/// "d~" so it sorts right after every "d".
final Map<String, String> _base = () {
  const groups = {
    'a': 'àáảãạăằắẳẵặâầấẩẫậ',
    'e': 'èéẻẽẹêềếểễệ',
    'i': 'ìíỉĩị',
    'o': 'òóỏõọôồốổỗộơờớởỡợ',
    'u': 'ùúủũụưừứửữự',
    'y': 'ỳýỷỹỵ',
  };
  final map = <String, String>{'đ': 'd~'};
  for (final MapEntry(:key, :value) in groups.entries) {
    for (final char in value.characters) {
      map[char] = key;
    }
  }
  return map;
}();
