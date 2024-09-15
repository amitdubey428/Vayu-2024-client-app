// In trip_service.dart

import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/data/repositories/trip_repository.dart';
import 'dart:developer' as developer;

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

  Future<String> generateInviteLink(int tripId) async {
    try {
      return await _tripRepository.generateInviteLink(tripId);
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
}
