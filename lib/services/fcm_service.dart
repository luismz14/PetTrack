import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Aquest fitxer gestiona les notificacions push mitjançant Firebase Cloud Messaging (FCM).

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Inicialitza el servei de FCM per a l'usuari actual.
  Future<void> initForCurrentUser() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    await _persistToken(token);
    _messaging.onTokenRefresh.listen(_persistToken);
  }

  // Guarda un token persistent a la base de dadades de l'usuari actual.
  Future<void> _persistToken(String? token) async {
    if (token == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
    print('FCM token actualitzat: $token');
  }
}
