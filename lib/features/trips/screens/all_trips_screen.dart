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
    Widget content = FutureBuilder<List<TripModel>>(
      future: _tripsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CustomLoadingIndicator(message: 'Loading'));
        } else if (snapshot.hasError) {
          return const Center(
              child: Text(
                  'Some error occurred. Please check your internet connection'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No trips found'));
        }

        final trips = snapshot.data!
            .where((trip) => _showArchived ? trip.isArchived : !trip.isArchived)
            .toList();
        if (trips.isEmpty) {
          return Center(
            child:
                Text(_showArchived ? 'No archived trips' : 'No active trips'),
          );
        }
        return ListView.builder(
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return TripCard(trip: trip);
          },
        );
      },
    );

    Widget body = RefreshIndicator(
      onRefresh: refreshTrips,
      child: widget.isInDashboard
          ? SingleChildScrollView(
              controller: widget.parentScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: content,
              ),
            )
          : content,
    );

    return Scaffold(
      appBar: widget.isInDashboard
          ? null
          : AppBar(
              title: const Text('All Trips'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
      body: body,
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
}
