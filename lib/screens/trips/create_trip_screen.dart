// lib/screens/trips/create_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/di/service_locator.dart';
import 'package:vayu_flutter_app/models/trip_model.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/widgets/date_picker_form_field.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';
import 'dart:developer' as developer;

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _tripNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTrip() async {
    if (_formKey.currentState!.validate()) {
      var tripService = getIt<TripService>();
      final newTrip = TripModel(
        tripName: _tripNameController.text,
        description: _descriptionController.text,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      try {
        final createdTrip = await tripService.createTrip(newTrip);
        if (mounted) {
          SnackbarUtil.showSnackbar(
            'Trip "${createdTrip.tripName}" created successfully!',
            type: SnackbarType.success,
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtil.showSnackbar(
            'Failed to create trip. Please try again.',
            type: SnackbarType.error,
          );
          developer.log('Error creating trip: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextFormField(
                controller: _tripNameController,
                labelText: 'Trip Name',
                hintText: 'Enter trip name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a trip name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Enter trip description',
                maxLines: 3,
                minLines: 2,
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
                onDateSelected: (date) {
                  setState(() {
                    _endDate = date;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createTrip,
                child: const Text('Create Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
