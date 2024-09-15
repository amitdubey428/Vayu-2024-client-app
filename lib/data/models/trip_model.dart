// lib/models/trip_model.dart
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/data/models/user_public_info.dart';

class TripModel {
  final int? tripId;
  final String tripName;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  List<UserPublicInfo> participants;
  final int? participantCount;
  List<DayPlanModel> dayPlans;

  TripModel({
    this.tripId,
    required this.tripName,
    required this.startDate,
    required this.endDate,
    this.description = '',
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.participants = const [],
    this.participantCount,
    this.dayPlans = const [],
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      tripId: json['trip_id'],
      tripName: json['trip_name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      description: json['description'] ?? '',
      isArchived: json['is_archived'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => UserPublicInfo.fromMap(p))
              .toList() ??
          [],
      participantCount: json['participant_count'],
      dayPlans: (json['day_plans'] as List<dynamic>?)
              ?.map((e) => DayPlanModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tripId != null) 'trip_id': tripId,
      'trip_name': tripName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'description': description,
      'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'participants': participants.map((p) => p.toMap()).toList(),
      'participant_count': participantCount,
      'day_plans': dayPlans.map((e) => e.toJson()).toList(),
    };
  }

  TripModel copyWith({
    int? tripId,
    String? tripName,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<UserPublicInfo>? participants,
    int? participantCount,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      tripName: tripName ?? this.tripName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      participantCount: participantCount ?? this.participantCount,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'trip_name': tripName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'description': description,
      'is_archived': isArchived,
    };
  }

  bool isUserAdmin(String currentUserId) {
    return participants.any((participant) =>
        participant.firebaseUid == currentUserId && participant.isAdmin);
  }
}
