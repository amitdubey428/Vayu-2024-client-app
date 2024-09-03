// In edit_trip_screen.dart

import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/shared/widgets/date_picker_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class EditTripScreen extends StatefulWidget {
  final TripModel trip;

  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tripNameController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(text: widget.trip.tripName);
    _descriptionController =
        TextEditingController(text: widget.trip.description);
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _tripNameController,
                decoration: const InputDecoration(labelText: 'Trip Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a trip name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DatePickerFormField(
                labelText: 'Start Date',
                selectedDate: _startDate,
                onDateSelected: (date) {
                  setState(() {
                    _startDate = date;
                  });
                },
              ),
              const SizedBox(height: 16),
              DatePickerFormField(
                labelText: 'End Date',
                selectedDate: _endDate,
                firstDate: _startDate,
                onDateSelected: (date) {
                  setState(() {
                    _endDate = date;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateTrip,
                child: const Text('Update Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateTrip() async {
    if (_formKey.currentState!.validate()) {
      final updatedTrip = widget.trip.copyWith(
        tripName: _tripNameController.text,
        description: _descriptionController.text,
        startDate: _startDate,
        endDate: _endDate,
      );

      try {
        final TripService tripService = getIt<TripService>();
        await tripService.updateTrip(updatedTrip);
        if (mounted) {
          Navigator.of(context).pop(updatedTrip);
          SnackbarUtil.showSnackbar("Trip updated successfully",
              type: SnackbarType.success);
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtil.showSnackbar("Failed to update trip, try again later",
              type: SnackbarType.error);
        }
      }
    }
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
