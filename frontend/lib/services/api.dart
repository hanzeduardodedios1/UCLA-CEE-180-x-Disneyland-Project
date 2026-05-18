import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/hotel.dart';
import '../models/route.dart';

class HotelApiException implements Exception {
  HotelApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class HotelApi {
  HotelApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final String _base = apiBaseUrl;

  Future<List<String>> fetchHotelNames() async {
    final uri = Uri.parse('$_base/api/hotels/names');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw HotelApiException('Could not load hotel list (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<String>();
  }

  Future<List<String>> suggestHotels(String query) async {
    final uri = Uri.parse('$_base/api/hotels/suggest').replace(
      queryParameters: {'q': query.trim()},
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw HotelApiException('Could not load suggestions (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<String>();
  }

  Future<HotelRow> searchHotel(String query, {bool exact = false}) async {
    final uri = Uri.parse('$_base/api/hotels/search').replace(
      queryParameters: {
        'q': query.trim(),
        if (exact) 'exact': 'true',
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode == 404) {
      throw HotelApiException('No Disneyland hotel found for "$query"');
    }
    if (response.statusCode == 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is Map && detail['matches'] is List) {
        final names = (detail['matches'] as List).join(', ');
        throw HotelApiException('Multiple matches. Pick one from the dropdown: $names');
      }
      throw HotelApiException('Multiple hotels match — pick from the dropdown.');
    }
    if (response.statusCode != 200) {
      throw HotelApiException('Search failed (${response.statusCode})');
    }
    return HotelRow.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Fetches walking route from backend (Google Directions API, server-side).
  Future<HotelRoute> fetchRoute(String hotelName) async {
    final uri = Uri.parse('$_base/api/hotels/route').replace(
      queryParameters: {'hotel': hotelName.trim()},
    );
    final response = await _client.get(uri);
    if (response.statusCode == 404) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail']?.toString() ?? '';
      if (detail == 'Not Found') {
        throw HotelApiException(
          'Route API not loaded. Restart the backend from the backend folder: '
          'uvicorn main:app --reload --host 127.0.0.1 --port 8000',
        );
      }
      throw HotelApiException(
        detail.isNotEmpty ? detail : 'No Disneyland hotel found for "$hotelName"',
      );
    }
    if (response.statusCode == 503) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw HotelApiException(
        body['detail']?.toString() ?? 'Maps API key not configured on server',
      );
    }
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail']?.toString() ?? 'Route request failed';
      throw HotelApiException('$detail (${response.statusCode})');
    }
    return HotelRoute.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
