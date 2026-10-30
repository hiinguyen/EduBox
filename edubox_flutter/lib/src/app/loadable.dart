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

  T? get value => _value;

  /// When [value] was last refreshed from the server.
  DateTime? get cachedAt => _cachedAt;

  /// True when [value] came from the local store while offline.
  bool get isStale => _isStale;

  /// The last load's error, cleared by the next success.
  BackendError? get error => _error;

  bool get isLoading => _isLoading;

  bool get hasValue => _value != null;

  /// Loads once; concurrent calls share nothing and simply both run.
  Future<void> load() async {
    _isLoading = true;
    _notify();
    final result = await _fetch();
    if (_disposed) return;
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
