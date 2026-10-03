import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

// Aquest fitxer gestiona l'autenticació amb Google mitjançant Firebase
// Authentication, incloent inici de sessió, obtenció del token i logout.

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

  // Inicia sessió amb Google i retorna l'usuari autenticat.
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Inici de sessió cancel·lat per l’usuari');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('No s’ha pogut obtenir els tokens de Google');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('No s’ha pogut obtenir l’usuari de Firebase');
      }

      final firebaseIdToken = await user.getIdToken();
      return firebaseIdToken;
    } catch (e) {
      print('Error al iniciar sessió amb Google: $e');
      rethrow;
    }
  }

  // Tanca la sessió de l'usuari actual.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    print('Sessió tancada correctament.');
  }

  // Retorna un client autenticat amb les credencials actuals de Google per fer peticions a APIs segures com Google Calendar.
  Future<AuthClient?> getAuthenticatedClient() async {
    GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
    if (googleUser == null) {
      googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        print(
          'No hay sesión de Google activa o no se pudo refrescar silenciosamente para obtener AuthClient.',
        );
        return null;
      }
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if (googleAuth.accessToken == null) {
      print('AccessToken nulo. El usuario debe volver a autenticarse.');
      return null;
    }

    final AccessToken accessToken = AccessToken(
      'Bearer',
      googleAuth.accessToken!,
      DateTime.now().toUtc().add(Duration(hours: 1)),
    );

    final AccessCredentials credentials = AccessCredentials(
      accessToken,
      null,
      _googleCalendarScopes,
    );

    return authenticatedClient(http.Client(), credentials);
  }
}
