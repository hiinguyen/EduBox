import 'package:serverpod/serverpod.dart';

import '../authz/edubox_endpoint.dart';
import '../authz/guard.dart';
import '../classes/class_queries.dart';
import '../generated/protocol.dart';

/// Content, from the student's side.
class ContentEndpoint extends EduboxEndpoint {
  /// The calling student's classes and the `approved` content scoped to at
  /// least one of them, newest first. Draft content and other classes'
  /// content are never returned (the in-app enforcement point for "no
  /// unapproved content").
  ///
  /// Allowed: student. Denied: teacher, parent, not set up, unauthenticated.
  Future<StudentLibrary> library(Session session) async {
    final caller = await requireRole(session, UserRole.student);
    final memberships = await ClassMember.db.find(
      session,
      where: (t) => t.studentId.equals(caller.userId),
    );
    final classIds = memberships.map((m) => m.classId).toSet();
    if (classIds.isEmpty) {
      return StudentLibrary(classes: const [], items: const []);
    }
    final classes = await SchoolClass.db.find(
      session,
      where: (t) => t.id.inSet(classIds),
      orderByList: (t) => [t.gradeLevel.asc(), t.name.asc()],
    );
    final subjects = await subjectsByClass(session, classIds);
    final scope = await ContentClass.db.find(
      session,
      where: (t) => t.classId.inSet(classIds),
    );
    final contentIds = scope.map((s) => s.contentId).toSet();
    final items = contentIds.isEmpty
        ? const <ContentRecord>[]
        : await ContentRecord.db.find(
            session,
            where: (t) =>
                t.id.inSet(contentIds) &
                t.status.equals(ContentStatus.approved),
            orderByList: (t) => [
              t.createdAt.desc(),
              t.id.desc(),
            ],
          );
    return StudentLibrary(
      classes: [
        for (final c in classes)
          StudentClass(
            id: c.id!,
            name: c.name,
            gradeLevel: c.gradeLevel,
            subjects: subjects[c.id!] ?? const [],
          ),
      ],
      items: [
        for (final item in items)
          LibraryItem(
            id: item.id!,
            type: item.type,
            title: item.title,
            subject: item.subject,
            gradeLevel: item.gradeLevel,
            createdAt: item.createdAt,
          ),
      ],
    );
  }
}
