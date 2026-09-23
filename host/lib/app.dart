import 'package:flutter/material.dart';

import 'modules/host_module.dart';
import 'modules/registry.dart';

/// Below this width the framework switches from the desktop-style side rail to the mobile shell
/// (module list -> tap -> fullscreen module). Per docs/plugin-contract.md's open question 2, the
/// exact mobile shell design isn't settled yet; this is a reasonable default (one of the options
/// the doc lists), not a final decision.
const double kWideLayoutBreakpoint = 700;

class AiAuditorApp extends StatelessWidget {
  const AiAuditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI-Auditor',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HostHome(),
    );
  }
}

/// Cross-module navigation (this file) is the framework's job; each module's own internal
/// navigation stays inside its `Shell` — the framework never reaches into it. See
/// docs/plugin-contract.md #1 and #2.
class HostHome extends StatefulWidget {
  const HostHome({super.key});

  @override
  State<HostHome> createState() => _HostHomeState();
}

class _HostHomeState extends State<HostHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final modules = hostModules;
    if (modules.isEmpty) {
      return const Scaffold(body: Center(child: Text('尚未掛載任何模組')));
    }

    final wide = MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;
    return wide ? _WideShell(modules: modules, selectedIndex: _selectedIndex, onSelect: (i) => setState(() => _selectedIndex = i)) : _ModuleListPage(modules: modules);
  }
}

/// Desktop/tablet: a side rail lists modules, the content area holds whichever `Shell` is
/// selected. The framework does nothing beyond swapping the widget in `Expanded` — this is the
/// literal `Widget content = const Shell();` example from the contract's "嵌入方式" section.
class _WideShell extends StatelessWidget {
  const _WideShell({required this.modules, required this.selectedIndex, required this.onSelect});

  final List<HostModule> modules;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final index = selectedIndex.clamp(0, modules.length - 1);
    final selected = modules[index];
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onSelect,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final m in modules) NavigationRailDestination(icon: Icon(m.icon), label: Text(m.name)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: Builder(builder: selected.builder)),
        ],
      ),
    );
  }
}

/// Phone: pick a module from a plain list, then its `Shell` takes over the whole screen.
///
/// No back button is added by hand — the module's own `Scaffold`/`AppBar` (e.g. email-assist's
/// `ShellContent`) already renders one automatically once it's pushed onto a route that can pop,
/// which is standard Flutter `AppBar` behavior. That keeps this page at zero module-specific
/// code, matching the contract's "no extra integration cost" bar.
class _ModuleListPage extends StatelessWidget {
  const _ModuleListPage({required this.modules});

  final List<HostModule> modules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI-Auditor')),
      body: ListView.separated(
        itemCount: modules.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final m = modules[i];
          return ListTile(
            leading: Icon(m.icon),
            title: Text(m.name),
            subtitle: Text(m.description),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: m.builder)),
          );
        },
      ),
    );
  }
}
