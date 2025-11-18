import 'package:flutter/material.dart';
import 'package:jevvels/new_entry/utils/input_decoration.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef CategoryChanged = void Function(
  String category,
  String? customCategory,
);

class BuildCategorySection extends StatelessWidget {
  final CategoryChanged? onCategoryChanged;
  final String selectedCategory;
  final TextEditingController customCategoryController;

  const BuildCategorySection({
    super.key,
    this.onCategoryChanged,
    required this.selectedCategory,
    required this.customCategoryController,
  });

  void _notifyCategoryChanged(String newCategory, String? custom) {
    if (onCategoryChanged != null) {
      onCategoryChanged!(newCategory, custom);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          items: const ['Necklace', 'Ring', 'Bracelet', 'Earring', 'Other']
              .map(
                (cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                ),
              )
              .toList(),
          dropdownColor: const Color(0xFF2C2B2B),
          iconEnabledColor: const Color(0xFFB99750),
          decoration: customInputDecoration(),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Main Font',
            fontWeight: FontWeight.bold,
          ),
          onChanged: (value) {
            if (value == null) return;

            // if user switches away from "Other", wipe custom text
            if (value != 'Other') {
              customCategoryController.text = '';
              _notifyCategoryChanged(value, null);
            } else {
              // going to Other -> use whatever is in the text field (may be empty)
              _notifyCategoryChanged(value, customCategoryController.text);
            }
          },
        ),
        if (isOther)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: BuildTextField(
              label: 'Custom Category',
              controller: customCategoryController,
              onChanged: (val) {
                // selectedCategory is "Other" here
                _notifyCategoryChanged(selectedCategory, val);
              },
            ),
          ),
      ],
    );
  }
}
