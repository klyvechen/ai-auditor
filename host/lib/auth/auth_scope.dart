import 'package:flutter/widgets.dart';

import 'google_auth.dart';

/// Makes the framework's [GoogleAuthService] reachable from anywhere under the app (the header's
/// account menu now, module registry callbacks once modules accept them). Null when Google
/// isn't configured — everything that reads it must cope with that.
class AuthScope extends InheritedNotifier<GoogleAuthService> {
  const AuthScope({super.key, required GoogleAuthService? service, required super.child}) : super(notifier: service);

  static GoogleAuthService? maybeGoogleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}
