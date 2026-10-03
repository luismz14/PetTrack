import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:pet_track/models/pets_db.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pet_track/screens/tracking_screen.dart';

// Pantalla de selecció i enregistrament de rutes amb mascotes. Permet
// triar quines mascotes participen, centra el mapa a la ubicació de
// l’usuari, inicia el seguiment (TrackingScreen) i desa a Firestore els
// detalls de la ruta (temps, distància, traçat) per a cada mascota.

class RoutesWithPetsScreen extends StatefulWidget {
  const RoutesWithPetsScreen({super.key});

  @override
  State<RoutesWithPetsScreen> createState() => _RoutesWithPetsScreenState();
}

class _RoutesWithPetsScreenState extends State<RoutesWithPetsScreen> {
  late Future<List<Map<String, dynamic>>> _petsFuture;
  final Set<String> _selectedIds = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _petsFuture = getPets();

    Future.delayed(const Duration(milliseconds: 500), () {
      _centerMapOnUser();
    });
  }

  // Afegeix o elimina la mascota amb ID [id] del conjunt _selectedIds.
  void _togglePet(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // Si totes les mascotes estan seleccionades les desmarca; en cas contrari,
  // selecciona-les totes. Utilitza _selectedIds i la llista [pets].
  void _toggleAll(List<Map<String, dynamic>> pets) {
    setState(() {
      if (_selectedIds.length == pets.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(pets.map((e) => e['id'] as String));
      }
    });
  }

  // Demana permisos de localització, obté la posició actual i anima la
  // càmera del GoogleMap perquè se centri a l’usuari.
  Future<void> _centerMapOnUser() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    } catch (e) {
      debugPrint('Error centrant la ubicació: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _petsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pets = snapshot.data ?? [];
          final allSelected = _selectedIds.length == pets.length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rutes amb mascotes',
                    style: AppTextStyles.titleText(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tria acompanyants:',
                        style: AppTextStyles.midText(
                          context,
                        ).copyWith(fontSize: size.width * 0.045),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _toggleAll(pets),
                      style: ButtonStyle(
                        elevation: WidgetStateProperty.all(0),
                        backgroundColor: WidgetStateProperty.all(
                          allSelected
                              ? AppColors.primary
                              : AppColors.backgroundComponent,
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      child: Text(
                        allSelected ? 'Descarta tots' : 'Selecciona tots',
                        style: AppTextStyles.midText(
                          context,
                        ).copyWith(color: allSelected ? Colors.white : null),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    final id = pet['id'] as String;
                    final selected = _selectedIds.contains(id);
                    final species = pet['species'] ?? "example";
                    final String? imageUrl = pet['imageUrl'];
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      imageCache.evict(
                        NetworkImage(imageUrl),
                        includeLive: true,
                      );
                    }
                    final ImageProvider imageProvider =
                        imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : AssetImage('assets/images/$species.png');
                    return GestureDetector(
                      onTap: () => _togglePet(id),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.backgroundComponent,
                            backgroundImage: imageProvider,
                          ),
                          if (selected)
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(
                                  (0.6 * 255).toInt(),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: pets.length,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(35.6938, 139.7034),
                        zoom: 15,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton(
                        heroTag: null,
                        onPressed: _centerMapOnUser,
                        backgroundColor: AppColors.primary,
                        mini: true,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                      child: SizedBox(
                        height: 68,
                        child: ElevatedButton(
                          onPressed: _selectedIds.isEmpty ? null : () {},
                          style: ButtonStyle(
                            elevation: WidgetStateProperty.all(0),
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color?>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors.grey;
                                  }
                                  return Colors.transparent;
                                }),
                            shadowColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient:
                                  _selectedIds.isEmpty
                                      ? null
                                      : AppColors.gradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap:
                                  _selectedIds.isEmpty
                                      ? null
                                      : () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => TrackingScreen(
                                                  petIds: _selectedIds.toList(),
                                                ),
                                          ),
                                        );
                                        print(
                                          'Result from TrackingScreen: $result',
                                        );
                                        if (result != null && result is Map) {
                                          for (final petId
                                              in result['petIds']) {
                                            final ref =
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(
                                                      FirebaseAuth
                                                          .instance
                                                          .currentUser!
                                                          .uid,
                                                    )
                                                    .collection('pets')
                                                    .doc(petId)
                                                    .collection('routes')
                                                    .doc();
                                            await ref.set({
                                              'startTime': result['startTime'],
                                              'endTime': result['endTime'],
                                              'distance': result['distance'],
                                              'duration': result['duration'],
                                              'path': result['path'],
                                            });
                                          }
                                        }
                                      },
                              child: Center(
                                child: Text(
                                  'Iniciar ruta (${_selectedIds.length})',
                                  style: AppTextStyles.bigText(
                                    context,
                                  ).copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
