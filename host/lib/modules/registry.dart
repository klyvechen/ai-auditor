import 'package:email_assist/ui/shell.dart' as email_assist;
import 'package:flutter/material.dart';

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
    builder: (context) => const email_assist.Shell(),
  ),
];
