// In trip_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/data/repositories/trip_repository.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class TripService {
  final TripRepository _tripRepository;

  TripService(this._tripRepository);

  Future<List<TripModel>> getUserTrips() async {
    try {
      return await _tripRepository.getUserTrips();
    } catch (e) {
      // Log the error
      developer.log("Error fetching trips: $e", name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<TripModel> getTripDetails(int tripId) async {
    try {
      return await _tripRepository.getTripDetails(tripId);
    } catch (e) {
      developer.log("Error fetching trip details: $e",
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<TripModel> createTrip(TripModel trip) async {
    try {
      return await _tripRepository.createTrip(trip);
    } catch (e) {
      developer.log('Error in createTrip: $e', name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<TripModel> updateTrip(TripModel trip) async {
    try {
      return await _tripRepository.updateTrip(trip);
    } catch (e) {
      developer.log('Error in updateTrip: $e', name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<void> deleteTrip(int tripId) async {
    try {
      await _tripRepository.deleteTrip(tripId);
    } catch (e) {
      developer.log('Error in deleteTrip: $e', name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<void> toggleArchiveTrip(int tripId, bool archive) async {
    try {
      await _tripRepository.toggleArchiveTrip(tripId, archive);
    } catch (e) {
      developer.log('Error in toggleArchiveTrip: $e',
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<void> leaveTrip(int tripId) async {
    try {
      await _tripRepository.leaveTrip(tripId);
    } catch (e) {
      developer.log('Error in leaveTrip: $e', name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addParticipant(
      int tripId, String identifier) async {
    try {
      return await _tripRepository.addParticipant(tripId, identifier);
    } catch (e) {
      developer.log('Error in addParticipant: $e',
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateInviteLink(int tripId) async {
    try {
      final invitationData = await _tripRepository.generateInviteLink(tripId);
      return invitationData;
    } catch (e) {
      developer.log('Error in generateInviteLink: $e',
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<TripModel> joinTripByInvitation(String invitationCode) async {
    try {
      return await _tripRepository.joinTripByInvitation(invitationCode);
    } catch (e) {
      developer.log('Error in joinTripByInvitation: $e',
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<List<DayPlanModel>> getTripDayPlans(int tripId) async {
    try {
      return await _tripRepository.getTripDayPlans(tripId);
    } catch (e) {
      developer.log('Error in getTripDayPlans: $e',
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<DayPlanModel> updateOrCreateDayPlan(
      int tripId, DayPlanModel dayPlan) async {
    try {
      return await _tripRepository.updateOrCreateDayPlan(tripId, dayPlan);
    } catch (e) {
      developer.log('[trip_service] Error in updateOrCreateDayPlan: $e');
      rethrow;
    }
  }

  Future<void> deleteDayPlan(int tripId, int dayPlanId) async {
    try {
      await _tripRepository.deleteDayPlan(tripId, dayPlanId);
    } catch (e) {
      developer.log('Error in deleteDayPlan: $e',
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      final apiKey = Platform.isAndroid
          ? dotenv.env['GOOGLE_MAPS_ANDROID_API_KEY']
          : dotenv.env['GOOGLE_MAPS_IOS_API_KEY'];
      final url =
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$apiKey';

      // Try to get cached response
      try {
        final file = await DefaultCacheManager().getSingleFile(url);
        final cachedData = await file.readAsString();
        final data = json.decode(cachedData);
        return List<Map<String, dynamic>>.from(data['results']);
      } catch (e) {
        // If there's an error reading the cache, proceed with the API call
        developer.log('Cache read error: $e', error: e);
      }

      // If not cached, make the API call
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Cache the response
        // Try to cache the response, but don't let cache errors stop the process
        try {
          await DefaultCacheManager().putFile(url, response.bodyBytes);
        } catch (cacheError) {
          developer.log('Cache write error: $cacheError', error: cacheError);
        }
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in searchLocations: $e', error: e);
      rethrow;
    }
  }

  Future<bool> isSoleAdmin(int tripId) async {
    try {
      return await _tripRepository.isSoleAdmin(tripId);
    } catch (e) {
      developer.log('Error in isSoleAdmin: $e', name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<void> makeUserAdmin(int tripId, int userId) async {
    try {
      await _tripRepository.makeUserAdmin(tripId, userId);
    } catch (e) {
      developer.log('Error in makeUserAdmin: $e',
          name: 'trip_service', error: e);
      rethrow;
    }
  }

  Future<void> removeParticipant(int tripId, int userId) async {
    try {
      await _tripRepository.removeParticipant(tripId, userId);
    } catch (e) {
      developer.log('Error in removeParticipant: $e',
          name: 'trip_service', error: e);
      rethrow;
    }
  }
}
