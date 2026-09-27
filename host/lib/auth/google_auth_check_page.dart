import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'google_auth.dart';
import 'google_sign_in_button.dart';

const _gmailModify = 'https://www.googleapis.com/auth/gmail.modify';

/// Debug-only page for checking Google sign-in by hand on Chrome / Android, independent of any
/// module. Shows what the SDK actually returned (never the raw tokens).
class GoogleAuthCheckPage extends StatefulWidget {
  const GoogleAuthCheckPage({super.key, required this.auth});

  final GoogleAuthService? auth;

  @override
  State<GoogleAuthCheckPage> createState() => _GoogleAuthCheckPageState();
}

class _GoogleAuthCheckPageState extends State<GoogleAuthCheckPage> {
  final _log = <String>[];

  String _stamp() {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  Future<void> _run(String label, Future<String> Function() action) async {
    String result;
    try {
      result = await action();
    } catch (e) {
      result = '失敗:$e';
    }
    if (mounted) setState(() => _log.insert(0, '[${_stamp()}] $label → $result'));
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return Scaffold(
      appBar: AppBar(title: const Text('Google 登入測試')),
      body: auth == null || !auth.isConfigured
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Google 登入未設定。啟動時要帶 --dart-define-from-file=dart_defines.json'),
              ),
            )
          : ListenableBuilder(listenable: auth, builder: (context, _) => _body(context, auth)),
    );
  }

  Widget _body(BuildContext context, GoogleAuthService auth) {
    final user = auth.user;
    final claims = auth.idTokenClaims;
    final aud = claims?['aud'];
    final exp = claims?['exp'];
    final remaining = exp is num
        ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000).difference(DateTime.now()).inMinutes
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section('設定', [
          _Row('平台', kIsWeb ? 'Web' : defaultTargetPlatform.name),
          _Row('Web 用戶端 ID', auth.webClientId),
          _Row('登入方式', kIsWeb ? 'Google 官方按鈕(Web 不能用程式觸發)' : '程式呼叫 authenticate()'),
        ]),
        _Section('登入狀態', [
          _Row('帳號', user == null ? '未登入' : '${user.email}${user.displayName == null ? '' : '(${user.displayName})'}'),
          if (claims != null) ...[
            _Row('aud 等於用戶端 ID', aud == auth.webClientId ? '✓ 是' : '✗ 否($aud)'),
            _Row('email_verified', '${claims['email_verified']}'),
            _Row('ID token 剩餘', remaining == null ? '?' : '$remaining 分鐘'),
          ],
        ]),
        _Section('操作', [
          if (user == null)
            FutureBuilder<void>(
              future: auth.init(),
              builder: (context, snap) => snap.connectionState == ConnectionState.done
                  ? Align(alignment: Alignment.centerLeft, child: buildGoogleSignInButton(auth))
                  : const LinearProgressIndicator(),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _run('freshIdToken()', () async {
                  final t = await auth.freshIdToken();
                  return t == null ? 'null(未登入或已過期且無法靜默更新)' : '有效';
                }),
                child: const Text('取得 ID token'),
              ),
              OutlinedButton(
                onPressed: () => _run('requestAccess(gmail.modify)', () async {
                  final r = await auth.requestAccess(const [_gmailModify]);
                  if (r == null) return 'null(取消,或未設定)';
                  final code = r.serverAuthCode;
                  final codeText = code == null ? '無' : '有(長度 ${code.length},開頭 ${code.substring(0, code.length.clamp(0, 6))}…)';
                  return 'idToken:${r.idToken == null ? '無' : '有'};serverAuthCode:$codeText';
                }),
                child: const Text('要求 Gmail 授權'),
              ),
              OutlinedButton(
                onPressed: user == null ? null : () => _run('signOut()', () async {
                  await auth.signOut();
                  return '完成';
                }),
                child: const Text('登出'),
              ),
            ],
          ),
        ]),
        _Section('紀錄', [
          if (_log.isEmpty) const Text('(還沒有操作)'),
          for (final line in _log) SelectableText(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          for (final c in children) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: c),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline))),
        Expanded(child: SelectableText(value)),
      ],
    );
  }
}
