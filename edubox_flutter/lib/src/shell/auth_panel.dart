import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The pre-auth layout (sign-in, account-not-set-up, app start): a 400dp
/// `sheet` panel on `paper`, centred when it fits, top-aligned and
/// scrollable when it does not (keyboard, 200% text, split screen).
class AuthPanelScaffold extends StatelessWidget {
  const AuthPanelScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 360;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(EduSpace.s16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: EduSize.authPanelWidth,
                      ),
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(
                            narrow ? EduSpace.s16 : EduSpace.s24,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
