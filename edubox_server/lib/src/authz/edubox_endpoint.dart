import 'package:serverpod/serverpod.dart';

/// Base class of every EduBox endpoint (not the auth module endpoints).
///
/// `requireLogin` makes Serverpod reject unauthenticated calls before any
/// EduBox code runs; each method additionally calls `requireCaller` or
/// `requireRole`, which loads the role from the `users` table.
abstract class EduboxEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;
}
