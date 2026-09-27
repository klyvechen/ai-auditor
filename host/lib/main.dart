import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'auth/google_auth.dart';

// Public value (identifies the app to Google, not a secret). Pass with
// `--dart-define-from-file=dart_defines.json`; empty means Google sign-in is simply unavailable.
const _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final google = GoogleAuthService(webClientId: _googleWebClientId);
  unawaited(google.init());
  runApp(AiAuditorApp(googleAuth: google));
}
