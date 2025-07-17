import 'package:flutter/material.dart';

class GoldPriceCard extends StatelessWidget {
  final double price24k;
  final double price22k;
  final double price18k;

  const GoldPriceCard({
    super.key,
    required this.price24k,
    required this.price22k,
    required this.price18k,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: 300,
        height: 200,
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Color(0xFFB99750), // Gold tone
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gold Price (Per Gram)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Main Font',
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Text(
                  "24K: ",
                  style: TextStyle(
                    color: Color(0xFF47143D),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Main Font',
                  ),
                ),
                Text(
                  // "\$${price24k.toStringAsFixed(2)}",
                  "\$107.89",
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Main Font',
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
            const Row(
              children: [
                Text(
                  "22K: ",
                  style: TextStyle(
                    color: Color(0xFF47143D),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Main Font',
                  ),
                ),
                Text(
                  // "\$${price22k.toStringAsFixed(2)}",
                  "\$98.5",
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Main Font',
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
            const Row(
              children: [
                Text(
                  "18K: ",
                  style: TextStyle(
                    color: Color(0xFF47143D),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Main Font',
                  ),
                ),
                Text(
                  // "\$${price18k.toStringAsFixed(2)}",
                  "\$80.92",
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Main Font',
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Updated • ${DateTime.now().toLocal().toString().split(' ')[0]}',
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
}
