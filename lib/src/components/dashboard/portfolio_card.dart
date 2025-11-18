import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortfolioCard extends StatefulWidget {
  const PortfolioCard({super.key});

  @override
  State<PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<PortfolioCard> {
  double currentValue = 0.0;
  double boughtValue = 0.0;
  Map<String, double> metalPercentages = {};
  Map<String, double> metalValues = {};
  Map<String, double> metalTotals = {}; 
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculatePortfolio();
  }
  Future<void> _calculatePortfolio() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final metalsCache = await Supabase.instance.client
          .from('metals_cache')
          .select('metal, price_in_inr')
          .eq('fetched_at', today)
          .order('metal', ascending: true);
      final metalRates = <String, double>{};
      for (final row in metalsCache) {
        metalRates[row['metal'].toString().toLowerCase()] =
            (row['price_in_inr'] as num).toDouble();
      }

      final items = await Supabase.instance.client
          .from('jewelry_items')
          .select('id')
          .order('id', ascending: true);

      double totalCurrentValue = 0.0;
      double totalBoughtValue = 0.0;
      metalTotals = {}; 
      Map<String, double> metalCurrentValues = {};

      // fetch all pricing_details for bought value
      final pricingDetails = await Supabase.instance.client
          .from('pricing_details')
          .select('total_price');

      // sum all total_price values for boughtValue
      for (final pd in pricingDetails) {
        if (pd['total_price'] != null) {
          totalBoughtValue += (pd['total_price'] as num).toDouble();
        }
      }

      for (final item in items) {
        final itemId = item['id'];

        final itemMetals = await Supabase.instance.client
            .from('metals')
            .select('type, weight')
            .eq('jewelry_item_id', itemId);

        if (itemMetals.isEmpty) continue;

        for (final m in itemMetals) {
          final type = m['type'].toString().toLowerCase();
          final weight = (m['weight'] as num).toDouble();
          final rate = metalRates[type] ?? 0.0;
          final value = weight * rate;
          totalCurrentValue += value;
          metalTotals[type] = (metalTotals[type] ?? 0) + weight;
          metalCurrentValues[type] = (metalCurrentValues[type] ?? 0) + value;
        }
      }

      final totalWeight = metalTotals.values.fold(0.0, (a, b) => a + b);
      final metalPercentagesCalc = <String, double>{};
      metalTotals.forEach((type, weight) {
        metalPercentagesCalc[type[0].toUpperCase() + type.substring(1)] =
            totalWeight > 0 ? (weight / totalWeight) * 100 : 0.0;
      });

      final metalValuesCalc = <String, double>{};
      metalCurrentValues.forEach((type, value) {
        metalValuesCalc[type[0].toUpperCase() + type.substring(1)] = value;
      });

      // capitalize keys for display in metalTotals
      final metalTotalsDisplay = <String, double>{};
      metalTotals.forEach((type, weight) {
        metalTotalsDisplay[type[0].toUpperCase() + type.substring(1)] = weight;
      });
      metalTotals = metalTotalsDisplay;

      setState(() {
        currentValue = totalCurrentValue;
        boughtValue = totalBoughtValue;
        metalPercentages = metalPercentagesCalc;
        metalValues = metalValuesCalc;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load portfolio";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Text('Failed to load portfolio',
              style: TextStyle(color: Colors.white)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: 300,
        height: 200,
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Color(0xFFB99750),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Right Now.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Main Font'),
                  ),
                  Text(
                    currentValue.toStringAsFixed(2),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontFamily: 'Main Font',
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'Bought.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Main Font'),
                  ),
                  Text(
                    boughtValue.toStringAsFixed(2),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Main Font',
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: metalPercentages.entries.map((entry) {
                  final metalKey = entry.key;
                  final weight = metalTotals[metalKey] ?? 0.0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metalKey,
                        style: const TextStyle(
                            fontFamily: 'Main Font',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Text(
                        ' ${entry.value.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: Color(0xFF47143D),
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' ₹${metalValues[metalKey]?.toStringAsFixed(2) ?? '--'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        ' (${weight.toStringAsFixed(2)}g)',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}