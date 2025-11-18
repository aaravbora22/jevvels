import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef NotesChanged = void Function(String notes);

class BuildNotesSection extends StatelessWidget {
  final NotesChanged? onNotesChanged;
  final TextEditingController controller;

  const BuildNotesSection({
    super.key,
    this.onNotesChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return BuildTextField(
      label: 'Notes',
      controller: controller,
      hint: 'Type anything you want us to remember about this entry',
      maxLines: 3,
      onChanged: (val) {
        if (onNotesChanged != null) {
          onNotesChanged!(val);
        }
      },
    );
  }
}
