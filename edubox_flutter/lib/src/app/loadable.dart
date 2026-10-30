import 'package:flutter/foundation.dart';

import '../contract/backend_result.dart';

/// One block's data: the last good value, its freshness, and the last
/// error. A failed reload keeps the old value, so "error after data was
/// shown" keeps the rows on screen.
class Loadable<T> extends ChangeNotifier {
  Loadable(this._fetch);

  final Future<BackendResult<T>> Function() _fetch;

  T? _value;
  DateTime? _cachedAt;
  bool _isStale = false;
  BackendError? _error;
  bool _isLoading = false;
  bool _disposed = false;
  int _loadSeq = 0;

  T? get value => _value;

  /// When [value] was last refreshed from the server.
  DateTime? get cachedAt => _cachedAt;

  /// True when [value] came from the local store while offline.
  bool get isStale => _isStale;

  /// The last load's error, cleared by the next success.
  BackendError? get error => _error;

  bool get isLoading => _isLoading;

  bool get hasValue => _value != null;

  /// Loads once. Only the newest call applies: an older call that resolves
  /// after a newer one is discarded and cannot clear the newer busy state.
  Future<void> load() async {
    final seq = ++_loadSeq;
    _isLoading = true;
    _notify();
    final result = await _fetch();
    if (_disposed || seq != _loadSeq) return;
    switch (result) {
      case BackendOk(:final value, :final cachedAt, :final isStale):
        _value = value;
        _cachedAt = cachedAt;
        _isStale = isStale;
        _error = null;
      case BackendFailure(:final error):
        _error = error;
    }
    _isLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
