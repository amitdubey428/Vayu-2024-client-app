import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vayu_flutter_app/models/user_model.dart';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) {
    return http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  Future<http.Response> post(String endpoint,
      {Map<String, String>? headers, Object? body}) {
    return http.post(Uri.parse('$baseUrl$endpoint'),
        headers: headers, body: body);
  }

  Future<http.Response> put(String endpoint,
      {Map<String, String>? headers, Object? body}) {
    return http.put(Uri.parse('$baseUrl$endpoint'),
        headers: headers, body: body);
  }

  Future<bool> doesUserExistByPhone(String phoneNumber) async {
    try {
      final encodedPhoneNumber = Uri.encodeQueryComponent(phoneNumber);
      final response =
          await get('/users/exists_by_phone?phone=$encodedPhoneNumber');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'];
      } else {
        throw Exception(
            'Failed to check user existence: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Connection timed out');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<String> createUser(
      Map<String, dynamic> userDetails, String idToken) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
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
}
