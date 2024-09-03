// lib/features/trips/widgets/trip_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;

  const TripCard({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: trip.isArchived ? Colors.grey[300] : null,
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
        child: Padding(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    '${DateFormat('MMM dd, yyyy').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                  if (trip.isArchived)
                    const Chip(
                      label: Text('Archived'),
                      backgroundColor: Colors.grey,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  Icon(Icons.arrow_forward,
                      color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
