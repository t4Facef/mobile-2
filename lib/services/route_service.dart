import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/secrets.dart';
import '../models/route_result.dart';
import '../models/stop_model.dart';

class RouteService {
  static const _directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const _placesUrl     = 'https://maps.googleapis.com/maps/api/place/textsearch/json';

  static const _francaLat = -20.5386;
  static const _francaLng = -47.4008;

  bool _isNearFranca(double lat, double lng) =>
      (lat - _francaLat).abs() < 0.5 && (lng - _francaLng).abs() < 0.5;

  /// Usa Places Text Search — mesmo motor do Google Maps — para encontrar
  /// o endereço com precisão real, com bias de localização para Franca, SP.
  /// Retorna "lat,lng" ou null se não encontrar dentro de Franca.
  Future<String?> _findPlaceCoords(String rawAddress) async {
    // Remove vírgulas — o Places Text Search funciona melhor com espaços,
    // como o usuário digitaria no Google Maps: "Rua Major Claudiano 1200 Franca SP"
    final cleaned = rawAddress
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();

    final query = cleaned.toLowerCase().contains('franca')
        ? cleaned
        : '$cleaned Franca SP Brasil';

    final url = Uri.parse(
      '$_placesUrl'
      '?query=${Uri.encodeComponent(query)}'
      '&location=$_francaLat,$_francaLng'
      '&radius=25000'
      '&language=pt-BR'
      '&key=$googleMapsApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK' || (data['results'] as List).isEmpty) return null;

      final loc = data['results'][0]['geometry']['location'];
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();

      if (_isNearFranca(lat, lng)) return '$lat,$lng';
    } catch (_) {}

    return null;
  }

  Future<RouteResult> optimizeRoute(List<Stop> stops, {LatLng? userOrigin}) async {
    final infeasible = stops.where((s) => !s.feasible).toList();

    if (stops.isEmpty) return const RouteResult(stops: [], polylinePoints: []);
    if (stops.length == 1) {
      return RouteResult(stops: stops, infeasible: infeasible,
          userLocation: userOrigin, polylinePoints: const []);
    }

    // Atrasados entram na rota com prioridade 0 — entregar correndo
    final allStops = stops.map((s) => !s.feasible
        ? Stop(address: s.address, complement: s.complement,
               note: s.note, time: s.time, priority: 0, feasible: false)
        : s).toList();

    final sorted = [...allStops]
      ..sort((a, b) => (a.priority ?? 2).compareTo(b.priority ?? 2));

    // Geocodifica em paralelo
    final rawCoords = await Future.wait(
      sorted.map((s) => _findPlaceCoords(s.address)),
    );

    // Mapa address → LatLng para reconstruir coords após reordenação
    final coordMap = <String, LatLng>{};
    for (int i = 0; i < sorted.length; i++) {
      final cs = rawCoords[i];
      if (cs != null) {
        final parts = cs.split(',');
        coordMap[sorted[i].address] = LatLng(
          double.parse(parts[0]), double.parse(parts[1]));
      }
    }

    String coordOrText(int i) => rawCoords[i] ??
        Uri.encodeComponent('${sorted[i].address} Franca SP Brasil');

    final originStr = userOrigin != null
        ? '${userOrigin.latitude},${userOrigin.longitude}'
        : coordOrText(0);

    // Rota ABERTA: destino = stop mais longe do entregador (não volta para casa).
    // Isso evita que o Google otimize para minimizar o retorno, o que gera
    // ordens contra-intuitivas (passa perto de casa antes de ir longe).
    final int destIdx;
    if (userOrigin != null) {
      int farthest = 0;
      double maxDist = -1;
      for (int i = 0; i < sorted.length; i++) {
        final cs = rawCoords[i];
        if (cs == null) continue;
        final parts = cs.split(',');
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        final d = (lat - userOrigin.latitude) * (lat - userOrigin.latitude) +
                  (lng - userOrigin.longitude) * (lng - userOrigin.longitude);
        if (d > maxDist) { maxDist = d; farthest = i; }
      }
      destIdx = farthest;
    } else {
      destIdx = sorted.length - 1;
    }

    final destinationStr = coordOrText(destIdx);
    final fixedLastStop  = sorted[destIdx];

    // Waypoints = todos exceto destino fixo (e exceto origin quando não há GPS)
    final waypointEntries = sorted.indexed
        .where((e) => userOrigin != null ? e.$1 != destIdx : (e.$1 != 0 && e.$1 != destIdx))
        .toList();
    final waypointStops   = waypointEntries.map((e) => e.$2).toList();
    final waypointIndices = waypointEntries.map((e) => e.$1).toList();

    var urlStr = '$_directionsUrl'
        '?origin=$originStr'
        '&destination=$destinationStr'
        '&language=pt-BR'
        '&region=br'
        '&key=$googleMapsApiKey';

    if (waypointStops.isNotEmpty) {
      final wps = waypointIndices.map(coordOrText).join('|');
      urlStr += '&waypoints=optimize:true|$wps';
    }

    final response = await http.get(Uri.parse(urlStr));
    if (response.statusCode != 200) {
      throw Exception('Erro na API de rotas (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') {
      throw Exception('Rota indisponível: ${data['status']}');
    }

    final route     = data['routes'][0] as Map<String, dynamic>;
    final order     = (route['waypoint_order'] as List).cast<int>();
    final reordered = order.map((i) => waypointStops[i]).toList();

    // Rota aberta: userOrigin → waypoints otimizados → destino mais longe
    List<Stop> optimizedStops = userOrigin != null
        ? [...reordered, fixedLastStop]
        : [sorted.first, ...reordered, fixedLastStop];

    optimizedStops = _enforceUrgentFirst(optimizedStops);

    // Coordenadas reais de cada stop na ordem otimizada (para markers no mapa)
    final stopCoordinates = optimizedStops
        .map((s) => coordMap[s.address])
        .whereType<LatLng>()
        .toList();

    final legs = route['legs'] as List;

    // Tempo estimado de chegada em cada parada (legs[i] = trecho até o stop i)
    final now = DateTime.now();
    int cumulativeSecs = 0;
    optimizedStops = List.generate(optimizedStops.length, (i) {
      if (i < legs.length) {
        cumulativeSecs += (legs[i]['duration']['value'] as num).toInt();
      }
      return optimizedStops[i].withArrival(
        now.add(Duration(seconds: cumulativeSecs)),
      );
    });

    // Polylines detalhadas por step — rota aberta, todos os legs incluídos
    final polylinePoints = <LatLng>[];
    for (final leg in legs) {
      for (final step in (leg['steps'] as List)) {
        polylinePoints.addAll(
          PolylinePoints()
              .decodePolyline(step['polyline']['points'] as String)
              .map((p) => LatLng(p.latitude, p.longitude)),
        );
      }
    }

    return RouteResult(
      stops: optimizedStops,
      infeasible: infeasible,
      userLocation: userOrigin,
      polylinePoints: polylinePoints,
      stopCoordinates: stopCoordinates,
    );
  }

  List<Stop> _enforceUrgentFirst(List<Stop> stops) {
    if (stops.length < 2) return stops;
    final result = [...stops];
    for (int i = result.length - 1; i > 0; i--) {
      if ((result[i].priority ?? 2) == 1 && (result[i - 1].priority ?? 2) == 3) {
        final tmp = result[i];
        result[i] = result[i - 1];
        result[i - 1] = tmp;
      }
    }
    return result;
  }
}
