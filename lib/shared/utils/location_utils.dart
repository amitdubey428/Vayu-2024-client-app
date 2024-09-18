// lib/shared/utils/location_utils.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/features/trips/screens/location_search_dialog.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class LocationUtils {
  static Future<LocationData?> searchLocation(
    BuildContext context, {
    required String initialQuery,
    LocationData? initialLocation,
  }) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationSearchDialog(
          initialQuery: initialQuery,
          initialLocation: initialLocation != null
              ? LatLng(initialLocation.latitude, initialLocation.longitude)
              : null,
        );
      },
    );

    if (result != null) {
      return LocationData(
        placeId: result['place_id'],
        latitude: result['latitude'],
        longitude: result['longitude'],
        formattedAddress: result['formatted_address'],
        name: result['name'],
      );
    }

    return null;
  }

  static Future<void> openInMaps(LocationData location) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      SnackbarUtil.showSnackbar('Could not open maps application',
          type: SnackbarType.error);
    }
  }
}
