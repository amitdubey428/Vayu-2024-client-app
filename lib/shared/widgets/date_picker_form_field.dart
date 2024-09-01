import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerFormField extends StatelessWidget {
  final String labelText;
  final DateTime? selectedDate;
  final DateTime? firstDate;
  final Function(DateTime) onDateSelected;

  const DatePickerFormField({
    super.key,
    required this.labelText,
    required this.selectedDate,
    this.firstDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      controller: TextEditingController(
        text: selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
            : '',
      ),
      onTap: () async {
        final now = DateTime.now();
        final initialDate = selectedDate ??
            (firstDate != null && firstDate!.isAfter(now) ? firstDate! : now);
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate ?? now,
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      validator: (value) {
        if (selectedDate == null) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }
}
