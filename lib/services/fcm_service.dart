import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<void> initForCurrentUser() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    await _persistToken(token);
    _messaging.onTokenRefresh.listen(_persistToken);
  }

  Future<void> _persistToken(String? token) async {
    if (token == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));

  }
}
