import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'stop_model.dart';

class RouteResult {
  final List<Stop> stops;
  final List<Stop> infeasible;
  final LatLng? userLocation;
  final List<LatLng> polylinePoints;
  final List<LatLng> stopCoordinates; // coordenadas geocodificadas reais de cada stop

  const RouteResult({
    required this.stops,
    this.infeasible = const [],
    this.userLocation,
    required this.polylinePoints,
    this.stopCoordinates = const [],
  });
}
