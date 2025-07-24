import 'package:flutter/material.dart';

class GoldPriceCard extends StatelessWidget {
  final Map<String, double> metals;
  final DateTime updatedDate;

  const GoldPriceCard({
    super.key,
    required this.metals,
    required this.updatedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: 300,
        height: 260,
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Color(0xFFB99750), // Gold tone
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metal Prices (Per Gram)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Main Font',
              ),
            ),
            const SizedBox(height: 10),
            _buildMetalRow('Gold', metals['gold']),
            _buildMetalRow('Silver', metals['silver']),
            _buildMetalRow('Platinum', metals['platinum']),
            _buildMetalRow('Copper', metals['copper']),
            _buildMetalRow('Zinc', metals['zinc']),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Updated • ${updatedDate.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Main Font',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetalRow(String label, double? value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            color: Color(0xFF47143D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Main Font',
          ),
        ),
        Text(
          value != null ? value.toStringAsFixed(2) : '--',
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Main Font',
              fontSize: 18,
              fontWeight: FontWeight.bold),
        )
      ],
    );
  }
}
