class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final DateTime birthDate;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.birthDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'birthDate': birthDate.toIso8601String(),
    };
  }
}
