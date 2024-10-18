// lib/features/trips/widgets/day_plan_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';

class DayPlanCard extends StatelessWidget {
  final DayPlanModel dayPlan;
  final int dayNumber;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final bool isAdmin;

  const DayPlanCard({
    super.key,
    required this.dayPlan,
    required this.dayNumber,
    required this.onTap,
    this.onEdit,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Day\n$dayNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(dayPlan.date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (dayPlan.area != null && dayPlan.area!.isNotEmpty)
                          Text(dayPlan.area!),
                      ],
                    ),
                  ),
                  if (isAdmin && onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (dayPlan.stays.isNotEmpty) ...[
                const Text(
                  'Stays:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...dayPlan.stays
                    .map((stay) => _buildItemRow(Icons.hotel, stay.name)),
              ],
              if (dayPlan.activities.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Activities:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildItemRow(Icons.event,
                    '${dayPlan.activities.length} activities planned'),
              ],
              if (dayPlan.notes != null && dayPlan.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  dayPlan.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
