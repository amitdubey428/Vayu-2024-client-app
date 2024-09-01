// Create a file named custom_exceptions.dart
class NoInternetException implements Exception {
  final String message;
  NoInternetException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
