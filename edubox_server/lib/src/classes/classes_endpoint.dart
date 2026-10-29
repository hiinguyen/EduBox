import 'package:serverpod/serverpod.dart';

import '../authz/edubox_endpoint.dart';
import '../authz/guard.dart';
import '../generated/protocol.dart';
import 'class_queries.dart';

/// Classes, from the teacher's side.
class ClassesEndpoint extends EduboxEndpoint {
  /// The calling teacher's own classes, ordered by grade, then name, with
  /// teacher-ordered subjects and the member count.
  ///
  /// Allowed: teacher. Denied: student, parent, not set up, unauthenticated.
  Future<List<ClassSummary>> mine(Session session) async {
    final caller = await requireRole(session, UserRole.teacher);
    final classes = await SchoolClass.db.find(
      session,
      where: (t) => t.teacherId.equals(caller.userId),
      orderByList: (t) => [t.gradeLevel.asc(), t.name.asc()],
    );
    final ids = classes.map((c) => c.id!).toSet();
    final subjects = await subjectsByClass(session, ids);
    final members = await ClassMember.db.find(
      session,
      where: (t) => t.classId.inSet(ids),
    );
    return [
      for (final c in classes)
        ClassSummary(
          id: c.id!,
          name: c.name,
          gradeLevel: c.gradeLevel,
          subjects: subjects[c.id!] ?? const [],
          studentCount: members.where((m) => m.classId == c.id).length,
        ),
    ];
  }
}
