import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'auth/auth_scope.dart';
import 'auth/google_auth.dart';
import 'auth/google_auth_check_page.dart';
import 'auth/google_sign_in_button.dart';
import 'modules/host_module.dart';
import 'modules/registry.dart';

/// Below this width the framework switches from the desktop-style side rail to the mobile shell
/// (module list -> tap -> fullscreen module). Per docs/plugin-contract.md's open question 2, the
/// exact mobile shell design isn't settled yet; this is a reasonable default (one of the options
/// the doc lists), not a final decision.
const double kWideLayoutBreakpoint = 700;

class AiAuditorApp extends StatelessWidget {
  const AiAuditorApp({super.key, this.googleAuth});

  /// Null when Google sign-in isn't configured (and in most widget tests).
  final GoogleAuthService? googleAuth;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      service: googleAuth,
      child: MaterialApp(
        title: 'AuditAmigo AI',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HostHome(),
      ),
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
      actions: [
        if (kDebugMode)
          IconButton(
            tooltip: 'Google 登入測試(僅 debug 版)',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GoogleAuthCheckPage(auth: AuthScope.maybeGoogleOf(context))),
            ),
          ),
        const _AccountMenu(),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Signed-in Google account (avatar + sign-out). Renders nothing until someone has signed in:
/// login is triggered on demand by a module, never forced from the header.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeGoogleOf(context);
    final user = auth?.user;
    if (auth == null || user == null) return const SizedBox.shrink();

    final initial = (user.displayName ?? user.email).characters.first.toUpperCase();
    return PopupMenuButton<String>(
      tooltip: user.email,
      onSelected: (v) {
        if (v == 'signout') auth.signOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(enabled: false, child: Text(user.email)),
        const PopupMenuItem<String>(value: 'signout', child: Text('登出')),
      ],
      child: CircleAvatar(
        radius: 16,
        backgroundImage: user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
        onBackgroundImageError: user.photoUrl == null ? null : (_, _) {},
        child: Text(initial),
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
        Expanded(child: _ModuleEntryPoint(module: selected)),
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
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ModuleEntryPoint(module: m))),
        );
      },
    );
  }
}

/// The login gate (docs/plugin-contract.md #6: on demand, per module — not a global login).
///
/// Renders [HostModule.builder] directly unless the module opted into [HostModule.requiresGoogle]
/// *and* Google sign-in is actually configured; in that combination, nobody signed in means a
/// login prompt takes the module's place until sign-in succeeds, at which point this rebuilds
/// (via [ListenableBuilder] on the auth service) and swaps in the real module. Gmail authorization
/// itself is unchanged for now — still the module's own backend-driven flow (contract phase 2 is
/// what replaces that).
class _ModuleEntryPoint extends StatelessWidget {
  const _ModuleEntryPoint({required this.module});

  final HostModule module;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeGoogleOf(context);
    if (!module.requiresGoogle || auth == null || !auth.isConfigured) {
      return Builder(builder: module.builder);
    }
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => auth.user != null ? Builder(builder: module.builder) : _GoogleLoginGate(module: module, auth: auth),
    );
  }
}

class _GoogleLoginGate extends StatelessWidget {
  const _GoogleLoginGate({required this.module, required this.auth});

  final HostModule module;
  final GoogleAuthService auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(module.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(module.icon, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  '使用「${module.name}」需要先登入 Google',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                FutureBuilder<void>(
                  future: auth.init(),
                  builder: (context, snap) => snap.connectionState == ConnectionState.done
                      ? buildGoogleSignInButton(auth)
                      : const CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
