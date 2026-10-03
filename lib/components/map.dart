import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

// Aquest fitxer implementa la pantalla de mapa que registra en temps real la ruta de passeig de la mascota,
// dibuixant els punts recollits i la posició actual sobre Google Maps. Gestiona la subscripció al GPS,
// la càmera del mapa i la visualització del traçat.

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Location location = Location();
  List<LatLng> route = [];

  @override
  void initState() {
    super.initState();
    location.onLocationChanged.listen((loc) {
      final position = LatLng(loc.latitude!, loc.longitude!);
      setState(() {
        route.add(position);
      });
      mapController?.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Passeig')),
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
