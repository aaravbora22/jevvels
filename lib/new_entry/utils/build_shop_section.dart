import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef ShopChanged = void Function(String shopName);

class BuildShopSection extends StatelessWidget {
  final ShopChanged? onShopChanged;
  final TextEditingController controller;

  const BuildShopSection({
    super.key,
    this.onShopChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return BuildTextField(
      label: 'Shop Name',
      controller: controller,
      textStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Main Font',
        fontWeight: FontWeight.bold,
      ),
      hint: 'Select or enter shop name',
      onChanged: (val) {
        onShopChanged?.call(val);
      },
      onTap: () {
        // TODO: integrate Google Places autocomplete picker
      },
    );
  }
}
