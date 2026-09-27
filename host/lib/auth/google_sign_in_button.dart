// Web can't start sign-in from code (google_sign_in_web has no `authenticate()`), so it needs
// Google's own rendered button; every other platform gets a normal button that calls signIn().
export 'google_sign_in_button_stub.dart' if (dart.library.js_interop) 'google_sign_in_button_web.dart';
