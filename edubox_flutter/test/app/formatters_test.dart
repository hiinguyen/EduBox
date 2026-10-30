import 'package:edubox_flutter/src/app/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi'));

  test('weekday date and 24-hour time in Vietnamese', () {
    final date = DateTime(2026, 10, 29, 14, 30);
    expect(EduFormat.weekdayDate(date), 'Thứ Năm, 29/10/2026');
    expect(EduFormat.time(date), '14:30');
  });

  test('last-good time: HH:mm today, dd/MM, HH:mm otherwise', () {
    final now = DateTime(2026, 10, 29, 18);
    expect(EduFormat.lastGood(DateTime(2026, 10, 29, 9, 14), now), '09:14');
    expect(
      EduFormat.lastGood(DateTime(2026, 10, 28, 9, 14), now),
      '28/10, 09:14',
    );
  });

  test('figures use the vi grouping and print a real zero', () {
    expect(EduFormat.figure(0), '0');
    expect(EduFormat.figure(1250), '1.250');
  });

  test('given name and initials', () {
    expect(EduFormat.givenName('Nguyễn Minh An'), 'An');
    expect(EduFormat.givenName('  '), '');
    expect(EduFormat.initials('Nguyễn Minh An'), 'NA');
    expect(EduFormat.initials('Lan'), 'L');
    expect(EduFormat.initials(''), '');
  });

  test('Vietnamese compare folds diacritics and puts đ after d', () {
    final words = ['Đọc', 'Dạy', 'Ánh', 'An', 'Bé', 'dung'];
    words.sort(compareVietnamese);
    expect(words, ['An', 'Ánh', 'Bé', 'Dạy', 'dung', 'Đọc']);
  });

  test('joinValues joins data with a comma', () {
    expect(EduFormat.joinValues(['Toán', 'Tiếng Anh']), 'Toán, Tiếng Anh');
    expect(EduFormat.joinValues(const []), '');
  });
}
