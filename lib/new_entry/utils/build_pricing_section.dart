import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef PricingChanged = void Function(Map<String, dynamic> pricing);

class BuildPricingSection extends StatefulWidget {
  final PricingChanged? onPricingChanged;
  const BuildPricingSection({super.key, this.onPricingChanged});

  @override
  State<BuildPricingSection> createState() => _BuildPricingSectionState();
}

class _BuildPricingSectionState extends State<BuildPricingSection> {
  String _currency = 'INR';
  final List<String> _currencies = ['USD', 'INR', 'EUR'];
  final TextEditingController priceController = TextEditingController();
  final TextEditingController makingCostController = TextEditingController();
  final TextEditingController metalRateController = TextEditingController();

  void _notifyParent() {
    if (widget.onPricingChanged != null) {
      widget.onPricingChanged!({
        'currency': _currency,
        'totalPrice': priceController.text,
        'makingCost': makingCostController.text,
        'metalRate': metalRateController.text,
      });
    }
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing Details',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            DropdownButton<String>(
              value: _currency,
              dropdownColor: const Color(0xFF2C2B2B),
              iconEnabledColor: const Color(0xFFB99750),
              style: const TextStyle(color: Colors.white),
              items: _currencies
                  .map((cur) => DropdownMenuItem(
                        value: cur,
                        child: Text(cur),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _currency = val!;
                  _notifyParent();
                });
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BuildTextField(
                label: 'Total Price',
                controller: priceController,
                keyboardType: TextInputType.number,
                hint: 'Amount Paid',
                onChanged: (_) => _notifyParent(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BuildTextField(
          label: 'Making Cost',
          controller: makingCostController,
          keyboardType: TextInputType.number,
          hint: 'per gram',
          onChanged: (_) => _notifyParent(),
        ),
        const SizedBox(height: 10),
        BuildTextField(
          label: 'Precious Metal Rate',
          controller: metalRateController,
          keyboardType: TextInputType.number,
          hint: 'e.g. 6000 rs/g',
          onChanged: (_) => _notifyParent(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPricingSection();
  }
}
