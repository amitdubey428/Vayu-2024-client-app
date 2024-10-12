import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'dart:developer' as developer;

Future<void> registerUserDevice() async {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final ApiService apiService = getIt<ApiService>();

  // Get the device token
  String? deviceToken = await firebaseMessaging.getToken();

  // Determine device type
  String deviceType;
  if (Platform.isIOS) {
    deviceType = 'ios';
  } else if (Platform.isAndroid) {
    deviceType = 'android';
  } else {
    deviceType = 'web';
  }

  // Get additional device info (optional)
  String? deviceModel;
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    deviceModel = androidInfo.model;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    deviceModel = iosInfo.utsname.machine;
  }

  // Prepare device data
  final deviceData = {
    'device_token': deviceToken ?? '',
    'device_type': deviceType,
    'device_model': deviceModel ?? '',
  };

  // Send to backend using ApiService
  try {
    await apiService.registerUserDevice(deviceData);
  } catch (e) {
    // Handle or rethrow the exception as needed
    developer.log('Failed to register device: $e');
  }
}
