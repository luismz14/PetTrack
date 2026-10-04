import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';

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

    if (!mounted) return;
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

  Future<void> _onSavePressed() async {
    _positionStream?.cancel();
    final endTime = DateTime.now();
    final distance = await _calculateDistance();
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Finish and save walk'),
            content: Text(
              'Time: ${endTime.difference(_startTime).inMinutes} min\n'
              'Distance: ${distance.toStringAsFixed(1)} m\n\n'
              'Save this walk?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
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

  void _cancelTracking() {
    _positionStream?.cancel();
  }

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

  Future<bool> _confirmCancel() async {
    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel walk'),
            content: const Text(
              'Cancel this walk? Unsaved route data will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Return to walk'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
    return confirmed ?? false;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
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
                        'Cancel walk',
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
                        'Finish walk',
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
