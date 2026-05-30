import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/secrets.dart';
import '../models/stop_model.dart';

class RouteService {
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Retorna as paradas na ordem otimizada pela Google Directions API.
  /// Com menos de 3 paradas retorna a lista original (sem o que otimizar).
  Future<List<Stop>> optimizeRoute(List<Stop> stops) async {
    if (stops.length < 3) return stops;

    final addresses = stops.map((s) => s.address).toList();

    final origin = Uri.encodeComponent(addresses.first);
    final destination = Uri.encodeComponent(addresses.last);
    final middle = addresses
        .sublist(1, addresses.length - 1)
        .map(Uri.encodeComponent)
        .join('|');

    final url = Uri.parse(
      '$_baseUrl'
      '?origin=$origin'
      '&destination=$destination'
      '&waypoints=optimize:true|$middle'
      '&key=$googleMapsApiKey'
      '&language=pt-BR'
      '&region=br',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Erro na API de rotas (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') {
      throw Exception('Rota não encontrada: ${data['status']}');
    }

    // waypoint_order contém a nova ordem dos pontos intermediários (índice 0 = stops[1])
    final order = (data['routes'][0]['waypoint_order'] as List).cast<int>();
    final middleStops = stops.sublist(1, stops.length - 1);
    final reordered = order.map((i) => middleStops[i]).toList();

    return [stops.first, ...reordered, stops.last];
  }
}
