import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../screens/app_start/app_start_screens.dart';
import '../theme/edu_theme.dart';
import 'app_scope.dart';
import 'connectivity_state.dart';
import 'session_controller.dart';
import 'stage_router.dart';

/// Boots [AppServices] behind the first frame. The native splash gives way
/// to the opening screen immediately; a startup exception shows the
/// app-start failure panel instead of escaping to an unpainted root.
class EduBoxBootstrap extends StatefulWidget {
  const EduBoxBootstrap({super.key, required this.createServices});

  final Future<AppServices> Function() createServices;

  @override
  State<EduBoxBootstrap> createState() => _EduBoxBootstrapState();
}

class _EduBoxBootstrapState extends State<EduBoxBootstrap> {
  AppServices? _services;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final services = await widget.createServices();
      if (!mounted || generation != _generation) {
        unawaited(services.dispose());
        return;
      }
      setState(() {
        _services = services;
        _failed = false;
      });
    } catch (error, stackTrace) {
      if (!mounted || generation != _generation) return;
      developer.log(
        'EduBox startup failed',
        name: 'EduBox.Bootstrap',
        error: error,
        stackTrace: stackTrace,
      );
      setState(() => _failed = true);
    }
  }

  Future<void> _retry() async {
    setState(() => _failed = false);
    await _load();
  }

  @override
  void dispose() {
    // A load that lands after disposal must not hold resources.
    _generation++;
    final services = _services;
    if (services != null) unawaited(services.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (services != null) return EduBoxApp(services: services);
    return _appFrame(
      home: _failed
          ? AppStartFailedScreen(onRetry: _retry)
          : const AppOpeningScreen(),
    );
  }
}

/// The app root. Re-creating it (a new [EduBoxApp] over a reopened drift
/// store) is the E2E harness's in-process restart.
class EduBoxApp extends StatefulWidget {
  const EduBoxApp({super.key, required this.services});

  final AppServices services;

  @override
  State<EduBoxApp> createState() => _EduBoxAppState();
}

class _EduBoxAppState extends State<EduBoxApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final SessionController _session;
  late final ConnectivityState _connectivity;
  AppStage? _shownStage;

  @override
  void initState() {
    super.initState();
    _connectivity = ConnectivityState(widget.services.network);
    _session = SessionController(
      widget.services.backend,
      connectivity: _connectivity,
    )..addListener(_onSession);
    unawaited(_session.start());
  }

  void _onSession() {
    // A stage change replaces the whole screen: close any dialog or menu
    // route first so nothing from the old stage stays on top.
    if (_session.stage != _shownStage) {
      _shownStage = _session.stage;
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _session.dispose();
    _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      session: _session,
      connectivity: _connectivity,
      child: _appFrame(
        navigatorKey: _navigatorKey,
        home: ListenableBuilder(
          listenable: _session,
          builder: (context, _) => StageRouter(session: _session),
        ),
      ),
    );
  }
}

/// The one MaterialApp frame: Vietnamese, light only, the EduBox theme.
Widget _appFrame({
  required Widget home,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    onGenerateTitle: (context) => AppLocalizations.of(context).appName,
    debugShowCheckedModeBanner: false,
    theme: buildEduTheme(),
    themeMode: ThemeMode.light,
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}
