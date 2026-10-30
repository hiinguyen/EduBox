import 'package:edubox_client/edubox_client.dart' show UserRole;
import 'package:flutter/material.dart';

import '../screens/account_not_set_up/account_not_set_up_screen.dart';
import '../screens/app_start/app_start_screens.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../screens/student_library/student_library_screen.dart';
import '../shell/student_shell.dart';
import 'session_controller.dart';

/// Maps the session stage (and, at home, the role) to the one screen that
/// fills the window. Each stage change swaps the whole subtree.
/// Stages whose screen is not built yet show [AppOpeningScreen] until
/// their task replaces the placeholder.
class StageRouter extends StatelessWidget {
  const StageRouter({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return switch (session.stage) {
      AppStage.opening => const AppOpeningScreen(),
      AppStage.startFailed => AppStartFailedScreen(onRetry: session.start),
      AppStage.signedOut => const SignInScreen(),
      AppStage.notSetUp => const AccountNotSetUpScreen(),
      AppStage.home => switch (session.session!.role!) {
        UserRole.student => StudentShell(
          libraryBuilder: (_) => const StudentLibraryScreen(),
        ),
        UserRole.teacher => const AppOpeningScreen(),
        UserRole.parent => const AppOpeningScreen(),
      },
    };
  }
}
