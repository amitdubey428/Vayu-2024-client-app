import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/data/models/user_public_info.dart';
import 'package:vayu_flutter_app/features/trips/screens/edit_trip_screen.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/shared/widgets/qr_code_generator.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  const TripDetailScreen(
      {super.key, required this.tripId, required this.tripName});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  TripModel? _tripData;
  bool _isLoading = true;
  String? _error;

  Future<void> _generateAndShareInviteLink() async {
    if (_tripData == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const CustomLoadingIndicator(
            message: "Generating invite link...");
      },
    );

    try {
      final inviteLink =
          await getIt<TripService>().generateInviteLink(_tripData!.tripId!);
      if (mounted) {
        Navigator.of(context).pop();
        _showInvitationDialog(inviteLink);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss the loading indicator
        SnackbarUtil.showSnackbar(
          'Failed to generate invite link: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  void _showInvitationDialog(String inviteLink) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Invite to "${_tripData!.tripName}"',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QRCodeGenerator(data: inviteLink),
                            const SizedBox(height: 20),
                            SelectableText(inviteLink),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        child: const Text('Copy Link'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteLink));
                          Navigator.of(context).pop();
                          SnackbarUtil.showSnackbar('Link copied to clipboard',
                              type: SnackbarType.success);
                        },
                      ),
                      TextButton(
                        child: const Text('Share'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Share.share(
                            'Join my trip "${_tripData!.tripName}" on Vayu!\n\n$inviteLink',
                            subject: 'Invitation to join a trip on Vayu',
                          );
                        },
                      ),
                      TextButton(
                        child: const Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    try {
      final trip = await getIt<TripService>().getTripDetails(widget.tripId);
      setState(() {
        _tripData = trip;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load trip details: $e";
        _isLoading = false;
      });
      if (mounted) {
        SnackbarUtil.showSnackbar(_error!, type: SnackbarType.error);
      }
    }
  }

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
        actions: [
          if (_tripData != null && _isCurrentUserAdmin())
            PopupMenuButton<String>(
              onSelected: _handleMenuSelection,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit Trip'),
                ),
                PopupMenuItem<String>(
                  value: 'archive',
                  child: Text(_tripData!.isArchived
                      ? 'Unarchive Trip'
                      : 'Archive Trip'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete Trip'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator(message: 'Loading...'))
          : _error != null
              ? Center(child: Text(_error!))
              : _tripData == null
                  ? const Center(child: Text('No trip data available'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_tripData!.isArchived)
                            Container(
                              color: Colors.grey[300],
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Text(
                                'Archived Trip',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          _buildDateHeader(_tripData!),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Description'),
                                Text(_tripData!.description),
                                const SizedBox(height: 24),
                                _buildSectionTitle('Participants'),
                                _buildParticipantsList(_tripData!.participants),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: _tripData == null || _tripData!.isArchived
          ? null
          : FloatingActionButton(
              onPressed: _generateAndShareInviteLink,
              child: const Icon(Icons.person_add),
            ),
    );
  }

  bool _isCurrentUserAdmin() {
    final currentUserId = getIt<AuthNotifier>().currentUser!.uid;
    return _tripData!.participants.any((participant) =>
        participant.firebaseUid == currentUserId && participant.isAdmin);
  }

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'edit':
        final updatedTrip = await Navigator.push<TripModel>(
          context,
          MaterialPageRoute(
            builder: (context) => EditTripScreen(trip: _tripData!),
          ),
        );
        if (updatedTrip != null) {
          _loadTripData(); // Refresh the trip data
        }
        break;
      case 'archive':
        await _toggleArchiveTrip();
        break;
      case 'delete':
        _showDeleteConfirmationDialog();
        break;
    }
  }

  Future<void> _toggleArchiveTrip() async {
    try {
      await getIt<TripService>()
          .toggleArchiveTrip(widget.tripId, !_tripData!.isArchived);
      SnackbarUtil.showSnackbar(
        'Trip ${_tripData!.isArchived ? 'unarchived' : 'archived'} successfully',
        type: SnackbarType.success,
      );
      _loadTripData(); // Refresh the trip data
    } catch (e) {
      SnackbarUtil.showSnackbar(
        'Failed to ${_tripData!.isArchived ? 'unarchive' : 'archive'} trip: ${e.toString()}',
        type: SnackbarType.error,
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: const Text(
              'Are you sure you want to delete this trip? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTrip();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTrip() async {
    try {
      await getIt<TripService>().deleteTrip(widget.tripId);
      if (mounted) {
        Navigator.of(context).pop(); // Return to previous screen
        SnackbarUtil.showSnackbar(
          'Trip deleted successfully',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtil.showSnackbar(
          'Failed to delete trip: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  Widget _buildDateHeader(TripModel trip) {
    return Container(
      color: trip.isArchived
          ? Colors.grey[400]
          : Theme.of(context).colorScheme.primary,
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
    final currentUserId = getIt<AuthNotifier>().currentUser!.uid;

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
          title: Row(
            children: [
              Text('${participant.firstName} ${participant.lastName}'),
              if (participant.isAdmin)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (participant.firebaseUid == currentUserId)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Me',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
