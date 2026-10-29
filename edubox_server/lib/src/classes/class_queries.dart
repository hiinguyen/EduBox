import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Teacher-ordered subjects for each class in [classIds].
Future<Map<int, List<String>>> subjectsByClass(
  Session session,
  Set<int> classIds,
) async {
  if (classIds.isEmpty) return const {};
  final rows = await ClassSubject.db.find(
    session,
    where: (t) => t.classId.inSet(classIds),
    orderByList: (t) => [t.classId.asc(), t.position.asc()],
  );
  final result = <int, List<String>>{};
  for (final row in rows) {
    (result[row.classId] ??= []).add(row.subject);
  }
  return result;
}
