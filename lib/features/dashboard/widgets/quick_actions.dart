import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/shared/widgets/qr_code_scanner.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onDashboardRefreshNeeded;

  const QuickActions({
    super.key,
    required this.onDashboardRefreshNeeded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                'Create Trip',
                Icons.add,
                Theme.of(context).colorScheme.primary,
                () async {
                  final result =
                      await Navigator.of(context).pushNamed(Routes.createTrip);
                  if (result != null && result is TripModel) {
                    onDashboardRefreshNeeded();
                  }
                },
              ),
              _buildActionButton(
                context,
                'Join Trip',
                Icons.group_add,
                Theme.of(context).colorScheme.secondary,
                () => _showJoinTripDialog(context),
              ),
              _buildActionButton(
                context,
                'Expenses',
                Icons.attach_money,
                Theme.of(context).colorScheme.tertiary,
                () {
                  // TODO: Navigate to expenses
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onPressed) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: color,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

void _showJoinTripDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController controller = TextEditingController();
      return AlertDialog(
        title: const Text('Join a Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                  hintText: "Enter invitation code or link"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showQRScanner(context),
              child: const Text('Scan QR Code'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Join'),
            onPressed: () {
              Navigator.of(context).pop();
              _joinTrip(context, controller.text);
            },
          ),
        ],
      );
    },
  );
}

void _showQRScanner(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Scan Invite QR Code')),
        body: QRCodeScanner(
          onScan: (String data) {
            Navigator.of(context).pop();
            _joinTrip(context, data);
          },
        ),
      ),
    ),
  );
}

void _joinTrip(BuildContext context, String invitationCode) {
  // Extract the invitation code if a full URL was pasted
  final Uri? uri = Uri.tryParse(invitationCode);
  if (uri != null && uri.path.startsWith('/join-trip/')) {
    invitationCode = uri.pathSegments.last;
  }

  Navigator.of(context).pushNamed(
    Routes.joinTrip,
    arguments: {'invitationCode': invitationCode},
  );
}
