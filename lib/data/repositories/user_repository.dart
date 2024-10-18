// lib/data/repositories/user_repository.dart

import 'dart:convert';
import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'dart:developer' as developer;

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<UserModel> createUser(
      String firebaseUid, String phoneNumber, String? fullName) async {
    try {
      final response = await _apiService.post(
        '/users/create_user',
        body: json.encode({
          'firebase_uid': firebaseUid,
          'phone_number': phoneNumber,
          'full_name': fullName,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromMap(data);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error creating user: $e');
      rethrow;
    }
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiService.get('/users/me');
    final Map<String, dynamic> data = json.decode(response.body);
    return UserModel.fromMap(data);
  }

  Future<UserModel> updateUser(UserModel user) async {
    try {
      developer.log('Updating user: ${user.toMap()}');
      final response = await _apiService.put(
        '/users/update',
        body: user.toMap(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromMap(data);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating user: $e');
      developer.log('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    await _apiService.delete('/users/delete');
  }
}
