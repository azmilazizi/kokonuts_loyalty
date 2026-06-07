import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/claim_models.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);
}

class LoyaltyApiService {
  static const _baseUrl = 'https://crm.kokonuts.my/loyalty/api';

  Future<ClaimValidation> validateToken(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/claim/$token'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 404) {
      throw const ApiException(404, 'Not found');
    }

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Request failed');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ClaimValidation.fromJson(json);
  }

  Future<ClaimResult> submitClaim(
      String token, String name, String phone) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/claim/$token'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'name': name, 'phone': phone}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ClaimResult.fromJson(json);
    }

    throw ApiException(response.statusCode, response.body);
  }
}
