import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final Future<String?> Function()? tokenProvider;

  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.tokenProvider,
  });

  Future<Map<String, String>> _buildHeaders({
    bool withAuth = false,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth && tokenProvider != null) {
      final token = await tokenProvider!.call();
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Uri _buildUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse(
      '$normalizedBase$normalizedPath',
    ).replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool withAuth = false,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final requestHeaders = await _buildHeaders(
      withAuth: withAuth,
      extraHeaders: headers,
    );

    final response = await http
        .get(uri, headers: requestHeaders)
        .timeout(timeout);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final requestHeaders = await _buildHeaders(
      withAuth: withAuth,
      extraHeaders: headers,
    );

    final response = await http
        .post(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(timeout);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final requestHeaders = await _buildHeaders(
      withAuth: withAuth,
      extraHeaders: headers,
    );

    final response = await http
        .put(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(timeout);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final requestHeaders = await _buildHeaders(
      withAuth: withAuth,
      extraHeaders: headers,
    );

    final response = await http
        .patch(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(timeout);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final requestHeaders = await _buildHeaders(
      withAuth: withAuth,
      extraHeaders: headers,
    );

    final response = await http
        .delete(
          uri,
          headers: requestHeaders,
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final rawBody = response.body.trim();

    Map<String, dynamic> decodedBody;
    if (rawBody.isEmpty) {
      decodedBody = <String, dynamic>{};
    } else {
      final dynamic parsed = jsonDecode(rawBody);
      if (parsed is Map<String, dynamic>) {
        decodedBody = parsed;
      } else {
        decodedBody = <String, dynamic>{'data': parsed};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractErrorMessage(decodedBody, response),
      responseBody: decodedBody,
    );
  }

  String _extractErrorMessage(
    Map<String, dynamic> body,
    http.Response response,
  ) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      final msg = error['message'];
      if (msg != null) return msg.toString();
      final code = error['code'];
      if (code != null) return code.toString();
    }

    final message = body['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    return 'Request failed with status ${response.statusCode}';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? responseBody;

  ApiException({
    required this.statusCode,
    required this.message,
    this.responseBody,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}