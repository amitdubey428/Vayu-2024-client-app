import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:vayu_flutter_app/models/trip_model.dart';
import 'package:vayu_flutter_app/models/user_model.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/di/service_locator.dart';
import 'dart:developer' as developer;

import 'package:vayu_flutter_app/utils/custom_exceptions.dart';

class TripService {
  final ApiService _apiService = getIt<ApiService>();
  final AuthNotifier _authNotifier = getIt<AuthNotifier>();

  Future<String?> _getIdToken() async {
    final user = _authNotifier.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  Future<List<TripModel>> getUserTrips() async {
    try {
      final idToken = await _authNotifier.getRefreshedIdToken();
      if (idToken == null) {
        throw Exception('Failed to retrieve authentication token');
      }
      final response = await _apiService.get('/trips');
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TripModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } on SocketException {
      throw NoInternetException('No internet connection');
    } on TimeoutException {
      throw TimeoutException('Connection timed out');
    } catch (e) {
      developer.log("Error fetching trips: $e", name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<TripModel> getTripDetails(int tripId) async {
    try {
      final idToken = await _authNotifier.getRefreshedIdToken();
      if (idToken == null) {
        throw Exception('Failed to retrieve authentication token');
      }
      final response = await _apiService.get('/trips/$tripId');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TripModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load trip details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log("Error fetching trip details: $e",
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<TripModel> createTrip(TripModel trip) async {
    final idToken = await _getIdToken();
    try {
      final response = await _apiService.post('/trips',
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(trip.toJson()));

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return TripModel.fromJson(jsonMap);
      } else {
        throw Exception('Failed to create trip: ${response.body}');
      }
    } catch (e) {
      developer.log('Error in createTrip: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> addParticipant(
      int tripId, String identifier) async {
    try {
      final idToken = await _getIdToken();
      final response = await _apiService.post(
        '/trips/$tripId/add-participant',
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'identifier': identifier}),
      );

      if (response.statusCode == 200) {
        List<dynamic> resultList = json.decode(response.body);
        return resultList.map((item) {
          return {
            'user': UserModel.fromMap(item['user']),
            'status': item['status'],
          };
        }).toList();
      } else {
        throw Exception('Failed to add participant: ${response.body}');
      }
    } catch (e) {
      developer.log('Error in addParticipant: $e');
      rethrow;
    }
  }
}
