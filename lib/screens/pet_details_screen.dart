import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pet_track/components/app_bar.dart';
import 'package:pet_track/components/feed_button.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:pet_track/screens/add_edit_pet_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pet_track/components/google_auth.dart';
import 'package:pet_track/services/calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';

// Pantalla de detalls d’una mascota. Mostra la foto, dades bàsiques, característiques
// generades amb Gemini, recompte d’àpats del dia, últim passeig i el proper
// esdeveniment del calendari PetTrack. Inclou botó per alimentar, accés a l’edició
// i sincronitza la informació amb Firestore i Google Calendar.

class PetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> petData;

  const PetDetailsScreen({super.key, required this.petData});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  late Map<String, dynamic> pet;
  late int _dailyFeedCount;
  late int _dailyFeedGoal;
  late DateTime _lastFed;
  late String _caracteristiques;

  DateTime? _lastWalkStart;
  DateTime? _lastWalkEnd;

  late final AuthService _authService;
  CalendarService? _calendarService;
  String? _petTrackCalendarId;
  gcal.Event? _nextEvent;
  bool _loadingEvent = true;

  @override
  void initState() {
    super.initState();
    pet = Map<String, dynamic>.from(widget.petData);
    _dailyFeedCount = pet['dailyFeedCount'];
    _dailyFeedGoal = pet['dailyFeedGoal'] ?? 3;
    _lastFed =
        pet['lastFed'] is Timestamp
            ? (pet['lastFed'] as Timestamp).toDate()
            : DateTime(2025, 1, 1);
    _caracteristiques = 'Carregant...';

    _authService = AuthService();
    _loadNextEvent();
    _loadLastWalk();

    _obtenirCaracteristiques().then((value) {
      if (!mounted) return;
      setState(() => _caracteristiques = value);
    });
  }

  // Recupera l’últim passeig de Firestore i assigna les
  // marques d’inici i fi a _lastWalkStart i _lastWalkEnd.
  Future<void> _loadLastWalk() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('pets')
            .doc(pet['id'])
            .collection('routes')
            .orderBy('startTime', descending: true)
            .limit(1)
            .get();
    if (snap.docs.isEmpty) return;
    final data = snap.docs.first.data();
    setState(() {
      _lastWalkStart =
          data['startTime'] is Timestamp
              ? (data['startTime'] as Timestamp).toDate()
              : null;
      _lastWalkEnd =
          data['endTime'] is Timestamp
              ? (data['endTime'] as Timestamp).toDate()
              : null;
    });
  }

  // Assegura l’existència del calendari “PetTrack”, obté esdeveniments futurs,
  // filtra els relacionats amb la mascota i desa el més proper a _nextEvent.
  Future<void> _loadNextEvent() async {
    final AuthClient? client = await _authService.getAuthenticatedClient();
    if (client == null) {
      setState(() => _loadingEvent = false);
      return;
    }
    _calendarService = CalendarService(client);
    _petTrackCalendarId = await _calendarService!.createPetTrackCalendar();
    if (_petTrackCalendarId == null) {
      setState(() => _loadingEvent = false);
      return;
    }
    final now = DateTime.now().toUtc();
    final end = now.add(const Duration(days: 365));
    final events = await _calendarService!.getEvents(
      _petTrackCalendarId!,
      now,
      end,
    );

    final List<gcal.Event> matched = [];
    for (final e in events) {
      final raw = e.extendedProperties?.private?['petIds'];
      if (raw == null) continue;
      try {
        final ids = List<String>.from(json.decode(raw));
        if (ids.contains(pet['id'])) matched.add(e);
      } catch (_) {}
    }
    matched.sort((a, b) {
      final aStart = a.start?.dateTime ?? a.start?.date;
      final bStart = b.start?.dateTime ?? b.start?.date;
      return aStart!.compareTo(bStart!);
    });
    setState(() {
      _nextEvent = matched.isNotEmpty ? matched.first : null;
      _loadingEvent = false;
    });
  }

  // Converteix la línia de característiques separades per comes en una llista
  // de punts amb salts de línia per a una millor llegibilitat.
  String _formatCaracteristiques(String text) {
    if (!text.contains(',')) return text;
    return text.split(',').map((c) => '• ${c.trim()}').join('\n');
  }

  // Actualitza el recompte i la data de l’últim àpat tant en l’estat local
  // com al document de la mascota a Firestore.
  void _updateFeed(bool add) {
    setState(() {
      _dailyFeedCount =
          add
              ? (_dailyFeedCount + 1).clamp(0, _dailyFeedGoal)
              : (_dailyFeedCount - 1).clamp(0, _dailyFeedGoal);
      if (add) _lastFed = DateTime.now();
    });
    final user = FirebaseAuth.instance.currentUser;
    final updateData = <String, dynamic>{
      'dailyFeedCount': _dailyFeedCount,
      if (add) 'lastFed': Timestamp.fromDate(_lastFed),
    };
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('pets')
        .doc(pet['id'])
        .update(updateData);
  }

  // Envia una petició a Gemini amb espècie, raça, edat i sexe, i retorna
  // 3-4 característiques clau de l’animal en una sola línia
  Future<String> _obtenirCaracteristiques() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) return 'Característiques desconegudes';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );
    final species = pet['species'] ?? 'Desconegut';
    final breed = pet['breed'] ?? 'Desconeguda';
    final sex = pet['sex'] ?? 'Desconegut';

    String edat;
    if (pet['birthDate'] is Timestamp) {
      final bd = (pet['birthDate'] as Timestamp).toDate();
      final months = DateTime.now().difference(bd).inDays ~/ 30;
      edat = '$months mesos';
    } else {
      edat = 'Desconeguda';
    }

    final prompt = '''
Ets un expert veterinari. Basant-te en la següent informació, dóna'm exclusivament 3 o 4 característiques clau de l'animal (mida, nivell d'energia, personalitat, necessitats, etc.). Escriu-les separades per comes, en una sola línia, sense cap altre text ni puntuació extra, i fes que cada característica comenci en majúscula.
Espècie: $species
Raça: $breed
Edat: $edat
Sexe: $sex
Si no ho saps, respon exactament així: Característiques desconegudes''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (res.statusCode == 200) {
        final jsonResp = jsonDecode(res.body);
        final text =
            jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.trim().isNotEmpty) return text.trim();
      }
    } catch (_) {}
    return 'Característiques desconegudes';
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    final name = pet['name'] ?? 'Mascota';
    final breed = pet['breed'] ?? 'Raça desconeguda';
    final species = pet['species'] ?? 'Espècie desconeguda';
    final sex =
        pet['sex'] == 'M'
            ? 'Mascle'
            : pet['sex'] == 'F'
            ? 'Femella'
            : 'Desconegut';

    final bd =
        pet['birthDate'] is Timestamp
            ? (pet['birthDate'] as Timestamp).toDate()
            : null;
    final ageText =
        bd != null
            ? () {
              final now = DateTime.now();
              final duration = now.difference(bd);
              final days = duration.inDays;
              final months = (days / 30).floor();
              return days < 30
                  ? '$days dies'
                  : months < 12
                  ? '$months mesos'
                  : '${(months / 12).floor()} anys';
            }()
            : '';

    final lastWalkText =
        (_lastWalkStart != null && _lastWalkEnd != null)
            ? '${DateFormat.Hm().format(_lastWalkStart!)} - ${DateFormat.Hm().format(_lastWalkEnd!)}'
            : '–';
    final lastWalkDateText =
        _lastWalkStart != null
            ? DateFormat('dd/MM').format(_lastWalkStart!)
            : '';

    final imageUrl = pet['imageUrl'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageCache.evict(NetworkImage(imageUrl), includeLive: true);
    }
    final ImageProvider imageProvider =
        imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : AssetImage('assets/images/$species.png');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(
        height: screenH * .10,
        iconColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedPet = await Navigator.push<Map<String, dynamic>?>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditPetScreen(petData: pet),
                ),
              );
              if (!mounted || updatedPet == null) return;
              if (updatedPet['deleted'] == true) {
                Navigator.pop(context, true);
                return;
              }
              setState(() => pet = updatedPet);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenW * .40,
                  height: screenW * .40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.bigText(context)),
                      const SizedBox(height: 5),
                      Text(breed, style: AppTextStyles.midText(context)),
                      if (ageText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(ageText, style: AppTextStyles.tinyText(context)),
                      ],
                      Text(sex, style: AppTextStyles.tinyText(context)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child:
                  _loadingEvent
                      ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      )
                      : (_nextEvent == null
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_none,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'No hi ha esdeveniments propers',
                                style: AppTextStyles.midText(context),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _nextEvent!.summary ?? 'Esdeveniment',
                                style: AppTextStyles.midText(context),
                              ),
                              const SizedBox(width: 8),
                              if ((_nextEvent!.start?.dateTime ??
                                      _nextEvent!.start?.date) !=
                                  null)
                                Text(
                                  (() {
                                    final start =
                                        (_nextEvent!.start?.dateTime ??
                                                _nextEvent!.start?.date)!
                                            .toLocal();
                                    return _nextEvent!.start?.dateTime != null
                                        ? DateFormat(
                                          'dd/MM HH:mm',
                                        ).format(start)
                                        : DateFormat('dd/MM').format(start);
                                  })(),
                                  style: AppTextStyles.tinyText(context),
                                ),
                            ],
                          )),
            ),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FeedButton(
                    size: screenW * .35,
                    dailyFeedCount: _dailyFeedCount,
                    dailyFeedGoal: _dailyFeedGoal,
                    lastFed: _lastFed,
                    onFeed: _updateFeed,
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Últim passeig:',
                        style: AppTextStyles.midText(context),
                      ),
                      const SizedBox(height: 4),
                      Text(lastWalkText, style: AppTextStyles.bigText(context)),
                      if (lastWalkDateText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          lastWalkDateText,
                          style: AppTextStyles.tinyText(context),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Característiques:",
                    style: AppTextStyles.bigText(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatCaracteristiques(_caracteristiques),
                    textAlign: TextAlign.left,
                    style: AppTextStyles.midText(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
