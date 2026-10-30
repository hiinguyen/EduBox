import 'package:flutter/widgets.dart';

import '../contract/backend.dart';
import '../contract/network_controller.dart';
import 'connectivity_state.dart';
import 'session_controller.dart';

/// Everything a screen needs from outside the widget tree. Tests build one
/// over `FakeBackend` and `ManualNetworkController`; `main.dart` builds one
/// over `CachedBackend` and `ProbedNetworkController`.
class AppServices {
  AppServices({
    required this.backend,
    required this.network,
    DateTime Function()? clock,
    this.disposeNetwork,
  }) : clock = clock ?? DateTime.now;

  final EduBoxBackend backend;
  final NetworkController network;

  /// Local wall clock for the date line and "checked at" times.
  final DateTime Function() clock;

  /// Releases the network seam when this bundle owns it (production). Null
  /// when the caller keeps ownership (widget tests, the E2E harness).
  final void Function()? disposeNetwork;

  /// Releases everything this bundle owns.
  Future<void> dispose() async {
    try {
      await backend.dispose();
    } finally {
      disposeNetwork?.call();
    }
  }
}

/// Provides [AppServices], the [SessionController] and the
/// [ConnectivityState] to the tree. Read with `AppScope.of(context)`.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required this.session,
    required this.connectivity,
    required super.child,
  });

  final AppServices services;
  final SessionController session;
  final ConnectivityState connectivity;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      services != oldWidget.services ||
      session != oldWidget.session ||
      connectivity != oldWidget.connectivity;
}
