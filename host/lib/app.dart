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
      title: 'AuditAmigo AI',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HostHome(),
    );
  }
}

/// Cross-module banner: logo + product name, top-left. Shown on the module picker / wide layout
/// only — a module taking over fullscreen (the mobile shell's pushed route) intentionally does
/// not get this, per docs/plugin-contract.md's "模組內容佔滿全螢幕".
///
class _HostHeader extends StatelessWidget implements PreferredSizeWidget {
  const _HostHeader();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/logo_icon.png', height: 32),
          const SizedBox(width: 10),
          Text('AuditAmigo AI', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
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
      return const Scaffold(appBar: _HostHeader(), body: Center(child: Text('尚未掛載任何模組')));
    }

    final wide = MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;
    return Scaffold(
      appBar: const _HostHeader(),
      body: wide
          ? _WideBody(modules: modules, selectedIndex: _selectedIndex, onSelect: (i) => setState(() => _selectedIndex = i))
          : _ModuleListBody(modules: modules),
    );
  }
}

/// Desktop/tablet: a side rail lists modules, the content area holds whichever `Shell` is
/// selected. The framework does nothing beyond swapping the widget in `Expanded` — this is the
/// literal `Widget content = const Shell();` example from the contract's "嵌入方式" section.
class _WideBody extends StatelessWidget {
  const _WideBody({required this.modules, required this.selectedIndex, required this.onSelect});

  final List<HostModule> modules;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final index = selectedIndex.clamp(0, modules.length - 1);
    final selected = modules[index];
    return Row(
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
    );
  }
}

/// Phone: pick a module from a plain list, then its `Shell` takes over the whole screen (no host
/// header on that pushed page — see `_HostHeader`'s doc comment).
///
/// No back button is added by hand — the module's own `Scaffold`/`AppBar` (e.g. email-assist's
/// `ShellContent`) already renders one automatically once it's pushed onto a route that can pop,
/// which is standard Flutter `AppBar` behavior. That keeps this page at zero module-specific
/// code, matching the contract's "no extra integration cost" bar.
class _ModuleListBody extends StatelessWidget {
  const _ModuleListBody({required this.modules});

  final List<HostModule> modules;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
    );
  }
}
