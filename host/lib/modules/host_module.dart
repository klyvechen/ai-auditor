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
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
}
