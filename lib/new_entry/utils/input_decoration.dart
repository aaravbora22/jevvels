import 'package:flutter/material.dart';

InputDecoration customInputDecoration({String? hint}) {
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
