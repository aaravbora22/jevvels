import 'package:flutter/material.dart';
import 'package:jevvels/new_entry/utils/input_decoration.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef CategoryChanged = void Function(
    String category, String? customCategory);

class BuildCategorySection extends StatefulWidget {
  final CategoryChanged? onCategoryChanged;
  const BuildCategorySection({super.key, this.onCategoryChanged});

  @override
  State<BuildCategorySection> createState() => _BuildCategorySectionState();
}

class _BuildCategorySectionState extends State<BuildCategorySection> {
  String selectedCategory = 'Necklace';
  String? customCategory;
  late TextEditingController customCategoryController;

  @override
  void initState() {
    super.initState();
    customCategoryController = TextEditingController();
  }

  @override
  void dispose() {
    customCategoryController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    if (widget.onCategoryChanged != null) {
      widget.onCategoryChanged!(selectedCategory, customCategory);
    }
  }

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
          style: const TextStyle(color: Colors.white, fontFamily: 'Main Font', fontWeight: FontWeight.bold),
          onChanged: (value) {
            setState(() {
              selectedCategory = value!;
              if (value != 'Other') {
                customCategory = null;
                customCategoryController.text = '';
              }
              _notifyParent();
            });
          },
        ),
        if (isOther)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: BuildTextField(
              label: 'Custom Category',
              controller: customCategoryController,
              onChanged: (val) {
                customCategory = val;
                _notifyParent();
              },
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
