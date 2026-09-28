import 'package:email_assist/ui/shell.dart' as email_assist;
import 'package:flutter/material.dart';

import '../auth/auth_scope.dart';
import 'host_module.dart';

/// The framework's module list. Manually maintained, mirrors the repo root's `modules.json`
/// (see docs/plugin-contract.md "已拍板的決定": no auto-discovery yet, second module decides
/// whether that's worth building).
///
/// Adding a module should be the *only* framework-side code change: import its `Shell`, add one
/// entry below. No provider setup, no module-specific init — see the "嵌入方式" acceptance bar.
final List<HostModule> hostModules = [
  HostModule(
    id: 'email-assist',
    name: 'Gmail 整理助手',
    description: '定時檢查 Gmail,用 AI 找出多餘的信件,經審核後移到垃圾桶或退訂。',
    icon: Icons.mail_outline,
    requiresGoogle: true,
    // Both are optional (contract #6): when Google sign-in isn't configured the module gets
    // neither callback and keeps using its own fixed API token / desktop-browser Gmail flow,
    // exactly as when it runs standalone. requestGoogleAccess is phase 2 — email-assist decides
    // if/when to call it (and with which scopes) once it has identity; the host never calls it.
    builder: (context) {
      final google = AuthScope.maybeGoogleOf(context);
      final ready = google != null && google.isConfigured;
      return email_assist.Shell(
        googleIdToken: ready ? google.freshIdToken : null,
        requestGoogleAccess: ready ? google.requestAccess : null,
      );
    },
  ),
];
