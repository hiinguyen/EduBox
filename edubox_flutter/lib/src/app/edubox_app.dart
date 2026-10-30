import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/edu_theme.dart';
import 'app_scope.dart';
import 'connectivity_state.dart';
import 'session_controller.dart';
import 'stage_router.dart';

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
    _session = SessionController(widget.services.backend)
      ..addListener(_onSession);
    _connectivity = ConnectivityState(widget.services.network);
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
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: buildEduTheme(),
        themeMode: ThemeMode.light,
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ListenableBuilder(
          listenable: _session,
          builder: (context, _) => StageRouter(session: _session),
        ),
      ),
    );
  }
}
