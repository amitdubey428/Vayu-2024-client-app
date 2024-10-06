// lib/data/repositories/trip_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/data/models/user_public_info.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/core/utils/custom_exceptions.dart';

class TripRepository {
  final ApiService _apiService;

  TripRepository(this._apiService);

  Future<List<TripModel>> getUserTrips() async {
    try {
      final response = await _apiService.get('/trips');
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TripModel.fromJson(json)).toList();
      } else {
        throw Exception(
            'Unable to load trips. Please check your internet connection and try again.');
      }
    } catch (e) {
      throw ApiException('An error occurred while fetching trips: $e');
    }
  }

  Future<TripModel> getTripDetails(int tripId) async {
    try {
      final response = await _apiService.get('/trips/$tripId');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TripModel.fromJson(jsonData);
      } else {
        throw ApiException(
            'Failed to load trip details, please check your internet connection');
      }
    } catch (e) {
      throw ApiException('An error occurred while fetching trip details: $e');
    }
  }

  Future<TripModel> createTrip(TripModel trip) async {
    try {
      final response = await _apiService.post(
        '/trips/',
        body: json.encode(trip.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return TripModel.fromJson(jsonMap);
      } else {
        throw Exception('Unable to create trip. Please try again later.');
      }
    } catch (e) {
      throw ApiException('An error occurred while creating the trip: $e');
    }
  }

  Future<TripModel> updateTrip(TripModel trip) async {
    try {
      final response = await _apiService.put(
        '/trips/${trip.tripId}',
        body: json.encode(trip.toUpdateJson()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return TripModel.fromJson(jsonMap);
      } else {
        throw ApiException('Failed to update trip: ${response.body}');
      }
    } catch (e) {
      throw ApiException('An error occurred while updating the trip: $e');
    }
  }

  Future<void> deleteTrip(int tripId) async {
    try {
      final response = await _apiService.delete('/trips/$tripId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Failed to delete trip: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('An error occurred while deleting the trip: $e');
    }
  }

  Future<void> toggleArchiveTrip(int tripId, bool archive) async {
    try {
      final response = await _apiService.patch(
        '/trips/$tripId/archive',
        body: json.encode({'archive': archive}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException('Failed to archive trip: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('An error occurred while archiving the trip: $e');
    }
  }

  Future<void> leaveTrip(int tripId) async {
    try {
      final response = await _apiService.delete('/trips/$tripId/leave');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Failed to leave trip: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('An error occurred while leaving the trip: $e');
    }
  }

  Future<Map<String, dynamic>> addParticipant(
      int tripId, String identifier) async {
    try {
      final response = await _apiService.post(
        '/trips/$tripId/add-participant',
        body: json.encode({'identifier': identifier}),
        headers: {'Content-Type': 'application/json'},
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
      } else {
        throw ApiException('Failed to add participant: ${response.body}');
      }
    } catch (e) {
      throw ApiException('An error occurred while adding participant: $e');
    }
  }

  Future<Map<String, dynamic>> generateInviteLink(int tripId) async {
    try {
      final response = await _apiService.post('/trips/$tripId/invite');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String invitationCode = data['invitation_code'];
        final String expiresAt = data['expires_at'];

        return {
          'invitation_link': 'vayuapp://join-trip/$invitationCode',
          'invitation_code': invitationCode,
          'expires_at': expiresAt,
        };
      } else {
        throw ApiException('Failed to generate invite link: ${response.body}');
      }
    } catch (e) {
      throw ApiException('An error occurred while generating invite link: $e');
    }
  }

  Future<TripModel> joinTripByInvitation(String invitationCode) async {
    try {
      final response = await _apiService.post(
        '/trips/join',
        body: json.encode({'invitation_code': invitationCode}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return TripModel.fromJson(jsonMap);
      } else {
        throw ApiException(
            'Unable to join trip. The invitation may be invalid or expired.');
      }
    } catch (e) {
      throw ApiException('An error occurred while joining the trip: $e');
    }
  }

  Future<List<DayPlanModel>> getTripDayPlans(int tripId) async {
    try {
      final response = await _apiService.get('/trips/$tripId/day-plans');
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DayPlanModel.fromJson(json)).toList();
      } else {
        throw ApiException('Failed to get day plans: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('An error occurred while fetching day plans: $e');
    }
  }

  Future<DayPlanModel> updateOrCreateDayPlan(
      int tripId, DayPlanModel dayPlan) async {
    try {
      final response = await _apiService.put(
        '/trips/$tripId/day-plans/${dayPlan.dayPlanId ?? 'new'}',
        body: json.encode(dayPlan.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return DayPlanModel.fromJson(jsonMap);
      } else {
        throw ApiException(
            'Failed to update/create day plan: ${response.body}');
      }
    } catch (e) {
      throw ApiException(
          'An error occurred while updating/creating day plan: $e');
    }
  }

  Future<void> deleteDayPlan(int tripId, int dayPlanId) async {
    try {
      final response =
          await _apiService.delete('/trips/$tripId/day-plans/$dayPlanId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Failed to delete day plan: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('An error occurred while deleting day plan: $e');
    }
  }

  Future<bool> isSoleAdmin(int tripId) async {
    try {
      final response = await _apiService.get('/trips/$tripId/is-sole-admin');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['is_sole_admin'] as bool;
      } else {
        throw ApiException(
            'Failed to check sole admin status: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException(
          'An error occurred while checking sole admin status: $e');
    }
  }

  Future<void> makeUserAdmin(int tripId, int userId) async {
    try {
      final response = await _apiService.patch(
        '/trips/$tripId/make-admin/$userId',
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw ApiException('Failed to make user admin: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('An error occurred while making user admin: $e');
    }
  }

  Future<void> removeParticipant(int tripId, int userId) async {
    try {
      final response =
          await _apiService.delete('/trips/$tripId/remove-participant/$userId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
            'Failed to remove participant: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('An error occurred while removing participant: $e');
    }
  }
}
