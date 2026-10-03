import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';

// Pantalla de seguiment en temps real d’una ruta: inicia la subscripció a la
// localització, dibuixa la polilínia sobre Google Maps, actualitza en directe
// les mètriques (distància, durada, ritme) i, en acabar, retorna
// al caller les dades de la ruta perquè es desin a Firestore.

class TrackingScreen extends StatefulWidget {
  final List<String> petIds;
  const TrackingScreen({super.key, required this.petIds});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  final List<LatLng> _route = [];
  StreamSubscription<Position>? _positionStream;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  // Inicia el seguiment: comprova serveis i permisos de localització,
  // desa l’hora d’inici, crea l’Stream de posicions i va afegint punts
  // a _route mentre mou la càmera perquè segueixi l’usuari.
  void _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _startTime = DateTime.now();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((position) {
      final point = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _route.add(point);
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(point));
      }
    });
  }

  // Gestiona el botó «Finalitza ruta»: atura l’Stream, calcula la
  // distància total, mostra un diàleg de confirmació amb mètriques
  // (temps i metres) i, si l’usuari accepta, retorna les dades de la
  // ruta (temps, distància, traçat i mascotes) al widget anterior.
  Future<void> _onSavePressed() async {
    _positionStream?.cancel();
    final endTime = DateTime.now();
    final distance = await _calculateDistance();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Finalitzar i desar la ruta'),
            content: Text(
              'Temps: ${endTime.difference(_startTime).inMinutes} min\n'
              'Distància: ${distance.toStringAsFixed(1)} m\n\n'
              'Vols desar la ruta?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel·la'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Desa'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      Navigator.of(context).pop({
        'startTime': _startTime,
        'endTime': endTime,
        'distance': distance,
        'duration': endTime.difference(_startTime).inSeconds,
        'path':
            _route.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'petIds': widget.petIds,
      });
    }
  }

  // Cancel·la el seguiment immediatament tancant l’Stream de posicions.
  void _cancelTracking() {
    _positionStream?.cancel();
  }

  // Calcula la distància total recorreguda sumant la distància entre
  // cada parell consecutiu de punts a _route amb Geolocator.distanceBetween().
  Future<double> _calculateDistance() async {
    double total = 0.0;
    for (int i = 0; i < _route.length - 1; i++) {
      total += Geolocator.distanceBetween(
        _route[i].latitude,
        _route[i].longitude,
        _route[i + 1].latitude,
        _route[i + 1].longitude,
      );
    }
    return total;
  }

  // Mostra un diàleg per confirmar si l’usuari vol abandonar la ruta
  // sense desar; retorna true si confirma la cancel·lació.
  Future<bool> _confirmCancel() async {
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel·lar ruta'),
            content: const Text(
              'Estàs segur que vols cancel·lar la ruta? Es perdran les dades no desades.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Torna a la ruta'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí'),
              ),
            ],
          ),
    );
    return confirmed ?? false;
  }

  // Allibera recursos tancant l’Stream quan el widget es destrueix.
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final confirm = await _confirmCancel();
          if (confirm) {
            _cancelTracking();
            if (mounted) Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: const CameraPosition(
                target: LatLng(41.3851, 2.1734),
                zoom: 16,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _route,
                  color: AppColors.primary,
                  width: 5,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirm = await _confirmCancel();
                        if (confirm) {
                          _cancelTracking();
                          if (mounted) Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel·la ruta',
                        style: AppTextStyles.bigText(context).copyWith(
                          color: Colors.white,
                          fontSize: size.width * 0.04,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Finalitza ruta',
                        style: AppTextStyles.bigText(context).copyWith(
                          color: Colors.white,
                          fontSize: size.width * 0.04,
                        ),
                      ),
                    ),
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
