import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef ShopChanged = void Function(String shopName);

class BuildShopSection extends StatefulWidget {
  final ShopChanged? onShopChanged;
  const BuildShopSection({super.key, this.onShopChanged});

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
      onChanged: (val) {
        if (widget.onShopChanged != null) {
          widget.onShopChanged!(val);
        }
      },
      onTap: () {
        // to do integrate Google Places autocomplete picker
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildShopSelector(context);
  }
}
