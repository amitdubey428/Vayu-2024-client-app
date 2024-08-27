// lib/models/trip_model.dart
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/models/user_public_info.dart';

class TripModel {
  final int? tripId;
  final String tripName;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<UserPublicInfo> participants;

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tripId != null) 'trip_id': tripId,
      'trip_name': tripName,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      'description': description,
      'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'participants': participants,
    };
  }
}
