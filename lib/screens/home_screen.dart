import 'package:flutter/material.dart';
import 'package:pet_track/components/app_bar.dart';
import 'package:pet_track/components/nav_bar.dart';
import 'package:pet_track/screens/calendar_screen.dart';
import 'package:pet_track/screens/pet_list_screen.dart';
import 'package:http/http.dart' as http;
import 'package:pet_track/screens/profile_screen.dart';
import 'package:pet_track/screens/routes_screen.dart';
import 'dart:convert';
import 'package:pet_track/services/user_service.dart';

// Pantalla principal de l’aplicació: mostra la barra superior personalitzada,
// la barra de navegació inferior i, segons la pestanya seleccionada, carrega
// una de les pantalles bàsiques (Mascotes, Calendari, Rutes o Perfil).
// També centralitza les crides a les Cloud Run Functions i recupera
// la informació de l’usuari autenticat des de Firestore.

const runUrl = 'get-pets-958615888221.europe-southwest1.run.app';

// Fa una crida HTTP (GET o POST) a la Cloud Run Function indicada,
// incloent-hi el token de Firebase si cal, i retorna la resposta.
Future<http.Response?> callCloudFunction({
  required String functionName,
  required String? firebaseIdToken,
  Map<String, dynamic>? data,
  String method = 'GET',
}) async {
  final uri = Uri.https(
    runUrl,
    '/$functionName',
    method == 'GET' ? data?.map((k, v) => MapEntry(k, v.toString())) : null,
  );

  if (method == 'GET') {
    return await http.get(uri);
  } else {
    return await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data ?? {}),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final UserService _userService = UserService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Carrega les dades de l’usuari actual amb UserService i les desa a userData.
  Future<void> _loadUserData() async {
    final data = await _userService.getCurrentUser();
    if (mounted) {
      setState(() {
        userData = data;
      });
    }
  }

  // Determina quina pantalla s’ha de mostrar segons l’índex seleccionat.
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const PetListScreen();
      case 1:
        return const CalendarScreen();
      case 2:
        return const RoutesWithPetsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const PetListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBarWidget(height: screenHeight * 0.1),
        body: _getPage(_index),
        bottomNavigationBar: NavBar(
          currentIndex: _index,
          onTap: (i) async {
            setState(() => _index = i);
          },
        ),
      ),
    );
  }
}
