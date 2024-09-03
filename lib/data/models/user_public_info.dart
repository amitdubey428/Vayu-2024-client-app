class UserPublicInfo {
  final int userId;
  final String firebaseUid;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? country;
  final String? state;
  final bool isAdmin;

  UserPublicInfo({
    required this.userId,
    required this.firebaseUid,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.country,
    this.state,
    this.isAdmin = false,
  });

  factory UserPublicInfo.fromMap(Map<String, dynamic> map) {
    return UserPublicInfo(
      userId: map['user_id'],
      firebaseUid: map['firebase_uid'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      fullName: map['full_name'],
      email: map['email'],
      phoneNumber: map['phone_number'],
      country: map['country'],
      state: map['state'],
      isAdmin: map['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'firebase_uid': firebaseUid,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'country': country,
      'state': state,
      'is_admin': isAdmin,
    };
  }
}
