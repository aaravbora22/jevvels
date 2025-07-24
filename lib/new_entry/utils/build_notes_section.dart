import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef NotesChanged = void Function(String notes);

class BuildNotesSection extends StatefulWidget {
  final NotesChanged? onNotesChanged;
  BuildNotesSection({super.key, this.onNotesChanged});

  @override
  State<BuildNotesSection> createState() => _BuildNotesSectionState();
}

class _BuildNotesSectionState extends State<BuildNotesSection> {
  final notesController = TextEditingController();

  Widget _buildNotesSection() {
    return BuildTextField(
      label: 'Notes',
      controller: notesController,
      hint: 'Type anything you want us to remember about this entry',
      maxLines: 3,
      onChanged: (val) {
        if (widget.onNotesChanged != null) {
          widget.onNotesChanged!(val);
        }
      },
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildNotesSection();
  }
}
