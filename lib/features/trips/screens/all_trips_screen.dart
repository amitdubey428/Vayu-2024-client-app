// lib/screens/trips/all_trips_screen.dart

import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/features/trips/widgets/trip_card.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class AllTripsScreen extends StatefulWidget {
  const AllTripsScreen({super.key});

  @override
  State<AllTripsScreen> createState() => AllTripsScreenState();
}

class AllTripsScreenState extends State<AllTripsScreen> {
  late Future<List<TripModel>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _loadTrips();
  }

  Future<List<TripModel>> _loadTrips() async {
    try {
      return await getIt<TripService>().getUserTrips();
    } catch (e) {
      SnackbarUtil.showSnackbar(
        'Failed to load trips: ${e.toString()}',
        type: SnackbarType.error,
      );
      return [];
    }
  }

  Future<void> refreshTrips() async {
    setState(() {
      _tripsFuture = _loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Trips'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: RefreshIndicator(
        onRefresh: refreshTrips,
        child: FutureBuilder<List<TripModel>>(
          future: _tripsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CustomLoadingIndicator(message: 'Loading'));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No trips found'));
            }

            final trips = snapshot.data!;
            return ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                return TripCard(trip: trips[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
