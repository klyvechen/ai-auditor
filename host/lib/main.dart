import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'auth/google_auth.dart';

// Public values (identify the app to Google, not secrets). Pass with
// `--dart-define-from-file=dart_defines.json`; empty means Google sign-in is unavailable on that
// platform (Web/Android need only the web one; iOS needs both — see GoogleAuthService).
const _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
const _googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final google = GoogleAuthService(
    webClientId: _googleWebClientId,
    iosClientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
  );
  unawaited(google.init());
  runApp(AiAuditorApp(googleAuth: google));
}
