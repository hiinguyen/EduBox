/// The lifecycle of one stored write.
enum OutboxState {
  /// Waiting for a sync attempt.
  pending,

  /// The server rejected it permanently (for example a denied caller) or
  /// retrying it cannot help; the UI may offer a manual retry.
  failed,
}

/// An unsynced write. Phase 1 defines the shape only; progress and submission
/// writes arrive in phase 3, and `tests.start` / `tutor.ask` are never queued.
class OutboxWrite {
  const OutboxWrite({
    this.id,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.state = OutboxState.pending,
    this.attempts = 0,
    this.lastError,
  });

  final int? id;

  /// Stable operation name, for example `progress.markComplete`.
  final String operation;

  /// JSON-encodable body, including the client-generated idempotency id.
  final Map<String, Object?> payload;

  final DateTime createdAt;
  final OutboxState state;
  final int attempts;
  final String? lastError;

  OutboxWrite copyWith({
    int? id,
    String? operation,
    Map<String, Object?>? payload,
    DateTime? createdAt,
    OutboxState? state,
    int? attempts,
    String? lastError,
  }) => OutboxWrite(
    id: id ?? this.id,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    lastError: lastError ?? this.lastError,
  );
}

/// The outbox contract used by the sync worker and the pending-sync UI.
abstract interface class Outbox {
  /// Appends one write and returns its row id.
  Future<int> enqueue(OutboxWrite write);

  /// Pending writes in insertion order.
  Future<List<OutboxWrite>> pending();

  /// All writes, including permanently failed ones, in insertion order.
  Future<List<OutboxWrite>> all();

  /// Marks a delivered write as done.
  Future<void> markSent(int id);

  /// Moves a write to [OutboxState.failed] and records why.
  Future<void> markFailed(int id, String reason);

  /// Moves a failed write back to pending for one manual attempt.
  Future<void> retry(int id);
}
