import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

class BuildPricingSection extends StatefulWidget {
  const BuildPricingSection({super.key});

  @override
  State<BuildPricingSection> createState() => _BuildPricingSectionState();
}

class _BuildPricingSectionState extends State<BuildPricingSection> {
  String _currency = 'INR';
  final List<String> _currencies = ['USD', 'INR', 'EUR'];
  final TextEditingController priceController = TextEditingController();
  final TextEditingController makingCostController = TextEditingController();
  final TextEditingController metalRateController = TextEditingController();

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
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BuildTextField(
          label: 'Making Cost',
          controller: makingCostController,
          keyboardType: TextInputType.number,
          hint: 'e.g. 500',
        ),
        const SizedBox(height: 10),
        BuildTextField(
          label: 'Precious Metal Rate',
          controller: metalRateController,
          keyboardType: TextInputType.number,
          hint: 'e.g. 6000/g',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPricingSection();
  }
}
