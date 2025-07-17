import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

class BuildShopSection extends StatefulWidget {
  const BuildShopSection({super.key});

  @override
  State<BuildShopSection> createState() => _BuildShopSectionState();
}

class _BuildShopSectionState extends State<BuildShopSection> {
  final shopNameController = TextEditingController();

  @override
  void dispose() {
    shopNameController.dispose();
    super.dispose();
  }

  Widget _buildShopSelector(BuildContext context) {
    return BuildTextField(
      label: 'Shop Name',
      controller: shopNameController,
      textStyle: TextStyle(),
      hint: 'Select or enter shop name',
      onTap: () {
        // Later: integrate Google Places autocomplete picker
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildShopSelector(context);
  }
}
