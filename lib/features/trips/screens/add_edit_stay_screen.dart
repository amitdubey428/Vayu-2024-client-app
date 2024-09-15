// lib/features/trips/screens/add_edit_stay_screen.dart
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:intl/intl.dart';

class AddEditStayScreen extends StatefulWidget {
  final StayModel? stay;
  final DateTime date;

  const AddEditStayScreen({super.key, this.stay, required this.date});

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.stay?.name ?? '');
    _addressController =
        TextEditingController(text: widget.stay?.address ?? '');
    _checkInController =
        TextEditingController(text: widget.stay?.checkIn ?? '');
    _checkOutController =
        TextEditingController(text: widget.stay?.checkOut ?? '');
    _notesController = TextEditingController(text: widget.stay?.notes ?? '');
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

  void _saveStay() {
    if (_formKey.currentState!.validate()) {
      final stay = StayModel(
        stayId: widget.stay?.stayId,
        name: _nameController.text,
        address: _addressController.text,
        checkIn: _checkInController.text,
        checkOut: _checkOutController.text,
        notes: _notesController.text,
      );
      Navigator.of(context).pop(stay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              CustomTextFormField(
                controller: _addressController,
                labelText: 'Address',
                hintText: 'Enter stay address',
                prefixIcon: const Icon(Icons.location_on),
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
                      onTap: () => _selectTime(context, _checkInController),
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
                      onTap: () => _selectTime(context, _checkOutController),
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
    );
  }
}
