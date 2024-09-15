// lib/features/trips/screens/add_edit_activity_screen.dart
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:intl/intl.dart';

class AddEditActivityScreen extends StatefulWidget {
  final ActivityModel? activity;

  const AddEditActivityScreen({super.key, this.activity});

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activity?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.activity?.description ?? '');
    _startTimeController =
        TextEditingController(text: widget.activity?.startTime ?? '');
    _endTimeController =
        TextEditingController(text: widget.activity?.endTime ?? '');
    _locationController =
        TextEditingController(text: widget.activity?.location ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        // Format the time as HH:MM
        final formattedTime = DateFormat('HH:mm')
            .format(DateTime(2023, 1, 1, picked.hour, picked.minute));
        controller.text = formattedTime;
      });
    }
  }

  void _saveActivity() {
    if (_formKey.currentState!.validate()) {
      final activity = ActivityModel(
        activityId: widget.activity?.activityId,
        name: _nameController.text,
        description: _descriptionController.text,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        location: _locationController.text,
      );
      Navigator.of(context).pop(activity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity == null ? 'Add Activity' : 'Edit Activity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextFormField(
                controller: _nameController,
                labelText: 'Activity Name',
                hintText: 'Enter activity name',
                prefixIcon: const Icon(Icons.event),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an activity name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Enter activity description',
                prefixIcon: const Icon(Icons.description),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: _startTimeController,
                      labelText: 'Start Time',
                      hintText: 'Select start time',
                      prefixIcon: const Icon(Icons.access_time),
                      readOnly: true,
                      onTap: () => _selectTime(context, _startTimeController),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextFormField(
                      controller: _endTimeController,
                      labelText: 'End Time',
                      hintText: 'Select end time',
                      prefixIcon: const Icon(Icons.access_time),
                      readOnly: true,
                      onTap: () => _selectTime(context, _endTimeController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _locationController,
                labelText: 'Location',
                hintText: 'Enter activity location',
                prefixIcon: const Icon(Icons.location_on),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveActivity,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.activity == null
                        ? 'Add Activity'
                        : 'Update Activity',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
