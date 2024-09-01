import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/data/models/user_public_info.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'dart:developer' as developer;

import 'package:vayu_flutter_app/core/utils/custom_exceptions.dart';

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
      final response = await _apiService.post('/trips/',
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

  Future<Map<String, dynamic>> addParticipant(
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
        Map<String, dynamic> result = json.decode(response.body);
        return {
          'added_participants': (result['added_participants'] as List)
              .map((item) =>
                  UserPublicInfo.fromMap(item as Map<String, dynamic>))
              .toList(),
          'already_in_trip': (result['already_in_trip'] as List).cast<String>(),
        };
      } else if (response.statusCode == 404) {
        throw ApiException('No users found, Invite them to Vayu!');
      } else {
        throw ApiException('Failed to add participant: ${response.body}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw NoInternetException('No internet connection');
      } else if (e is ApiException) {
        rethrow;
      } else {
        throw ApiException('An unexpected error occurred: $e');
      }
    }
  }

  Future<String> generateInviteLink(int tripId) async {
    try {
      final response = await _apiService.post(
        '/trips/$tripId/invite',
        headers: {
          'Authorization': 'Bearer ${await _getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String invitationCode = data['invitation_code'];
        return 'vayuapp://join-trip/$invitationCode';
      } else {
        throw ApiException('Failed to generate invite link: ${response.body}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw NoInternetException('No internet connection');
      } else if (e is ApiException) {
        rethrow;
      } else {
        throw ApiException('An unexpected error occurred: $e');
      }
    }
  }

  Future<TripModel> joinTripByInvitation(String invitationCode) async {
    try {
      developer.log('Original invitation code: $invitationCode');

      List<String> prefixes = ["http://", "https://", "vayuapp://"];
      String? matchedPrefix = prefixes.firstWhere(
        (prefix) => invitationCode.startsWith(prefix),
        orElse: () => '',
      );

      if (matchedPrefix.isNotEmpty) {
        if (matchedPrefix == "vayuapp://") {
          List<String> parts = invitationCode.split('/');
          if (parts.length >= 4 && parts[2] == "join-trip") {
            invitationCode = parts[3];
          }
        } else {
          final uri = Uri.parse(invitationCode);
          developer.log('Path segments: ${uri.pathSegments}');

          if (uri.pathSegments.length > 2 &&
              uri.pathSegments[1] == "join-trip") {
            invitationCode = uri.pathSegments[2];
          }
        }
      }

      developer.log('Processed invitation code: $invitationCode');

      final response = await _apiService.post(
        '/trips/join',
        headers: {
          'Authorization': 'Bearer ${await _getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'invitation_code': invitationCode}),
      );

      developer.log('Response status code: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return TripModel.fromJson(jsonMap);
      } else {
        throw ApiException('Failed to join trip: ${response.body}');
      }
    } on SocketException {
      throw NoInternetException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      developer.log('Error in joinTripByInvitation: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('An unexpected error occurred: $e');
    }
  }
}
