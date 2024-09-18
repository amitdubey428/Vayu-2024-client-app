// lib/features/trips/screens/add_edit_stay_screen.dart

import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/shared/utils/file_utils.dart';
import 'package:vayu_flutter_app/shared/utils/time_utils.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/location_input_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class AddEditStayScreen extends StatefulWidget {
  final StayModel? stay;
  final DateTime date;
  final int tripId;

  const AddEditStayScreen(
      {super.key, this.stay, required this.date, required this.tripId});

  @override
  State<AddEditStayScreen> createState() => _AddEditStayScreenState();
}

class _AddEditStayScreenState extends State<AddEditStayScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _checkInController;
  late TextEditingController _checkOutController;
  late TextEditingController _notesController;
  String? _placeId;
  String? _attachmentUrl;
  String? _attachmentName;
  String? _attachmentPath;
  LocationData? _location;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.stay?.name ?? '');
    _addressController =
        TextEditingController(text: widget.stay?.address?.name ?? '');
    _checkInController =
        TextEditingController(text: widget.stay?.checkIn ?? '');
    _checkOutController =
        TextEditingController(text: widget.stay?.checkOut ?? '');
    _notesController = TextEditingController(text: widget.stay?.notes ?? '');
    _placeId = widget.stay?.placeId;
    _attachmentUrl = widget.stay?.attachmentUrl;
    _attachmentName = widget.stay?.attachmentName;
    _attachmentPath = widget.stay?.attachmentPath;
    _location = widget.stay?.address;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _notesController.dispose();
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
        await FileUtils.pickAndUploadFile(context, widget.tripId, 'stays');
    setState(() {
      _attachmentUrl = result['attachmentUrl'];
      _attachmentName = result['attachmentName'];
      _attachmentPath = result['attachmentPath'];
      _isUploading = false;
    });
  }

  void _saveStay() {
    if (_isUploading) {
      SnackbarUtil.showSnackbar('Please wait for the file upload to complete',
          type: SnackbarType.warning);
      return;
    }
    if (_formKey.currentState!.validate()) {
      final stay = StayModel(
        stayId: widget.stay?.stayId,
        name: _nameController.text,
        address: _location,
        checkIn: _checkInController.text,
        checkOut: _checkOutController.text,
        notes: _notesController.text,
        placeId: _placeId,
        attachmentUrl: _attachmentUrl,
        attachmentName: _attachmentName,
        attachmentPath: _attachmentPath,
      );
      Navigator.of(context).pop(stay);
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
          title: Text(
            '${widget.stay == null ? 'Add' : 'Edit'} Stay - ${widget.date.toString().split(' ')[0]}',
          ),
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
                  controller: _nameController,
                  labelText: 'Stay Name',
                  hintText: 'Enter stay name',
                  prefixIcon: const Icon(Icons.hotel),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a stay name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                LocationInputField(
                  label: 'Location',
                  initialLocation: widget.stay?.address,
                  onLocationSelected: (location) {
                    setState(() {
                      _location = location;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _checkInController,
                        labelText: 'Check-in Time',
                        hintText: 'Select check-in time',
                        prefixIcon: const Icon(Icons.login),
                        readOnly: true,
                        onTap: () => _selectTime(_checkInController),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _checkOutController,
                        labelText: 'Check-out Time',
                        hintText: 'Select check-out time',
                        prefixIcon: const Icon(Icons.logout),
                        readOnly: true,
                        onTap: () => _selectTime(_checkOutController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _notesController,
                  labelText: 'Notes',
                  hintText: 'Enter any additional notes',
                  prefixIcon: const Icon(Icons.note),
                  maxLines: 3,
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
                    onPressed: _saveStay,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.stay == null ? 'Add Stay' : 'Update Stay',
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
