// Script de debug para Geocoding API (alternativa à Places)
// Rodar com: dart run bin/debug_geocoding.dart
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
  print('=== DEBUG: Google Geocoding API ===\n');

  for (final address in testAddresses) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Endereço: $address');

    await _test(address, strategy: 'plain');
    await _test(address, strategy: 'component');
    print('');
  }
}

Future<void> _test(String address, {required String strategy}) async {
  final label = strategy == 'plain' ? 'SEM components' : 'COM components=locality:Franca';
  print('\n  [$label]');

  var urlStr =
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=${Uri.encodeComponent(address)}'
      '&language=pt-BR'
      '&key=$googleMapsApiKey';

  if (strategy == 'component') {
    urlStr += '&components=locality:Franca|administrative_area:SP|country:BR';
  }

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
      final formattedAddress = first['formatted_address'] ?? '(sem endereço)';
      final loc = first['geometry']['location'];
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      final inRange = (lat - _francaLat).abs() < 0.5 && (lng - _francaLng).abs() < 0.5;

      print('  Endereço formatado: $formattedAddress');
      print('  Coordenadas: lat=$lat, lng=$lng');
      print('  Dentro do range de Franca (50km): $inRange');

      final types = (first['types'] as List?)?.join(', ') ?? '';
      print('  Tipos: $types');
    }
  } catch (e) {
    print('  EXCEÇÃO: $e');
  }
}
