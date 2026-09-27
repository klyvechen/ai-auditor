import 'package:flutter/material.dart';

import 'google_auth.dart';

Widget buildGoogleSignInButton(GoogleAuthService auth) {
  return FilledButton.icon(
    onPressed: auth.signIn,
    icon: const Icon(Icons.login),
    label: const Text('用 Google 登入'),
  );
}
