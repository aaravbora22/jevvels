import 'package:flutter/material.dart';

class BuildTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final int maxLines;
  final String? hint;
  final VoidCallback? onTap;
  final TextStyle? textStyle;

  const BuildTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.maxLines = 1,
    this.hint,
    this.onTap,
    this.textStyle,
  });

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF2C2B2B),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB99750)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB99750), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Main Font',
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onTap: onTap,
          style: (textStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Main Font',
                    fontSize: 16, // Default if not passed
                  ))
              .copyWith(color: Colors.white),
          decoration: _inputDecoration(hint: hint),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
        )
      ],
    );
  }
}
