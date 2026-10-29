import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

void main() => runApp(const EduBoxApp());

/// The app entry point. Feature screens are owned by the frontend track; this
/// scaffold only proves the Vietnamese l10n wiring and the single-locale
/// contract.
class EduBoxApp extends StatelessWidget {
  const EduBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(useMaterial3: true),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Text(AppLocalizations.of(context).appOpening),
          ),
        ),
      ),
    );
  }
}
