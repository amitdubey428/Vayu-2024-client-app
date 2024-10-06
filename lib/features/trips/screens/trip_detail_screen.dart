import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/data/models/user_public_info.dart';
import 'package:vayu_flutter_app/features/trips/screens/edit_trip_screen.dart';
import 'package:vayu_flutter_app/features/trips/widgets/animated_expansion_tile.dart';
import 'package:vayu_flutter_app/features/trips/widgets/day_plan_card.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/shared/utils/attachment_utils.dart';
import 'package:vayu_flutter_app/shared/utils/location_utils.dart';
import 'package:vayu_flutter_app/shared/widgets/qr_code_generator.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

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
      final invitationData =
          await getIt<TripService>().generateInviteLink(_tripData!.tripId!);
      if (mounted) {
        Navigator.of(context).pop();
        _showInvitationDialog(
          invitationData['invitation_link'],
          DateTime.parse(invitationData['expires_at']),
        );
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

  void _showInvitationDialog(String inviteLink, DateTime expiresAt) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Invite to "${_tripData!.tripName}"',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                QRCodeGenerator(data: inviteLink),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  child: SelectableText(
                    inviteLink,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Expires on: ${DateFormat('MMM dd, yyyy HH:mm').format(expiresAt.toLocal())}',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.copy,
                      label: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteLink));
                        Navigator.of(context).pop();
                        SnackbarUtil.showSnackbar('Link copied to clipboard',
                            type: SnackbarType.success);
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Share.share(
                          'Join my trip "${_tripData!.tripName}" on Vayu!\n\n$inviteLink',
                          subject: 'Invitation to join a trip on Vayu',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDayPlansList() {
    if (_tripData == null) return const SizedBox.shrink();

    List<Widget> dayCards = _generateDayCards();
    int visibleCards = 3;

    return Column(
      children: [
        ...dayCards.take(visibleCards),
        if (dayCards.length > visibleCards)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: () => _showAllDayPlans(dayCards),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('View all ${dayCards.length} days'),
            ),
          ),
      ],
    );
  }

  List<Widget> _generateDayCards() {
    int tripDuration =
        _tripData!.endDate.difference(_tripData!.startDate).inDays + 1;
    List<Widget> dayCards = [];

    for (int i = 0; i < tripDuration; i++) {
      DateTime currentDate = _tripData!.startDate.add(Duration(days: i));
      DayPlanModel existingPlan = _tripData!.dayPlans.firstWhere(
        (plan) => plan.date.isAtSameMomentAs(currentDate),
        orElse: () => DayPlanModel(
          dayPlanId: null,
          tripId: _tripData!.tripId!,
          date: currentDate,
          activities: [],
          stays: [],
        ),
      );

      dayCards.add(
        DayPlanCard(
          dayPlan: existingPlan,
          dayNumber: i + 1,
          onTap: () => _showDayPlanDetails(existingPlan),
          onEdit:
              _isCurrentUserAdmin() ? () => _editDayPlan(existingPlan) : null,
          isAdmin: _isCurrentUserAdmin(),
        ),
      );
    }

    return dayCards;
  }

  void _showAllDayPlans(List<Widget> dayCards) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'All Day Plans',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: dayCards.length,
                    itemBuilder: (context, index) => dayCards[index],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editDayPlan(DayPlanModel dayPlan) async {
    if (!_isCurrentUserAdmin()) {
      SnackbarUtil.showSnackbar('Only admins can edit day plans',
          type: SnackbarType.warning);
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      Routes.addEditDayPlan,
      arguments: {
        'tripId': widget.tripId,
        'dayPlan': dayPlan,
      },
    ) as DayPlanModel?;
    if (result != null) {
      await _refreshTripData();
    }
  }

  void _showDayPlanDetails(DayPlanModel dayPlan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM dd, yyyy').format(dayPlan.date),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (dayPlan.area != null && dayPlan.area!.isNotEmpty)
                      _buildDetailItem(
                          Icons.location_on, 'Area', dayPlan.area!),
                    if (dayPlan.notes != null && dayPlan.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailItem(Icons.note, 'Notes', dayPlan.notes!),
                    ],
                    if (dayPlan.stays.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Stays',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ...dayPlan.stays.map((stay) => _buildStayItem(stay)),
                    ],
                    if (dayPlan.activities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Activities',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ...dayPlan.activities
                          .map((activity) => _buildActivityItem(activity)),
                    ],
                    const SizedBox(height: 24),
                    if (_isCurrentUserAdmin())
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _editDayPlan(dayPlan);
                          },
                          child: const Text('Edit Day Plan'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStayItem(StayModel stay) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stay.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (stay.address != null)
              _buildLocationItem(stay.address!, 'Address'),
            _buildDetailItem(Icons.login, 'Check-in', stay.checkIn ?? 'N/A'),
            _buildDetailItem(Icons.logout, 'Check-out', stay.checkOut ?? 'N/A'),
            if (stay.notes != null && stay.notes!.isNotEmpty)
              _buildDetailItem(Icons.note, 'Notes', stay.notes!),
            if (stay.attachmentName != null)
              _buildAttachmentItem(stay.attachmentUrl!, stay.attachmentName!),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityModel activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (activity.startTime != null || activity.endTime != null)
              _buildDetailItem(Icons.access_time, 'Time',
                  '${activity.startTime ?? 'N/A'} - ${activity.endTime ?? 'N/A'}'),
            if (activity.location != null)
              _buildLocationItem(activity.location!, 'Location'),
            if (activity.description != null)
              _buildDetailItem(
                  Icons.description, 'Description', activity.description!),
            if (activity.attachmentName != null)
              _buildAttachmentItem(
                  activity.attachmentUrl!, activity.attachmentName!),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(LocationData location, String label) {
    return InkWell(
      onTap: () => LocationUtils.openInMaps(location),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(location.name),
                  Text(location.formattedAddress,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(String url, String name) {
    return ListTile(
      leading: const Icon(Icons.attachment),
      title: Text(name),
      onTap: () {
        AttachmentUtils.handleAttachment(context, url, name);
      },
    );
  }

  Future<void> _loadTripData() async {
    try {
      final trip = await getIt<TripService>().getTripDetails(widget.tripId);
      setState(() {
        _tripData = trip;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load trip details: $e";
          _isLoading = false;
        });
      }
      if (mounted) {
        SnackbarUtil.showSnackbar(_error!, type: SnackbarType.error);
      }
    }
  }

  Future<void> _refreshTripData() async {
    setState(() => _isLoading = true);
    await _loadTripData();
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
      body: RefreshIndicator(
        onRefresh: _refreshTripData,
        child: _isLoading
            ? const Center(child: CustomLoadingIndicator(message: 'Loading...'))
            : _error != null
                ? Center(child: Text(_error!))
                : _tripData == null
                    ? const Center(child: Text('No trip data available'))
                    : _buildTripContent(),
      ),
      floatingActionButton: _tripData == null || _tripData!.isArchived
          ? null
          : FloatingActionButton(
              onPressed: _generateAndShareInviteLink,
              child: const Icon(Icons.person_add),
            ),
    );
  }

  Widget _buildTripContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tripData!.isArchived)
            Container(
              color: Theme.of(context).colorScheme.surface,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                'Archived Trip',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
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
                AnimatedExpansionTile(
                  title: 'Description',
                  icon: Icons.description,
                  lightModeColor: Colors.blue[50]!,
                  darkModeColor: Colors.blue[900]!,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _tripData!.description,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedExpansionTile(
                  title: 'Participants',
                  icon: Icons.people,
                  lightModeColor: Colors.green[50]!,
                  darkModeColor: Colors.green[900]!,
                  children: [
                    _buildParticipantsList(_tripData!.participants),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedExpansionTile(
                  title: 'Day Plans',
                  icon: Icons.calendar_today,
                  lightModeColor: Colors.orange[50]!,
                  darkModeColor: Colors.orange[900]!,
                  children: [
                    _buildDayPlansList(),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedExpansionTile(
                  title: 'Expenses',
                  icon: Icons.attach_money,
                  lightModeColor: Colors.purple[50]!,
                  darkModeColor: Colors.purple[900]!,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            Routes.tripExpenseDashboard,
                            arguments: _tripData,
                          );
                        },
                        child: const Text('View Expenses Dashboard'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildDateCard(trip.startDate)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.arrow_forward,
                color: Theme.of(context).colorScheme.onPrimary, size: 30),
          ),
          Expanded(child: _buildDateCard(trip.endDate)),
        ],
      ),
    );
  }

  Widget _buildDateCard(DateTime date) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
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
            child: _getAvatarContent(participant),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  (participant.fullName?.isNotEmpty ?? false)
                      ? participant.fullName!
                      : participant
                          .phoneNumber, // Show phone number if name is empty
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              if (participant.isAdmin)
                _buildTag('Admin', Theme.of(context).colorScheme.primary),
              if (participant.firebaseUid == currentUserId)
                _buildTag('Me', Theme.of(context).colorScheme.secondary),
            ],
          ),
          subtitle: Text(
            participant.email ?? "",
            style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          trailing: IconButton(
            icon: Icon(Icons.phone,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () async {
              final Uri phoneUri =
                  Uri(scheme: 'tel', path: participant.phoneNumber);
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              } else {
                SnackbarUtil.showSnackbar("Could not launch phone call",
                    type: SnackbarType.error);
              }
            },
          ),
        );
      },
    );
  }

  Widget _getAvatarContent(UserPublicInfo participant) {
    if (participant.fullName != null && participant.fullName!.isNotEmpty) {
      final nameParts = participant.fullName!.split(' ');
      if (nameParts.length > 1) {
        return Text(
          '${nameParts.first[0]}${nameParts.last[0]}',
          style: const TextStyle(color: Colors.white),
        );
      } else {
        return Text(
          participant.fullName![0],
          style: const TextStyle(color: Colors.white),
        );
      }
    } else {
      return const Icon(Icons.person, color: Colors.white);
    }
  }

  Widget _buildTag(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
