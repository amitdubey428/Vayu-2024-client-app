import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/core/utils/custom_exceptions.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class JoinTripScreen extends StatefulWidget {
  final String invitationCode;

  const JoinTripScreen({super.key, required this.invitationCode});

  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _joinTrip();
  }

  Future<void> _joinTrip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tripService = getIt<TripService>();
      String invitationCode = widget.invitationCode;
      List<String> prefixes = ["http://", "https://", "vayuapp://"];
      bool startsWithValidPrefix =
          prefixes.any((prefix) => invitationCode.startsWith(prefix));

      if (startsWithValidPrefix) {
        final uri = Uri.parse(invitationCode);
        if (uri.pathSegments.length > 2 && uri.pathSegments[1] == "join-trip") {
          invitationCode = uri.pathSegments[2];
        }
      }
      final trip = await tripService.joinTripByInvitation(invitationCode);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          Routes.tripDetails,
          arguments: {'tripId': trip.tripId, 'tripName': trip.tripName},
        );
        SnackbarUtil.showSnackbar('Successfully joined the trip',
            type: SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        if (e is AuthException) {
          // Handle authentication error
          Navigator.of(context).pushReplacementNamed('/signInSignUpPage');
          SnackbarUtil.showSnackbar('Please sign in to join the trip',
              type: SnackbarType.warning);
        } else {
          SnackbarUtil.showSnackbar('Failed to join trip: $e',
              type: SnackbarType.error);
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Joining Trip')),
      body: Center(
        child: _isLoading
            ? const CustomLoadingIndicator(message: 'Joining trip...')
            : const Text('Processing your request...'),
      ),
    );
  }
}
