// Script de debug para Places Text Search API
// Rodar com: dart run bin/debug_places.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_2_bim/core/secrets.dart';

const _francaLat = -20.5386;
const _francaLng = -47.4008;

const testAddresses = [
  'Rua Major Claudiano 1200 Franca SP Brasil',
  'Av Champagnat 820 Franca SP Brasil',
  'Av Dr Hélio Palermo 3500 Franca SP Brasil',
];

Future<void> main() async {
  print('=== DEBUG: Google Places Text Search API ===\n');

  for (final address in testAddresses) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Endereço: $address');

    await _test(address, withBias: true);
    await _test(address, withBias: false);
    print('');
  }
}

Future<void> _test(String address, {required bool withBias}) async {
  final label = withBias ? 'COM bias (location+radius)' : 'SEM bias';
  print('\n  [$label]');

  var urlStr =
      'https://maps.googleapis.com/maps/api/place/textsearch/json'
      '?query=${Uri.encodeComponent(address)}'
      '&language=pt-BR'
      '&key=$googleMapsApiKey';

  if (withBias) {
    urlStr += '&location=$_francaLat,$_francaLng&radius=25000';
  }

  print('  URL: $urlStr\n');

  try {
    final response = await http.get(Uri.parse(urlStr));
    print('  HTTP: ${response.statusCode}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String;
    print('  Status: $status');

    if (status == 'REQUEST_DENIED') {
      print('  ERRO: ${data['error_message']}');
      return;
    }

    final results = data['results'] as List? ?? [];
    print('  Resultados: ${results.length}');

    if (results.isNotEmpty) {
      final first = results[0] as Map<String, dynamic>;
      final name = first['name'] ?? '(sem nome)';
      final formattedAddress = first['formatted_address'] ?? '(sem endereço)';
      final loc = first['geometry']['location'];
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      final inRange = (lat - _francaLat).abs() < 0.5 && (lng - _francaLng).abs() < 0.5;

      print('  Nome: $name');
      print('  Endereço formatado: $formattedAddress');
      print('  Coordenadas: lat=$lat, lng=$lng');
      print('  Dentro do range de Franca (50km): $inRange');
    }
  } catch (e) {
    print('  EXCEÇÃO: $e');
  }
}
