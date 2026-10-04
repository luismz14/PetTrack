import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _googleCalendarScopes = [
    'openid',
    'email',
    gcal.CalendarApi.calendarScope,
  ];

  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(scopes: _googleCalendarScopes);
  }

  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Sign-in cancelled by the user');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('Could not obtain Google authentication tokens');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Could not obtain the Firebase user');
      }

      final firebaseIdToken = await user.getIdToken();
      return firebaseIdToken;
    } catch (_) {
      if (kDebugMode) debugPrint('Google sign-in failed.');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    if (kDebugMode) debugPrint('Signed out.');
  }

  /// Wraps the current Google access token for Calendar requests.
  /// Expiry is assumed to be one hour; this wrapper has no refresh token.
  Future<AuthClient?> getAuthenticatedClient() async {
    GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
    if (googleUser == null) {
      googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        if (kDebugMode) debugPrint('No active Google session is available.');
        return null;
      }
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if (googleAuth.accessToken == null) {
      if (kDebugMode) debugPrint('Google reauthentication required.');
      return null;
    }

    final AccessToken accessToken = AccessToken(
      'Bearer',
      googleAuth.accessToken!,
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );

    final AccessCredentials credentials = AccessCredentials(
      accessToken,
      null,
      _googleCalendarScopes,
    );

    return authenticatedClient(http.Client(), credentials);
  }
}
