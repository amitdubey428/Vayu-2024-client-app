class UserPublicInfo {
  final int userId;
  final String firebaseUid;
  final String? fullName;
  final String? email;
  final String phoneNumber;
  final String? country;
  final String? state;
  final bool isAdmin;

  UserPublicInfo({
    required this.userId,
    required this.firebaseUid,
    this.fullName,
    this.email,
    required this.phoneNumber,
    this.country,
    this.state,
    this.isAdmin = false,
  });

  factory UserPublicInfo.fromMap(Map<String, dynamic> map) {
    return UserPublicInfo(
      userId: map['user_id'],
      firebaseUid: map['firebase_uid'],
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phone_number'],
      country: map['country'] as String?,
      state: map['state'] as String?,
      isAdmin: map['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'firebase_uid': firebaseUid,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'country': country,
      'state': state,
      'is_admin': isAdmin,
    };
  }
}
