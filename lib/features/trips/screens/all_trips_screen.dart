import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/features/trips/widgets/trip_card.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class AllTripsScreen extends StatefulWidget {
  final bool isInDashboard;
  final ScrollController? parentScrollController;

  const AllTripsScreen({
    super.key,
    this.isInDashboard = false,
    this.parentScrollController,
  });

  @override
  State<AllTripsScreen> createState() => AllTripsScreenState();
}

class AllTripsScreenState extends State<AllTripsScreen> {
  late Future<List<TripModel>> _tripsFuture;
  bool _showArchived = false;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = getIt<AuthNotifier>().currentUser!.uid;
    _tripsFuture = _loadTrips();
  }

  Future<List<TripModel>> _loadTrips() async {
    try {
      return await getIt<TripService>().getUserTrips();
    } catch (e) {
      SnackbarUtil.showSnackbar(
        'Failed to load trips, please check your internet connection',
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
      appBar: widget.isInDashboard
          ? null
          : AppBar(
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
              return _buildScrollableWidget(_buildErrorWidget());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildScrollableWidget(_buildEmptyWidget());
            }

            final trips = snapshot.data!
                .where((trip) =>
                    _showArchived ? trip.isArchived : !trip.isArchived)
                .toList();

            if (trips.isEmpty) {
              return _buildScrollableWidget(_buildEmptyWidget());
            }

            return ListView.builder(
              controller:
                  widget.isInDashboard ? widget.parentScrollController : null,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return TripCard(trip: trip);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showArchived = !_showArchived;
          });
        },
        child: Icon(_showArchived ? Icons.archive : Icons.unarchive),
      ),
    );
  }

  Widget _buildScrollableWidget(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Center(child: child),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Some error occurred. Please check your internet connection',
          textAlign: TextAlign.center,
        ),
        ElevatedButton(
          onPressed: refreshTrips,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Text(_showArchived ? 'No archived trips' : 'No active trips');
  }
}
