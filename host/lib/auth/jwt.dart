import 'dart:convert';

/// Expiry (`exp`) of a JWT, or null if it can't be read. The signature is NOT verified here — this
/// only decides whether to reuse a token locally; the module's backend does the real verification.
DateTime? jwtExpiry(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final exp = payload is Map ? payload['exp'] : null;
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  } catch (_) {
    return null;
  }
}

/// True if [jwt] is still valid for at least [skew] more.
bool jwtStillValid(String jwt, {DateTime? now, Duration skew = const Duration(seconds: 60)}) {
  final exp = jwtExpiry(jwt);
  if (exp == null) return false;
  return exp.isAfter((now ?? DateTime.now().toUtc()).add(skew));
}
