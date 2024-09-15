// lib/screens/trips/create_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/date_picker_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _tripNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTrip() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
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
          Navigator.of(context).pushReplacementNamed(
            Routes.tripDetails,
            arguments: {
              'tripId': createdTrip.tripId,
              'tripName': createdTrip.tripName,
            },
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtil.showSnackbar(
            'Failed to create trip. Please try again.',
            type: SnackbarType.error,
          );
          developer.log('Error creating trip: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          title: const Text('Create New Trip'),
          elevation: 0,
        ),
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
                  prefixIcon: const Icon(Icons.trip_origin),
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
                  prefixIcon: const Icon(Icons.description),
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
                      if (_endDate != null && _endDate!.isBefore(date)) {
                        _endDate = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                DatePickerFormField(
                  labelText: 'End Date',
                  selectedDate: _endDate,
                  firstDate: _startDate ?? DateTime.now(),
                  onDateSelected: (date) {
                    setState(() {
                      _endDate = date;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note: You can add day plans and activities after creating the trip.',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTrip,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isLoading ? 'Creating Trip...' : 'Create Trip',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_isLoading)
        const Positioned.fill(
          child: CustomLoadingIndicator(message: 'Creating trip...'),
        ),
    ]);
  }
}
