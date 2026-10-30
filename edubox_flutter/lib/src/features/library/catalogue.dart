import 'package:edubox_client/edubox_client.dart'
    show ContentType, LibraryItem, StudentLibrary;

import '../../app/formatters.dart';

/// One subject group of the library catalogue. [subject] is null for the
/// last group of items with an empty subject ("Môn khác").
class SubjectGroup {
  const SubjectGroup({required this.subject, required this.items});

  final String? subject;
  final List<LibraryItem> items;
}

const _typeOrder = [ContentType.ebook, ContentType.video, ContentType.exercise];

/// Groups the library by subject (student-library brief section 3):
/// subjects in the order of the classes' `subjects[]` (first class first),
/// then any other subject A-Z (Vietnamese-aware), then "Môn khác" last.
/// Inside a group: title A-Z, ties by type (Sách, Video, Bài tập).
List<SubjectGroup> buildCatalogue(StudentLibrary library) {
  final classOrder = <String>[];
  for (final studentClass in library.classes) {
    for (final subject in studentClass.subjects) {
      if (!classOrder.contains(subject)) classOrder.add(subject);
    }
  }
  final bySubject = <String, List<LibraryItem>>{};
  final other = <LibraryItem>[];
  for (final item in library.items) {
    final subject = item.subject.trim();
    if (subject.isEmpty) {
      other.add(item);
    } else {
      bySubject.putIfAbsent(subject, () => []).add(item);
    }
  }
  final extra =
      bySubject.keys.where((subject) => !classOrder.contains(subject)).toList()
        ..sort(compareVietnamese);
  final ordered = [...classOrder.where(bySubject.containsKey), ...extra];
  return [
    for (final subject in ordered)
      SubjectGroup(subject: subject, items: _sorted(bySubject[subject]!)),
    if (other.isNotEmpty) SubjectGroup(subject: null, items: _sorted(other)),
  ];
}

List<LibraryItem> _sorted(List<LibraryItem> items) => [...items]
  ..sort((a, b) {
    final byTitle = compareVietnamese(a.title, b.title);
    if (byTitle != 0) return byTitle;
    return _typeOrder.indexOf(a.type).compareTo(_typeOrder.indexOf(b.type));
  });

/// The newest [count] items by `createdAt`, newest first (student-home).
List<LibraryItem> newestItems(StudentLibrary library, {int count = 4}) => ([
  ...library.items,
]..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(count).toList();
