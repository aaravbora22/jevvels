import 'package:flutter/material.dart';
import 'package:jevvels/new_entry/utils/input_decoration.dart';
import 'package:jevvels/widgets/build_text_field.dart';

class BuildCategorySection extends StatefulWidget {
  const BuildCategorySection({super.key});

  @override
  State<BuildCategorySection> createState() => _BuildCategorySectionState();
}

class _BuildCategorySectionState extends State<BuildCategorySection> {
  String selectedCategory = 'Necklace';
  String? customCategory;

  Widget _buildCategorySection() {
    final isOther = selectedCategory == 'Other';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Main Font',
              fontWeight: FontWeight.bold,
              fontSize: 24),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          items: ['Necklace', 'Ring', 'Bracelet', 'Earring', 'Other']
              .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  ))
              .toList(),
          dropdownColor: const Color(0xFF2C2B2B),
          iconEnabledColor: const Color(0xFFB99750),
          decoration: customInputDecoration(),
          style: const TextStyle(color: Colors.white, fontFamily: 'Main Font'),
          onChanged: (value) {
            setState(() {
              selectedCategory = value!;
              if (value != 'Other') customCategory = null;
            });
          },
        ),
        if (isOther)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: BuildTextField(
              label: 'Custom Category',
              controller: TextEditingController()
                ..text = customCategory ?? ''
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: (customCategory ?? '').length)),
              onChanged: (val) => customCategory = val,
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCategorySection();
  }
}
