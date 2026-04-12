import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

/// Central HTTP client for the customer app.
/// - Attaches Bearer token automatically.
/// - Retries once on 401 using stored refresh token.
/// - Supports GET / POST / PATCH / DELETE + multipart uploads.
class ApiClient {
  static const String baseUrl = 'https://back2eat-api.onrender.com/api/v1';
  static const _timeout = Duration(seconds: 20);

  final TokenStorage _storage;
  ApiClient(this._storage);

  Map<String, String> _headers({String? restaurantId}) {
    final token = _storage.accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (restaurantId != null) 'x-restaurant-id': restaurantId,
    };
  }

  // ── Refresh token ──────────────────────────────────────────────────

  bool _refreshing = false;

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    final refresh = _storage.refreshToken;
    if (refresh == null) return false;
    _refreshing = true;
    try {
      final res = await http
          .post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final access = body['accessToken'] as String?;
        final newRefresh = body['refreshToken'] as String?;
        if (access != null && newRefresh != null) {
          await _storage.saveTokens(
              accessToken: access, refreshToken: newRefresh);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  // ── Core request executor ──────────────────────────────────────────

  Future<Map<String, dynamic>> _exec(
      Future<http.Response> Function() request, {
        bool retry = true,
        String? restaurantId,
      }) async {
    var res = await request().timeout(_timeout);
    if (res.statusCode == 401 && retry) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        res = await request().timeout(_timeout);
      } else {
        await _storage.clear();
        throw ApiException(
            message: 'Session expired. Please log in again.',
            statusCode: 401);
      }
    }
    return _handle(res);
  }

  // ── Public methods ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
      String path, {
        Map<String, dynamic>? params,
        String? restaurantId,
      }) async {
    Uri uri = Uri.parse('$baseUrl$path');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(
          queryParameters:
          params.map((k, v) => MapEntry(k, v.toString())));
    }
    return _exec(
          () => http.get(uri, headers: _headers(restaurantId: restaurantId)),
      restaurantId: restaurantId,
    );
  }

  Future<Map<String, dynamic>> post(
      String path,
      Map<String, dynamic> body, {
        String? restaurantId,
        bool auth = true,
      }) async {
    final headers = auth
        ? _headers(restaurantId: restaurantId)
        : {'Content-Type': 'application/json', 'Accept': 'application/json'};
    return _exec(
          () => http.post(Uri.parse('$baseUrl$path'),
          headers: headers, body: jsonEncode(body)),
    );
  }

  Future<Map<String, dynamic>> patch(
      String path,
      Map<String, dynamic> body, {
        String? restaurantId,
      }) async {
    return _exec(
          () => http.patch(Uri.parse('$baseUrl$path'),
          headers: _headers(restaurantId: restaurantId),
          body: jsonEncode(body)),
    );
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _exec(
          () => http.delete(Uri.parse('$baseUrl$path'), headers: _headers()),
    );
  }

  // ── Response handler ───────────────────────────────────────────────

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body['message'] as String? ?? 'Unknown error';
    throw ApiException(message: msg, statusCode: res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}