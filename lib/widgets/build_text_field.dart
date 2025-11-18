import 'package:flutter/material.dart';

class BuildTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final int maxLines;
  final String? hint;
  final VoidCallback? onTap;
  final TextStyle? textStyle;

  final bool isPassword;

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
    this.isPassword = false,
  });

  @override
  State<BuildTextField> createState() => _BuildTextFieldState();
}

class _BuildTextFieldState extends State<BuildTextField> {
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    // obscure only if password field
    obscure = widget.isPassword;
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: widget.hint,
      hintStyle: const TextStyle(color: Colors.white),
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

      // 🔥 Password toggle button
      suffixIcon: widget.isPassword
          ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFFB99750),
              ),
              onPressed: () {
                setState(() => obscure = !obscure);
              },
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Main Font',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          obscureText: widget.isPassword ? obscure : false,
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          onChanged: widget.onChanged,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          keyboardType: widget.keyboardType,
          onTap: widget.onTap,
          style: (widget.textStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Main Font',
                    fontSize: 16,
                  ))
              .copyWith(color: Colors.white),
          decoration: _inputDecoration(),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
