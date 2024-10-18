import 'package:flutter/material.dart';

class CountryCode {
  final String name;
  final String dialCode;
  final String code;

  CountryCode({required this.name, required this.dialCode, required this.code});
}

final List<CountryCode> countryCodes = [
  // CountryCode(name: "United States", dialCode: "+1", code: "US"),
  CountryCode(name: "India", dialCode: "+91", code: "IN"),
  // CountryCode(name: "United Kingdom", dialCode: "+44", code: "GB"),
  // Add more countries as needed
];

class CountryCodePicker extends StatelessWidget {
  final ValueChanged<CountryCode> onChanged;
  final CountryCode initialSelection;

  const CountryCodePicker({
    super.key,
    required this.onChanged,
    required this.initialSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Match the height of CustomTextFormField
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
            color: Theme.of(context)
                    .inputDecorationTheme
                    .border
                    ?.borderSide
                    .color ??
                Colors.grey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Center(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<CountryCode>(
            value: initialSelection,
            items: countryCodes.map((CountryCode countryCode) {
              return DropdownMenuItem<CountryCode>(
                value: countryCode,
                child: Text(
                  "${countryCode.dialCode} ${countryCode.code}",
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: (CountryCode? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
            dropdownColor: Colors.grey[200],
          ),
        ),
      ),
    );
  }
}
