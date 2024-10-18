// lib/data/models/user_model.dart

import 'dart:convert';

class UserModel {
  final int userId; // db uid
  final String uid; // firebase uid
  final String? fullName;
  final String? email;
  final String phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final String? country;
  final String? state;
  final String? occupation;
  final List<String>? interests;
  final bool visibleToPublic;
  final int profileCompletion;
  final DateTime? lastLogin;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.userId, // db uid
    required this.uid, // firebase uid
    this.fullName,
    this.email,
    required this.phoneNumber,
    this.birthDate,
    this.gender,
    this.country,
    this.state,
    this.occupation,
    this.interests,
    this.visibleToPublic = true,
    required this.profileCompletion,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId, // db uid
      'firebase_uid': uid, // firebase uid
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'date_of_birth': birthDate?.toIso8601String(),
      'gender': gender,
      'country': country,
      'state': state,
      'occupation': occupation,
      'interests': interests,
      'visible_to_public': visibleToPublic,
      'profile_completion': profileCompletion,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'], // db uid
      uid: map['firebase_uid'] ?? '', // firebase uid
      fullName: map['full_name'],
      email: map['email'],
      phoneNumber: map['phone_number'] ?? '',
      birthDate: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'])
          : null,
      gender: map['gender'],
      country: map['country'],
      state: map['state'],
      occupation: map['occupation'],
      interests: List<String>.from(map['interests'] ?? []),
      visibleToPublic: map['visible_to_public'] ?? true,
      profileCompletion: map['profile_completion'] ?? 0,
      lastLogin:
          map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  UserModel copyWith({
    int? userId, //db uid
    String? uid, //firebase uid
    String? fullName,
    String? email,
    String? phoneNumber,
    DateTime? birthDate,
    String? gender,
    String? country,
    String? state,
    String? occupation,
    List<String>? interests,
    bool? visibleToPublic,
    int? profileCompletion,
    DateTime? lastLogin,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      state: state ?? this.state,
      occupation: occupation ?? this.occupation,
      interests: interests ?? this.interests,
      visibleToPublic: visibleToPublic ?? this.visibleToPublic,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
