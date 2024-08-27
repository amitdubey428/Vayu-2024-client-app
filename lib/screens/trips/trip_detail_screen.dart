import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/di/service_locator.dart';
import 'package:vayu_flutter_app/models/trip_model.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/models/user_public_info.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  const TripDetailScreen(
      {super.key, required this.tripId, required this.tripName});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Future<TripModel> _tripFuture;

  @override
  void initState() {
    super.initState();
    _tripFuture = getIt<TripService>().getTripDetails(widget.tripId);
  }

  // Future<void> _addParticipant(TripModel trip) async {
  //   final result = await showDialog<String>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return const AddParticipantDialog();
  //     },
  //   );
  //   if (result != null) {
  //     try {
  //       var tripService = getIt<TripService>();
  //       final newParticipants =
  //           await tripService.addParticipant(trip.tripId!, result);
  //       setState(() {
  //         for (var participant in newParticipants) {
  //           if (participant['status'] == 'added') {
  //             UserModel user = participant['user'];
  //             trip.participants.add('${user.firstName} ${user.lastName}');
  //           }
  //         }
  //         _tripFuture = Future.value(trip);
  //       });
  //       if (mounted) {
  //         SnackbarUtil.showSnackbar('Participant added successfully',
  //             type: SnackbarType.success);
  //       }
  //     } catch (e) {
  //       if (mounted) {
  //         SnackbarUtil.showSnackbar("Failed to add participant: $e",
  //             type: SnackbarType.error);
  //       }
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tripName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<TripModel>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final trip = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(trip),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Description'),
                        Text(trip.description),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Participants'),
                        _buildParticipantsList(trip.participants),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No trip data available'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // _addParticipant(trip)
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildDateHeader(TripModel trip) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildDateCard(trip.startDate)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.arrow_forward, color: Colors.white, size: 30),
          ),
          Expanded(child: _buildDateCard(trip.endDate)),
        ],
      ),
    );
  }

  Widget _buildDateCard(DateTime date) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              DateFormat('MMM').format(date),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              DateFormat('dd').format(date),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              DateFormat('yyyy').format(date),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildParticipantsList(List<UserPublicInfo> participants) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(
              participant.firstName[0] + participant.lastName[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text('${participant.firstName} ${participant.lastName}'),
          subtitle: Text(participant.email),
          trailing: participant.phoneNumber != null
              ? IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {
                    // TODO: Implement call functionality
                  },
                )
              : null,
        );
      },
    );
  }
}
