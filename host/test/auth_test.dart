import 'dart:convert';

import 'package:ai_auditor/app.dart';
import 'package:ai_auditor/auth/google_auth.dart';
import 'package:ai_auditor/auth/jwt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _jwt(Map<String, Object?> payload) {
  String enc(Object o) => base64Url.encode(utf8.encode(json.encode(o))).replaceAll('=', '');
  return '${enc({'alg': 'none'})}.${enc(payload)}.sig';
}

class _FakeGoogleAuth extends GoogleAuthService {
  _FakeGoogleAuth(this._user) : super(webClientId: '');

  GoogleUser? _user;
  int signOuts = 0;

  @override
  GoogleUser? get user => _user;

  @override
  Future<void> signOut() async {
    signOuts++;
    _user = null;
    notifyListeners();
  }
}

void main() {
  group('jwt', () {
    final now = DateTime.utc(2026, 9, 27, 12);
    int secs(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

    test('reads exp', () {
      final exp = jwtExpiry(_jwt({'exp': secs(now)}));
      expect(exp, now);
    });

    test('valid only while more than the skew remains', () {
      expect(jwtStillValid(_jwt({'exp': secs(now.add(const Duration(minutes: 10)))}), now: now), isTrue);
      expect(jwtStillValid(_jwt({'exp': secs(now.add(const Duration(seconds: 30)))}), now: now), isFalse);
      expect(jwtStillValid(_jwt({'exp': secs(now.subtract(const Duration(minutes: 1)))}), now: now), isFalse);
    });

    test('garbage is never valid', () {
      expect(jwtExpiry('not-a-jwt'), isNull);
      expect(jwtStillValid('a.b.c'), isFalse);
      expect(jwtStillValid(_jwt({'no': 'exp'})), isFalse);
    });
  });

  group('header account menu', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pump(WidgetTester tester, GoogleAuthService? auth) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(AiAuditorApp(googleAuth: auth));
      await tester.pumpAndSettle();
    }

    testWidgets('nothing is shown when signed out or not configured', (tester) async {
      await pump(tester, null);
      expect(find.byType(CircleAvatar), findsNothing);

      await pump(tester, _FakeGoogleAuth(null));
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('signed in: avatar with the account, and sign-out clears it', (tester) async {
      final auth = _FakeGoogleAuth(const GoogleUser(email: 'klyve@example.com', displayName: 'Klyve'));
      await pump(tester, auth);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('K'), findsOneWidget);

      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();
      expect(find.text('klyve@example.com'), findsOneWidget);

      await tester.tap(find.text('登出'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 1);
      expect(find.byType(CircleAvatar), findsNothing);
    });
  });
}
