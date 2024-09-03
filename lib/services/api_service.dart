import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'dart:developer' as developer;

import 'package:vayu_flutter_app/core/utils/custom_exceptions.dart';

class ApiService {
  final String baseUrl;
  final http.Client httpClient;
  final Future<String?> Function() getToken;

  ApiService(
    this.baseUrl, {
    http.Client? httpClient,
    required this.getToken,
  }) : httpClient = httpClient ?? http.Client();

  Future<http.Response> _sendRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
  }) async {
    try {
      final Map<String, String> fullHeaders = {...?headers};

      if (requiresAuth) {
        final token = await getToken();
        if (token == null) throw AuthException("Not authenticated");
        fullHeaders['Authorization'] = 'Bearer $token';
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      http.Response response;

      switch (method) {
        case 'GET':
          response = await httpClient.get(uri, headers: fullHeaders);
          break;
        case 'POST':
          response =
              await httpClient.post(uri, headers: fullHeaders, body: body);
          break;
        case 'PATCH':
          response =
              await httpClient.patch(uri, headers: fullHeaders, body: body);
          break;
        case 'PUT':
          response =
              await httpClient.put(uri, headers: fullHeaders, body: body);
          break;
        case 'DELETE':
          response = await httpClient.delete(uri, headers: fullHeaders);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 307) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          developer.log('Redirecting to: $redirectUrl', name: 'api_service');
          final redirectUri = Uri.parse(redirectUrl);
          switch (method) {
            case 'GET':
              response =
                  await httpClient.get(redirectUri, headers: fullHeaders);
              break;
            case 'POST':
              response = await httpClient.post(redirectUri,
                  headers: fullHeaders, body: body);
              break;
            case 'PUT':
              response = await httpClient.put(redirectUri,
                  headers: fullHeaders, body: body);
              break;
            case 'PATCH':
              response = await httpClient.patch(redirectUri,
                  headers: fullHeaders, body: body);
              break;
            case 'DELETE':
              response = await httpClient.delete(uri, headers: fullHeaders);
              break;
          }
        }
      }

      return response;
    } on SocketException {
      throw NoInternetException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      developer.log('API Error: $e', name: 'api_service');
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint,
      {Map<String, String>? headers, bool requiresAuth = true}) async {
    return _sendRequest('GET', endpoint,
            headers: headers, requiresAuth: requiresAuth)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> post(String endpoint,
      {Map<String, String>? headers, Object? body}) async {
    return _sendRequest('POST', endpoint, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> put(String endpoint,
      {Map<String, String>? headers, Object? body}) async {
    return _sendRequest('PUT', endpoint, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> patch(String endpoint,
      {Map<String, String>? headers, Object? body}) async {
    return _sendRequest('PATCH', endpoint, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> delete(String endpoint,
      {Map<String, String>? headers}) async {
    return _sendRequest('DELETE', endpoint, headers: headers)
        .timeout(const Duration(seconds: 30));
  }

  Future<void> updateLastLogin() async {
    try {
      final response = await put('/users/update_last_login');
      if (response.statusCode != 200) {
        throw Exception('Failed to update last login');
      }
    } catch (e) {
      developer.log('Error updating last login: $e', name: 'updateLogin');
      // Consider how to handle this error. Maybe retry later or log it for analytics.
    }
  }

  Future<bool> doesUserExistByPhone(String phoneNumber) async {
    try {
      final encodedPhoneNumber = Uri.encodeQueryComponent(phoneNumber);
      final response = await get(
          '/users/exists_by_phone?phone=$encodedPhoneNumber',
          requiresAuth: false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'];
      } else if (response.statusCode == 500) {
        throw const HttpException('500');
      } else {
        throw Exception(
            'Failed to check user existence: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Connection timed out');
    } catch (e) {
      throw Exception('Unable to verify phone number. Please try again later.');
    }
  }

  Future<String> createUser(Map<String, dynamic> userDetails) async {
    final token = await getToken();
    if (token == null) throw Exception("Not authenticated");
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode(userDetails);

    final response =
        await post('/users/create_user', headers: headers, body: body);

    if (response.statusCode == 200) {
      return "success";
    } else {
      final data = jsonDecode(response.body);
      return data['detail'] ?? "Error Creating User: ${response.statusCode}";
    }
  }

  Future<String> deleteUser(String idToken) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    final response =
        await http.delete(Uri.parse('$baseUrl/users/delete'), headers: headers);

    if (response.statusCode == 204) {
      return "success";
    } else {
      final data = jsonDecode(response.body);
      return data['detail'] ?? "Error Deleting User: ${response.statusCode}";
    }
  }

  Future<bool> checkUserExistsByUID(String idToken) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    final response = await get('/users/exists_by_uid', headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] == 'database_error') {
        throw Exception('Database error when checking user existence');
      }
      return data['exists'];
    } else if (response.statusCode == 404) {
      // User doesn't exist, but this is not an error
      return false;
    } else {
      throw Exception('Error checking user existence: ${response.statusCode}');
    }
  }

  Future<String> updateUser(UserModel userDetails, String idToken) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
    final body = jsonEncode(userDetails.toMap());

    final response = await put('/users/update', headers: headers, body: body);

    if (response.statusCode == 200) {
      return "success";
    } else if (response.statusCode == 404) {
      return "User not found";
    } else {
      final data = jsonDecode(response.body);
      return data['detail'] ?? "Error Updating User: ${response.statusCode}";
    }
  }

  Future<String> updateUserPhone(String phoneNumber, String idToken) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
    final body = jsonEncode({'phone_number': phoneNumber});

    final response =
        await put('/users/update_phone', headers: headers, body: body);

    if (response.statusCode == 200) {
      return "success";
    } else if (response.statusCode == 404) {
      return "User not found";
    } else {
      final data = jsonDecode(response.body);
      return data['detail'] ??
          "Error Updating User Phone: ${response.statusCode}";
    }
  }
}
