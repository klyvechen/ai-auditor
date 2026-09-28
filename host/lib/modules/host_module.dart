import 'package:flutter/widgets.dart';

/// One entry in the framework's module menu (mirrors a `modules.json` entry).
///
/// The framework only ever touches `id`/`name`/`description`/`icon` for the menu, plus
/// `builder` to embed the module's `Shell`. Per docs/plugin-contract.md #1, it must not need
/// anything else about the module to make it work.
class HostModule {
  const HostModule({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.builder,
    this.requiresGoogle = false,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;

  /// Whether entering this module should be gated on a Google sign-in first (see
  /// docs/plugin-contract.md #6: on demand, per module — not a global login). When true and
  /// Google is configured but nobody is signed in, the host shows a login prompt in place of
  /// [builder] and only renders it once sign-in succeeds. Has no effect when Google sign-in isn't
  /// configured at all, so the module behaves exactly as it does standalone.
  final bool requiresGoogle;
}
