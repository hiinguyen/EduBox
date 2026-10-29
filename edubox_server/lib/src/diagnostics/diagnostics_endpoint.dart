import 'package:serverpod/serverpod.dart';

import '../authz/edubox_endpoint.dart';
import '../authz/guard.dart';
import '../generated/protocol.dart';

/// Diagnostics that prove transport paths end to end.
class DiagnosticsEndpoint extends EduboxEndpoint {
  /// Number of messages [pingStream] sends before it closes.
  static const pingCount = 3;

  /// Pause between two messages, so a client observes them arriving one by
  /// one over the streaming connection.
  static const pingInterval = Duration(milliseconds: 250);

  /// Streams [pingCount] messages carrying the caller's role, then closes.
  ///
  /// Allowed: student, teacher, parent. Denied: not set up, unauthenticated.
  Stream<PingMessage> pingStream(Session session) async* {
    final caller = await requireCaller(session);
    for (var sequence = 1; sequence <= pingCount; sequence++) {
      if (sequence > 1) await Future<void>.delayed(pingInterval);
      yield PingMessage(
        sequence: sequence,
        total: pingCount,
        role: caller.role,
        sentAt: DateTime.now().toUtc(),
      );
    }
  }
}
