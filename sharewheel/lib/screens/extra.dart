import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Map Example'),
        ),
        body: const MapWidget(),
      ),
    );
  }
}

class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = [
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(38.913184, -77.031952),
        builder: (ctx) => Container(
          child: const Icon(Icons.location_pin),
        ),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(37.775408, -122.413682),
        builder: (ctx) => Container(
          child: const Icon(Icons.location_pin),
        ),
      ),
    ];

    return FlutterMap(
      options: MapOptions(
        center: LatLng(37.8, -96.0),
        zoom: 4.0,
      ),
    );
  }
}
