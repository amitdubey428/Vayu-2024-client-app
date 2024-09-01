import 'dart:convert';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  String? mobileNumber;
  final DateTime birthDate;
  final String gender;
  final String country;
  final String state;
  final String occupation;
  final List<String> interests;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.mobileNumber,
    required this.birthDate,
    this.gender = '',
    this.country = '',
    this.state = '',
    this.occupation = '',
    this.interests = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'firebase_uid': uid,
      'full_name': '$firstName $lastName',
      'email': email,
      'phone_number': mobileNumber,
      'date_of_birth': birthDate.toIso8601String().split('T')[0],
      'gender': gender,
      'country': country,
      'state': state,
      'occupation': occupation,
      'interests': interests,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['firebase_uid'],
      firstName: map['full_name'].split(' ')[0],
      lastName: map['full_name'].split(' ').skip(1).join(' '),
      email: map['email'],
      mobileNumber: map['phone_number'],
      birthDate: DateTime.parse(map['date_of_birth']),
      gender: map['gender'] ?? '',
      country: map['country'] ?? '',
      state: map['state'] ?? '',
      occupation: map['occupation'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
    );
  }
  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
