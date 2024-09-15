class DayPlanModel {
  final int? dayPlanId;
  final int tripId;
  final DateTime date;
  final String? area;
  final String? notes;
  final List<ActivityModel> activities;
  final List<StayModel> stays;

  DayPlanModel({
    this.dayPlanId,
    required this.tripId,
    required this.date,
    this.area,
    this.notes,
    this.activities = const [],
    this.stays = const [],
  });

  factory DayPlanModel.fromJson(Map<String, dynamic> json) {
    return DayPlanModel(
      dayPlanId: json['day_plan_id'],
      tripId: json['trip_id'],
      date: DateTime.parse(json['date']),
      area: json['area'],
      notes: json['notes'],
      activities: (json['activities'] as List<dynamic>?)
              ?.map((activityJson) => ActivityModel.fromJson(activityJson))
              .toList() ??
          [],
      stays: (json['stays'] as List<dynamic>?)
              ?.map((stayJson) => StayModel.fromJson(stayJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_plan_id': dayPlanId,
      'trip_id': tripId,
      'date': date.toIso8601String().split('T')[0],
      'area': area,
      'notes': notes,
      'activities': activities.map((activity) => activity.toJson()).toList(),
      'stays': stays.map((stay) => stay.toJson()).toList(),
    };
  }
}

class ActivityModel {
  final int? activityId;
  final String name;
  final String? description;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? attachmentName;
  final String? attachmentUrl;

  ActivityModel({
    this.activityId,
    required this.name,
    this.description,
    this.startTime,
    this.endTime,
    this.location,
    this.attachmentName,
    this.attachmentUrl,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      activityId: json['activity_id'],
      name: json['name'],
      description: json['description'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      location: json['location'],
      attachmentName: json['attachment_name'],
      attachmentUrl: json['attachment_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_id': activityId,
      'name': name,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'attachment_name': attachmentName,
      'attachment_url': attachmentUrl,
    };
  }
}

class StayModel {
  final int? stayId;
  final String name;
  final String? address;
  final String? checkIn;
  final String? checkOut;
  final String? notes;

  StayModel({
    this.stayId,
    required this.name,
    this.address,
    this.checkIn,
    this.checkOut,
    this.notes,
  });

  factory StayModel.fromJson(Map<String, dynamic> json) {
    return StayModel(
      stayId: json['stay_id'],
      name: json['name'],
      address: json['address'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stay_id': stayId,
      'name': name,
      'address': address,
      'check_in': checkIn,
      'check_out': checkOut,
      'notes': notes,
    };
  }
}
