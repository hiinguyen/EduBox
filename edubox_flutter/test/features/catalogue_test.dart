import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_flutter/src/features/library/catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryItem item(String title, String subject, ContentType type, int day) =>
    LibraryItem(
      id: day,
      type: type,
      title: title,
      subject: subject,
      gradeLevel: 7,
      createdAt: DateTime.utc(2026, 10, day),
    );

void main() {
  final library = StudentLibrary(
    classes: [
      StudentClass(
        id: 1,
        name: '7A',
        gradeLevel: 7,
        subjects: ['Toán', 'Ngữ văn'],
      ),
    ],
    items: [
      item('Phân số', 'Toán', ContentType.ebook, 20),
      item('Đọc hiểu', 'Ngữ văn', ContentType.video, 21),
      item('Luyện tập', 'Toán', ContentType.exercise, 22),
      item('Nội quy', '', ContentType.ebook, 24),
      item('Từ vựng', 'Tiếng Anh', ContentType.ebook, 25),
      item('Ánh sáng', 'Vật lý', ContentType.video, 23),
      item('Phân số', 'Toán', ContentType.video, 19),
    ],
  );

  test('groups follow the class subject order, then A-Z, then other', () {
    final groups = buildCatalogue(library);
    expect(groups.map((g) => g.subject), [
      'Toán',
      'Ngữ văn',
      'Tiếng Anh',
      'Vật lý',
      null,
    ]);
  });

  test('inside a group: title A-Z, ties by type ebook, video, exercise', () {
    final toan = buildCatalogue(library).first;
    expect(toan.items.map((i) => '${i.title}/${i.type.name}'), [
      'Luyện tập/exercise',
      'Phân số/ebook',
      'Phân số/video',
    ]);
  });

  test('newest four by createdAt, newest first', () {
    expect(newestItems(library).map((i) => i.title), [
      'Từ vựng',
      'Nội quy',
      'Ánh sáng',
      'Luyện tập',
    ]);
  });
}
