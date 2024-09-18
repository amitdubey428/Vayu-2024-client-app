import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/day_plan_model.dart';
import 'package:vayu_flutter_app/shared/utils/location_utils.dart';

class LocationInputField extends StatefulWidget {
  final String label;
  final LocationData? initialLocation;
  final Function(LocationData) onLocationSelected;

  const LocationInputField({
    super.key,
    required this.label,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationInputField> createState() => _LocationInputFieldState();
}

class _LocationInputFieldState extends State<LocationInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialLocation?.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openLocationSearch(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: const Icon(Icons.location_on),
          ),
        ),
      ),
    );
  }

  void _openLocationSearch(BuildContext context) async {
    final LocationData? result = await LocationUtils.searchLocation(
      context,
      initialQuery: _controller.text,
      initialLocation: widget.initialLocation,
    );

    if (result != null) {
      setState(() {
        _controller.text = result.name;
      });
      widget.onLocationSelected(result);
    }
  }
}
