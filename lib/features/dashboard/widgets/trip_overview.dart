import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/features/trips/screens/all_trips_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/create_trip_screen.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/utils/custom_exceptions.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';

class TripOverview extends StatefulWidget {
  const TripOverview({super.key});

  @override
  State<TripOverview> createState() => TripOverviewState();
}

class TripOverviewState extends State<TripOverview> {
  late Future<List<TripModel>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    refreshTrips();
  }

  Future<void> refreshTrips() async {
    setState(() {
      _tripsFuture = getIt<TripService>().getUserTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Upcoming Trips',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        FutureBuilder<List<TripModel>>(
          future: _tripsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CustomLoadingIndicator(message: 'Loading...'));
            } else if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error);
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyTripCard(context);
            }

            final allTrips = snapshot.data!;
            final activeTrips =
                allTrips.where((trip) => !trip.isArchived).toList();
            final archivedTrips =
                allTrips.where((trip) => trip.isArchived).toList();

            activeTrips.sort((a, b) => a.startDate.compareTo(b.startDate));
            archivedTrips.sort((a, b) => a.startDate.compareTo(b.startDate));
            final displayTrips = [...activeTrips, ...archivedTrips];

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: displayTrips.length > 3 ? 4 : displayTrips.length,
                itemBuilder: (context, index) {
                  if (index < 3 && index < displayTrips.length) {
                    final trip = displayTrips[index];
                    return _buildTripCard(context, trip);
                  } else {
                    return _buildViewAllCard(context, displayTrips.length - 3);
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorWidget(Object? error) {
    String errorMessage = "An unexpected error occurred. Please try again.";
    if (error is NoInternetException) {
      errorMessage =
          "No internet connection. Please check your network settings.";
    } else if (error is ApiException) {
      errorMessage =
          "No internet connection. Please check your network settings.";
    } else if (error is TimeoutException) {
      errorMessage = "Connection timed out. Please try again.";
    } else if (error
        .toString()
        .contains('Authentication token not available')) {
      errorMessage = "Authentication error. Please log in again.";
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16.0),
          ),
          ElevatedButton(
            onPressed: refreshTrips,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/tripDetails',
            arguments: {
              'tripId': trip.tripId,
              'tripName': trip.tripName,
            },
          );
        },
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      trip.tripName.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trip.isArchived)
                    Tooltip(
                      message: 'Archived Trip',
                      child: Icon(
                        Icons.archive,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd').format(trip.endDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text('${trip.participantCount} participants'),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.1),
                  ),
                  const Icon(Icons.arrow_forward),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllCard(BuildContext context, int remainingTrips) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AllTripsScreen(),
          ));
        },
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.more_horiz, size: 40),
              const SizedBox(height: 8),
              Text(
                'View All Trips',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (remainingTrips > 0)
                Text(
                  '+$remainingTrips more',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTripCard(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const CreateTripScreen(),
            ));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.beach_access,
                    size: 48, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(height: 16),
                Text(
                  "It's so lonely here!",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's plan an adventure!",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
