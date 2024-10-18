// lib/features/trips/screens/add_edit_activity_screen.dart
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/shared/utils/file_utils.dart';
import 'package:vayu_flutter_app/shared/utils/time_utils.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/location_input_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class AddEditActivityScreen extends StatefulWidget {
  final ActivityModel? activity;
  final int tripId;

  const AddEditActivityScreen({
    super.key,
    this.activity,
    required this.tripId,
  });

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
  String? _placeId;
  String? _attachmentUrl;
  String? _attachmentName;
  String? _attachmentPath;
  LocationData? _location;
  bool _isUploading = false;

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
        TextEditingController(text: widget.activity?.location?.name ?? '');
    _placeId = widget.activity?.placeId;
    _attachmentUrl = widget.activity?.attachmentUrl;
    _attachmentName = widget.activity?.attachmentName;
    _attachmentPath = widget.activity?.attachmentPath;
    _location = widget.activity?.location;
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

  Future<void> _selectTime(TextEditingController controller) async {
    final time = await TimeUtils.selectTime(context);
    if (time != null) {
      setState(() {
        controller.text = time;
      });
    }
  }

  Future<void> _pickFile() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });
    final result =
        await FileUtils.pickAndUploadFile(context, widget.tripId, 'activities');
    setState(() {
      _attachmentUrl = result['attachmentUrl'];
      _attachmentName = result['attachmentName'];
      _attachmentPath = result['attachmentPath'];
      _isUploading = false;
    });
  }

  void _saveActivity() {
    if (_isUploading) {
      SnackbarUtil.showSnackbar('Please wait for the file upload to complete',
          type: SnackbarType.warning);
      return;
    }
    if (_formKey.currentState!.validate()) {
      final activity = ActivityModel(
        activityId: widget.activity?.activityId,
        name: _nameController.text,
        description: _descriptionController.text,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        location: _location,
        placeId: _placeId,
        attachmentUrl: _attachmentUrl,
        attachmentName: _attachmentName,
        attachmentPath: _attachmentPath,
      );
      Navigator.of(context).pop(activity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SnackbarUtil.showSnackbar(
            'Please wait for the file upload to complete',
            type: SnackbarType.warning,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(widget.activity == null ? 'Add Activity' : 'Edit Activity'),
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
                        onTap: () => _selectTime(_startTimeController),
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
                        onTap: () => _selectTime(_endTimeController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LocationInputField(
                  label: 'Location',
                  initialLocation: widget.activity?.location,
                  onLocationSelected: (location) {
                    setState(() {
                      _location = location;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_attachmentName ?? 'Add Attachment'),
                ),
                if (_attachmentName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Attached: $_attachmentName'),
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
      ),
    );
  }
}
