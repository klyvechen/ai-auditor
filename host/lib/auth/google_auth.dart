import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'jwt.dart';

/// What the header needs to show; kept separate from the SDK's account type so it can be faked.
class GoogleUser {
  const GoogleUser({required this.email, this.displayName, this.photoUrl});

  final String email;
  final String? displayName;
  final String? photoUrl;
}

typedef GoogleAccess = ({String? idToken, String? serverAuthCode});

/// Google sign-in for the framework. Login is on demand (nothing here runs a sign-in at startup)
/// and per provider; modules receive [freshIdToken] / [requestAccess] as optional callbacks — see
/// docs/plugin-contract.md #6. This holds identity only: Gmail credentials stay in the module's
/// backend.
///
/// The web client ID is app-global in `google_sign_in` (Android: `serverClientId`, Web: `clientId`).
class GoogleAuthService extends ChangeNotifier {
  GoogleAuthService({required this.webClientId, GoogleSignIn? signIn}) : _signIn = signIn ?? GoogleSignIn.instance;

  final String webClientId;
  final GoogleSignIn _signIn;

  GoogleSignInAccount? _account;
  Future<void>? _init;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;

  bool get isConfigured => webClientId.isNotEmpty;

  GoogleUser? get user {
    final a = _account;
    return a == null ? null : GoogleUser(email: a.email, displayName: a.displayName, photoUrl: a.photoUrl);
  }

  Future<void> init() => _init ??= _doInit();

  Future<void> _doInit() async {
    if (!isConfigured) return;
    try {
      await _signIn.initialize(
        clientId: kIsWeb ? webClientId : null,
        serverClientId: kIsWeb ? null : webClientId,
      );
      _events = _signIn.authenticationEvents.listen(_onEvent, onError: (Object _) {});
      // Restore a previous session where the platform can do it without UI. On Web this is One
      // Tap, which may never answer, so nothing waits on it.
      _signIn.attemptLightweightAuthentication()?.then<void>((_) {}, onError: (Object _) {});
    } catch (e) {
      debugPrint('Google sign-in init failed: $e');
    }
  }

  void _onEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        _setAccount(user);
      case GoogleSignInAuthenticationEventSignOut():
        _setAccount(null);
    }
  }

  void _setAccount(GoogleSignInAccount? account) {
    _account = account;
    notifyListeners();
  }

  /// Claims of the current ID token (unverified, for display/diagnostics only).
  Map<String, dynamic>? get idTokenClaims {
    final token = _account?.authentication.idToken;
    return token == null ? null : jwtPayload(token);
  }

  /// Whether this platform can start sign-in from code. False on Web, where the sign-in button has
  /// to be Google's own rendered button. Only meaningful after [init].
  bool get canSignInProgrammatically => isConfigured && _signIn.supportsAuthenticate();

  /// Programmatic sign-in (Android). No-op where unsupported; returns quietly if the user cancels.
  Future<void> signIn() async {
    await init();
    if (!canSignInProgrammatically) return;
    try {
      await _signIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) return;
      rethrow;
    }
  }

  String? _validIdToken() {
    final token = _account?.authentication.idToken;
    return token != null && jwtStillValid(token) ? token : null;
  }

  /// A currently-valid ID token, or null if signed out. ID tokens last about an hour and can't be
  /// refreshed in place, so an expired one triggers a silent re-authentication where the platform
  /// supports it (Android). Never shows UI.
  Future<String?> freshIdToken() async {
    await init();
    final current = _validIdToken();
    if (current != null) return current;
    final attempt = _signIn.attemptLightweightAuthentication();
    if (attempt == null) return null;
    try {
      final account = await attempt.timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (account != null) _setAccount(account);
    } catch (_) {
      return null;
    }
    return _validIdToken();
  }

  /// Called by a module when it actually needs Google access: signs in if needed, then requests
  /// [scopes] (incremental authorization). Returns null if the user cancels or Google isn't
  /// configured. On Web there's no programmatic sign-in, so [GoogleAccess.idToken] can be null
  /// while [GoogleAccess.serverAuthCode] is present — the module's backend can take identity from
  /// the code exchange instead. Must be called from a user gesture (Web opens a popup).
  Future<GoogleAccess?> requestAccess(List<String> scopes) async {
    await init();
    if (!isConfigured) return null;
    try {
      if (_account == null && _signIn.supportsAuthenticate()) {
        await _signIn.authenticate(scopeHint: scopes);
      }
      final client = _account?.authorizationClient ?? _signIn.authorizationClient;
      final server = await client.authorizeServer(scopes);
      return (idToken: _validIdToken(), serverAuthCode: server?.serverAuthCode);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Clears the framework's sign-in state only. It does not revoke anything a module's backend
  /// already holds — disconnecting that is the module's own action (contract #6).
  Future<void> signOut() async {
    await init();
    try {
      await _signIn.signOut();
    } finally {
      _setAccount(null);
    }
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }
}
