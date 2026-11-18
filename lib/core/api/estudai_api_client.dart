import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Erro retornado pela API Estudaí, já convertido para uma mensagem legível.
class EstudaiApiException implements Exception {
  const EstudaiApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente HTTP centralizado. A URL pode ser trocada sem alterar o código:
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
class EstudaiApiClient {
  const EstudaiApiClient({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) : _storage = secureStorage;

  final String baseUrl;
  final FlutterSecureStorage _storage;

  static const _accessKey = 'estudai_access_token';
  static const _refreshKey = 'estudai_refresh_token';

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/v1$path');

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'detail': decoded.toString()};
  }

  String _errorMessage(Map<String, dynamic> data, int statusCode) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      final messages = detail
          .whereType<Map>()
          .map((item) => item['msg']?.toString())
          .whereType<String>()
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return 'Falha na comunicação com o servidor (HTTP $statusCode).';
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null) headers['Authorization'] = 'Bearer $accessToken';

    late final http.Response response;
    try {
      final uri = _uri(path);
      if (method == 'GET') {
        response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 20),
        );
      } else if (method == 'POST') {
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 20));
      } else {
        throw StateError('Método HTTP não suportado: $method');
      }
    } on EstudaiApiException {
      rethrow;
    } catch (_) {
      throw const EstudaiApiException(
        'Não foi possível conectar à API. Verifique se ela está ligada e se o endereço está correto.',
      );
    }

    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EstudaiApiException(
        _errorMessage(data, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    final access = data['access_token'];
    final refresh = data['refresh_token'];
    if (access is! String || refresh is! String) {
      throw const EstudaiApiException(
        'A API respondeu sem os tokens de autenticação esperados.',
      );
    }
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _send('POST', '/auth/register', body: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
    await _storeTokens(data);
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _send('POST', '/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });
    await _storeTokens(data);
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  Future<Map<String, dynamic>> _refresh() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null) {
      throw const EstudaiApiException('Sua sessão expirou. Entre novamente.');
    }
    final data = await _send(
      'POST',
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    await _storeTokens(data);
    return data;
  }

  /// Consulta o usuário atual. Se o access token expirou, renova a sessão
  /// uma vez usando o refresh token e repete a consulta.
  Future<Map<String, dynamic>> currentUser() async {
    var access = await _storage.read(key: _accessKey);
    if (access == null) {
      throw const EstudaiApiException('Nenhuma sessão salva. Entre novamente.');
    }
    try {
      final data = await _send('GET', '/auth/me', accessToken: access);
      return Map<String, dynamic>.from(data);
    } on EstudaiApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      await _refresh();
      access = await _storage.read(key: _accessKey);
      if (access == null) rethrow;
      final data = await _send('GET', '/auth/me', accessToken: access);
      return Map<String, dynamic>.from(data);
    }
  }

  /// Envia um PDF e recebe as questões geradas pela IA (`POST /questions/generate`).
  /// Se o access token expirou, renova a sessão uma vez e repete o envio.
  Future<Map<String, dynamic>> generateQuestions({
    required List<int> pdfBytes,
    required String filename,
    int numQuestions = 5,
    int numOptions = 4,
  }) async {
    Future<Map<String, dynamic>> attempt(String access) async {
      final request = http.MultipartRequest('POST', _uri('/questions/generate'))
        ..headers['Authorization'] = 'Bearer $access'
        ..fields['num_questions'] = '$numQuestions'
        ..fields['num_options'] = '$numOptions'
        ..files.add(http.MultipartFile.fromBytes('file', pdfBytes, filename: filename));
      late final http.Response response;
      try {
        final streamed = await request.send().timeout(const Duration(seconds: 150));
        response = await http.Response.fromStream(streamed);
      } catch (_) {
        throw const EstudaiApiException(
          'Não foi possível conectar à API. Verifique se ela está ligada e se o endereço está correto.',
        );
      }
      final data = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw EstudaiApiException(
          _errorMessage(data, response.statusCode),
          statusCode: response.statusCode,
        );
      }
      return data;
    }

    var access = await _storage.read(key: _accessKey);
    if (access == null) {
      throw const EstudaiApiException('Nenhuma sessão salva. Entre novamente.');
    }
    try {
      return await attempt(access);
    } on EstudaiApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      await _refresh();
      access = await _storage.read(key: _accessKey);
      if (access == null) rethrow;
      return attempt(access);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    try {
      if (refreshToken != null) {
        await _send(
          'POST',
          '/auth/logout',
          body: {'refresh_token': refreshToken},
        );
      }
    } finally {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
