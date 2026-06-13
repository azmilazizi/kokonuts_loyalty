import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  const AuthException(this.message, [this.statusCode]);
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _baseUrl = 'https://crm.kokonuts.my/loyalty/api';
  static const _tokenKey = 'auth_token';
  static const _phoneKey = 'auth_phone';
  static const _customerIdKey = 'auth_customer_id';

  String? _token;
  String? _phone;
  int? _customerId;
  UserProfile? _cachedProfile;

  String? get token => _token;
  String? get phone => _phone;
  int? get customerId => _customerId;
  bool get isLoggedIn => _token != null;
  UserProfile? get cachedProfile => _cachedProfile;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _phone = prefs.getString(_phoneKey);
    final id = prefs.getInt(_customerIdKey);
    _customerId = id;
  }

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Register / claim account (first-time password set).
  /// Uses set_password without current_password.
  Future<void> register(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/member/set_password'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'password': password,
        'password_confirm': password,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return;
    final json = _tryDecode(response.body);
    throw AuthException(
      _extractMessage(json) ?? 'Registration failed. Please try again.',
      response.statusCode,
    );
  }

  Future<void> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/member/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(json);
      await _saveSession(user.token, phone, user.customerId);
      notifyListeners();
      return;
    }
    final json = _tryDecode(response.body);
    throw AuthException(
      _extractMessage(json) ?? 'Login failed. Please check your credentials.',
      response.statusCode,
    );
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/member/logout'),
          headers: _authHeaders,
        );
      } catch (_) {
        // Ignore network errors on logout — clear local state regardless.
      }
    }
    _token = null;
    _phone = null;
    _customerId = null;
    _cachedProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_customerIdKey);
    notifyListeners();
  }

  Future<UserProfile> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfile != null) return _cachedProfile!;
    final response = await http.get(
      Uri.parse('$_baseUrl/member/me'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cachedProfile = UserProfile.fromJson(json);
      if (_customerId == null && _cachedProfile!.id != 0) {
        _customerId = _cachedProfile!.id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_customerIdKey, _customerId!);
      }
      return _cachedProfile!;
    }
    if (response.statusCode == 401) {
      await logout();
      throw const AuthException('Session expired. Please sign in again.', 401);
    }
    throw const AuthException('Failed to load profile. Please try again.');
  }

  Future<UserProfile> updateProfile({String? name, String? birthday}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (birthday != null) body['birthday'] = birthday;

    final response = await http.put(
      Uri.parse('$_baseUrl/member/profile'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cachedProfile = UserProfile.fromJson(json);
      notifyListeners();
      return _cachedProfile!;
    }
    final json = _tryDecode(response.body);
    throw AuthException(
      _extractMessage(json) ?? 'Failed to update profile.',
      response.statusCode,
    );
  }

  /// Change password for an already-authenticated user.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/member/set_password'),
      headers: _authHeaders,
      body: jsonEncode({
        'phone': _phone ?? '',
        'password': newPassword,
        'password_confirm': newPassword,
        'current_password': currentPassword,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return;
    final json = _tryDecode(response.body);
    throw AuthException(
      _extractMessage(json) ?? 'Failed to change password.',
      response.statusCode,
    );
  }

  Future<List<CashbackTransaction>> getTransactions({
    int page = 1,
    int perPage = 20,
  }) async {
    final id = _customerId;
    if (id == null) return [];
    final uri = Uri.parse(
      '$_baseUrl/transactions/$id?page=$page&per_page=$perPage',
    );
    final response = await http.get(uri, headers: _authHeaders);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as Map<String, dynamic>?) ?? {};
      final items = (data['items'] as List<dynamic>?) ?? [];
      return items
          .map((t) => CashbackTransaction.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    if (response.statusCode == 401) {
      await logout();
      throw const AuthException('Session expired. Please sign in again.', 401);
    }
    return [];
  }

  Future<void> _saveSession(String token, String phone, int customerId) async {
    _token = token;
    _phone = phone;
    _customerId = customerId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_phoneKey, phone);
    await prefs.setInt(_customerIdKey, customerId);
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? _extractMessage(Map<String, dynamic>? json) {
    if (json == null) return null;
    // Try common error shapes: {message}, {error}, {data: {message}}
    return json['message'] as String? ??
        json['error'] as String? ??
        (json['data'] as Map<String, dynamic>?)?['message'] as String?;
  }
}
