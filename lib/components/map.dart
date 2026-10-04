import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

/// Legacy map prototype; the home navigation uses TrackingScreen instead.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Location location = Location();
  List<LatLng> route = [];
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _locationSubscription = location.onLocationChanged.listen((loc) {
      if (!mounted) return;
      final position = LatLng(loc.latitude!, loc.longitude!);
      setState(() {
        route.add(position);
      });
      mapController?.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Walk')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: LatLng(0, 0), zoom: 15),
        onMapCreated: (controller) => mapController = controller,
        polylines: {
          Polyline(
            polylineId: PolylineId('passeig'),
            points: route,
            color: Colors.blue,
            width: 5,
          ),
        },
        myLocationEnabled: true,
      ),
    );
  }
}
