import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'dart:developer' as developer;

class AddEditDayPlanScreen extends StatefulWidget {
  final int tripId;
  final DayPlanModel? dayPlan;

  const AddEditDayPlanScreen({super.key, required this.tripId, this.dayPlan});

  @override
  State<AddEditDayPlanScreen> createState() => _AddEditDayPlanScreenState();
}

class _AddEditDayPlanScreenState extends State<AddEditDayPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _areaController;
  late TextEditingController _notesController;
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  List<StayModel> _stays = [];

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController(text: widget.dayPlan?.area ?? '');
    _notesController = TextEditingController(text: widget.dayPlan?.notes ?? '');
    _activities = widget.dayPlan?.activities ?? [];
    _stays = widget.dayPlan?.stays ?? [];
  }

  @override
  void dispose() {
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dayPlan == null
              ? 'Add Day Plan'
              : 'Edit Day Plan - ${DateFormat('MMM dd, yyyy').format(widget.dayPlan!.date)}',
        ),
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextFormField(
                  controller: _areaController,
                  labelText: 'Area',
                  hintText: 'Area/Locality of stay',
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _notesController,
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.note),
                  maxLines: 3,
                  hintText: 'Any additional notes',
                ),
                // _buildDayPlanAttachmentSection(),
                const SizedBox(height: 24),
                Text('Stays', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                ..._buildStayList(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addStay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Stay'),
                ),
                const SizedBox(height: 24),
                Text('Activities',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                ..._buildActivityList(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addActivity,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Activity'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveDayPlan,
                    child: Text(
                      widget.dayPlan == null
                          ? 'Create Day Plan'
                          : 'Update Day Plan',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: CustomLoadingIndicator(message: 'Saving day plan...'),
          ),
      ]),
    );
  }

  // Widget _buildDayPlanAttachmentSection() {
  //   return Container();
  //   // Implement day-level attachment functionality
  // }
  List<Widget> _buildStayList() {
    return _stays.map((stay) => _buildExpandableStayItem(stay)).toList();
  }

  Widget _buildExpandableStayItem(StayModel stay) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        leading: Icon(Icons.hotel, color: Theme.of(context).primaryColor),
        title: Text(stay.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${stay.checkIn ?? 'N/A'} - ${stay.checkOut ?? 'N/A'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stay.address != null)
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(stay.address!.name),
                  ),
                if (stay.notes != null)
                  ListTile(
                    leading: const Icon(Icons.note),
                    title: Text(stay.notes!),
                  ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () => _editStay(stay),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      onPressed: () => _removeStay(stay),
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

  void _addStay() async {
    final result = await Navigator.pushNamed(
      context,
      Routes.addEditStay,
      arguments: {
        'date': widget.dayPlan?.date ?? DateTime.now(),
        'tripId': widget.tripId
      },
    ) as StayModel?;
    if (result != null) {
      setState(() {
        _stays.add(result);
      });
    }
  }

  void _editStay(StayModel stay) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.addEditStay,
      arguments: {
        'stay': stay,
        'date': widget.dayPlan?.date ?? DateTime.now(),
        'tripId': widget.tripId
      },
    ) as StayModel?;
    if (result != null) {
      setState(() {
        final index = _stays.indexWhere((s) => s.stayId == stay.stayId);
        if (index != -1) {
          _stays[index] = result;
        }
      });
    }
  }

  void _removeStay(StayModel stay) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Stay'),
              content: Text('Are you sure you want to delete "${stay.name}"?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      setState(() {
        _stays.removeWhere((s) => s.stayId == stay.stayId);
      });
    }
  }

  List<Widget> _buildActivityList() {
    return _activities
        .map((activity) => _buildExpandableActivityItem(activity))
        .toList();
  }

  void _addActivity() async {
    final result = await Navigator.pushNamed(
      context,
      Routes.addEditActivity,
      arguments: {'tripId': widget.tripId},
    ) as ActivityModel?;
    if (result != null) {
      setState(() {
        _activities.add(result);
      });
    }
  }

  Widget _buildExpandableActivityItem(ActivityModel activity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        leading: Icon(Icons.event, color: Theme.of(context).primaryColor),
        title: Text(activity.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${activity.startTime ?? 'N/A'} - ${activity.endTime ?? 'N/A'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.location != null)
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(activity.location!.name),
                  ),
                if (activity.description != null)
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(activity.description!),
                  ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () => _editActivity(activity),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      onPressed: () => _removeActivity(activity),
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

  // Widget _buildActivityAttachmentSection(ActivityModel activity) {
  //   return Container();
  // }

  void _editActivity(ActivityModel activity) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.addEditActivity,
      arguments: {'activity': activity, 'tripId': widget.tripId},
    ) as ActivityModel?;
    if (result != null) {
      setState(() {
        final index =
            _activities.indexWhere((a) => a.activityId == activity.activityId);
        if (index != -1) {
          _activities[index] = result;
        }
      });
    }
  }

  void _removeActivity(ActivityModel activity) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Activity'),
              content:
                  Text('Are you sure you want to delete "${activity.name}"?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      setState(() {
        _activities.removeWhere((a) => a.activityId == activity.activityId);
      });
    }
  }

  void _saveDayPlan() async {
    setState(() => _isLoading = true);
    if (_formKey.currentState!.validate()) {
      final dayPlan = DayPlanModel(
        dayPlanId: widget.dayPlan?.dayPlanId,
        tripId: widget.tripId,
        date: widget.dayPlan?.date ?? DateTime.now(),
        area: _areaController.text,
        notes: _notesController.text,
        activities: _activities,
        stays: _stays,
      );

      try {
        final tripService = getIt<TripService>();
        final result =
            await tripService.updateOrCreateDayPlan(widget.tripId, dayPlan);

        developer
            .log('Day plan saved successfully: ${jsonEncode(result.toJson())}');

        if (mounted) {
          Navigator.of(context).pop(result);
          SnackbarUtil.showSnackbar(
            widget.dayPlan == null
                ? 'Day plan added successfully'
                : 'Day plan updated successfully',
            type: SnackbarType.success,
          );
        }
      } catch (e) {
        developer.log('Error saving day plan: $e');
        SnackbarUtil.showSnackbar(
          'Failed to save day plan',
          type: SnackbarType.error,
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
