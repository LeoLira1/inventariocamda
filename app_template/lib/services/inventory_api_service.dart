import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/inventory_item.dart';

class InventoryApiService {
  InventoryApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<InventoryItem>> fetchFromSource(String sourceUrl) async {
    final response = await _client.get(Uri.parse(sourceUrl));

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception('Falha ao carregar dados (${response.statusCode}).');
    }

    final payload = response.body;
    final parsed = _parsePayload(payload);

    if (parsed.isEmpty) {
      throw Exception(
        'A fonte não retornou registros no formato esperado. '
        'Use uma URL que exponha um JSON de itens.',
      );
    }

    return parsed.map(InventoryItem.fromMap).toList();
  }

  List<Map<String, dynamic>> _parsePayload(String payload) {
    final trimmed = payload.trim();

    final decoded = _tryDecodeJson(trimmed);
    if (decoded != null) {
      return decoded;
    }

    final arrayRegex = RegExp(r'(\[(.|\n|\r)*\])');
    final match = arrayRegex.firstMatch(trimmed);
    if (match != null) {
      final possibleJson = match.group(0);
      if (possibleJson != null) {
        final extracted = _tryDecodeJson(possibleJson);
        if (extracted != null) {
          return extracted;
        }
      }
    }

    return const [];
  }

  List<Map<String, dynamic>>? _tryDecodeJson(String value) {
    try {
      final dynamic jsonData = jsonDecode(value);
      if (jsonData is List) {
        return jsonData
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
      }

      if (jsonData is Map<String, dynamic>) {
        final candidateKeys = ['items', 'data', 'result', 'registros', 'produtos'];
        for (final key in candidateKeys) {
          final collection = jsonData[key];
          if (collection is List) {
            return collection
                .whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList();
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
