import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/secrets.dart';
import '../models/stop_model.dart';

class GeminiService {
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.1-8b-instant';

  String _extractErrorMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['error'] as Map?)?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }

  Future<List<Stop>> parseDeliveryList(String rawText) async {
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
          {
            'role': 'system',
            'content': 'Você é um assistente de rotas de entrega brasileiro. '
                'Quando o usuário enviar uma lista de entregas em texto livre, '
                'extraia cada endereço e retorne APENAS um array JSON válido, sem nenhum texto adicional, sem markdown. '
                'Cada objeto deve ter:\n'
                '- "address": rua, avenida e número (string)\n'
                '- "complement": apto, bloco ou ponto de referência (string, vazio se não houver)\n'
                '- "note": produto ou observação da entrega (string ou null)\n'
                '- "time": horário no formato HH:mm (string ou null)',
          },
          {
            'role': 'user',
            'content': rawText,
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      final detail = _extractErrorMessage(response.body);
      throw Exception('Erro na API (${response.statusCode}): $detail');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = body['choices'][0]['message']['content'] as String;

    // Remove blocos de markdown caso o modelo os adicione
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
