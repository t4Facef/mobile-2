import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/secrets.dart';
import '../models/stop_model.dart';

class GeminiService {
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.1-8b-instant';

  static const _weekdays = [
    'domingo', 'segunda-feira', 'terça-feira', 'quarta-feira',
    'quinta-feira', 'sexta-feira', 'sábado',
  ];

  String _extractErrorMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['error'] as Map?)?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }

  Future<List<Stop>> parseDeliveryList(
    String rawText, {
    required DateTime now,
    LatLng? userLocation,
  }) async {
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dayStr = _weekdays[now.weekday % 7];
    final locationStr = userLocation != null
        ? 'lat ${userLocation.latitude.toStringAsFixed(4)}, lng ${userLocation.longitude.toStringAsFixed(4)} (Franca, SP)'
        : 'não disponível';

    final systemPrompt = '''Você é um assistente de rotas de delivery operando exclusivamente em Franca, SP, Brasil.

Contexto atual:
- Dia: $dayStr
- Hora: $timeStr
- Localização do entregador: $locationStr

Analise a lista de entregas abaixo considerando esse contexto. Para cada entrega, retorne um objeto JSON com:
- "address": rua e número SEM vírgulas, SEMPRE com " Franca SP Brasil" no final (ex: "Rua Major Claudiano 1850 Franca SP Brasil")
- "complement": apto, bloco ou ponto de referência (string vazia se não houver)
- "note": produto ou observação da entrega (string ou null)
- "time": horário no formato HH:mm (string ou null)
- "priority": número de 1 a 3 conforme urgência:
    1 = urgente (pouco tempo restante, comida quente como pizza/japonês/hambúrguer)
    2 = normal (tempo razoável ou comida que tolera espera)
    3 = pode esperar (muito tempo disponível ou produto frio/bebida)
    Em $dayStr próximo de $timeStr, considere que o trânsito pode ser ${now.weekday >= 5 ? 'intenso (fim de semana)' : 'moderado'}.
- "feasible": true se ainda é possível entregar no horário, false se o horário já passou ou é claramente impossível de cumprir a partir de $timeStr

Retorne APENAS o array JSON válido, sem texto adicional, sem markdown.''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $groqApiKey',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.1,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': rawText},
        ],
      }),
    );

    if (response.statusCode != 200) {
      final detail = _extractErrorMessage(response.body);
      throw Exception('Erro na API (${response.statusCode}): $detail');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = body['choices'][0]['message']['content'] as String;

    final clean = text.replaceAll(RegExp(r'```(?:json)?\s*|\s*```'), '').trim();
    final jsonStart = clean.indexOf('[');
    final jsonEnd = clean.lastIndexOf(']') + 1;
    if (jsonStart == -1 || jsonEnd == 0) {
      throw Exception('Resposta da IA não contém lista válida.');
    }

    final List<dynamic> list = jsonDecode(clean.substring(jsonStart, jsonEnd));
    return list.map((e) => Stop.fromJson(e as Map<String, dynamic>)).toList();
  }
}
