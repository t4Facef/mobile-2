// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_2_bim/core/secrets.dart';

const _francaLat = -20.5386;
const _francaLng = -47.4008;

Future<String?> findPlace(String rawAddress) async {
  final cleaned = rawAddress.replaceAll(',', ' ').replaceAll(RegExp(r' +'), ' ').trim();
  final query = cleaned.toLowerCase().contains('franca') ? cleaned : '$cleaned Franca SP Brasil';
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/place/textsearch/json'
    '?query=${Uri.encodeComponent(query)}'
    '&location=$_francaLat,$_francaLng&radius=25000'
    '&language=pt-BR&key=$googleMapsApiKey',
  );
  final response = await http.get(url);
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  if (data['status'] != 'OK' || (data['results'] as List).isEmpty) {
    print('  API status: ${data['status']}');
    return null;
  }
  final first = data['results'][0] as Map<String, dynamic>;
  final loc = first['geometry']['location'];
  final lat = (loc['lat'] as num).toDouble();
  final lng = (loc['lng'] as num).toDouble();
  final inRange = (lat - _francaLat).abs() < 0.5 && (lng - _francaLng).abs() < 0.5;
  print('  formatted: ${first['formatted_address']}  coords: $lat,$lng  inRange: $inRange');
  return inRange ? '$lat,$lng' : null;
}

Future<void> main() async {
  final tests = {
    'COM vírgulas (Groq antigo)': [
      'Rua Major Claudiano, 1200, Franca, SP, Brasil',
      'Av. Champagnat, 820, Franca, SP, Brasil',
    ],
    'SEM vírgulas (Groq novo)': [
      'Rua Major Claudiano 1200 Franca SP Brasil',
      'Av Champagnat 820 Franca SP Brasil',
    ],
    'Endereços genéricos Franca': [
      'Rua Maria Martins de Araujo 729 Franca SP',
      'Rua Brodowski 150 Franca SP',
      'Rua Presidente Kennedy 500 Franca SP',
      'Rua Frederico Moura 680 Franca SP',
      'Av Major Nicacio 2300 Franca SP',
    ],
    'Sem número (endereço parcial)': [
      'Rua Major Claudiano Franca SP',
      'Av Champagnat Franca SP',
    ],
  };

  for (final entry in tests.entries) {
    print('\n══ ${entry.key} ══');
    for (final addr in entry.value) {
      print('\n▸ $addr');
      final result = await findPlace(addr);
      print('  resultado: $result');
    }
  }
}
