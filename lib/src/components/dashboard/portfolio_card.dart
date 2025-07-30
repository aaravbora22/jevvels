import 'package:flutter/material.dart';
import 'package:jevvels/powersync/powersync_connector.dart';
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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculatePortfolio();
  }

  Future<void> _calculatePortfolio() async {
    try {
      // Fetch today's rates from Supabase metals_cache
      final today = DateTime.now().toIso8601String().split('T')[0];
      final metalsCache = await Supabase.instance.client
          .from('metals_cache')
          .select('metal, price_in_inr')
          .eq('fetched_at', today)
          .order('metal', ascending: true)
          .then((result) => result as List<dynamic>);
      final metalRates = <String, double>{};
      for (final row in metalsCache) {
        metalRates[row['metal'].toString().toLowerCase()] =
            (row['price_in_inr'] as num).toDouble();
      }

      // Fetch jewelry_items
      final items = await db.execute('SELECT * FROM jewelry_items');
      // Fetch metals
      final metals = await db.execute('SELECT * FROM metals');
      // Fetch pricing_details
      final pricingDetails = await db.execute('SELECT * FROM pricing_details');

      double totalCurrentValue = 0.0;
      double totalBoughtValue = 0.0;
      Map<String, double> metalTotals = {};
      Map<String, double> metalCurrentValues = {};

      for (final item in items) {
        final itemId = item['id'];
        // Get metals for this item
        final itemMetals =
            metals.where((m) => m['jewelry_item_id'] == itemId).toList();
        if (itemMetals.isEmpty) continue;

        // Find dominant metal (highest weight)
        itemMetals
            .sort((a, b) => (b['weight'] as num).compareTo(a['weight'] as num));
        final dominantMetal = itemMetals.first;
        final dominantWeight = (dominantMetal['weight'] as num).toDouble();

        // Get pricing_details for this item
        final pd = pricingDetails.firstWhere(
          (p) => p['jewelry_item_id'] == itemId,
        );
        final boughtRate = pd.containsKey('precious_metals_rate')
            ? (pd['precious_metals_rate'] as num?)?.toDouble() ?? 0.0
            : 0.0;

        // Calculate bought value for dominant metal
        final boughtValueForItem = dominantWeight * boughtRate;
        totalBoughtValue += boughtValueForItem;

        // Calculate current value for all metals in item
        for (final m in itemMetals) {
          final type = m['type'].toString().toLowerCase();
          final weight = (m['weight'] as num).toDouble();
          final rate = metalRates[type] ??
              boughtRate; // fallback to boughtRate if not in API
          final value = weight * rate;
          totalCurrentValue += value;
          metalTotals[type] = (metalTotals[type] ?? 0) + weight;
          metalCurrentValues[type] = (metalCurrentValues[type] ?? 0) + value;
        }
      }

      // Calculate percentages
      final totalWeight = metalTotals.values.fold(0.0, (a, b) => a + b);
      final metalPercentagesCalc = <String, double>{};
      metalTotals.forEach((type, weight) {
        metalPercentagesCalc[type[0].toUpperCase() + type.substring(1)] =
            totalWeight > 0 ? (weight / totalWeight) * 100 : 0.0;
      });

      // Capitalize keys for display
      final metalValuesCalc = <String, double>{};
      metalCurrentValues.forEach((type, value) {
        metalValuesCalc[type[0].toUpperCase() + type.substring(1)] = value;
      });

      setState(() {
        currentValue = totalCurrentValue;
        boughtValue = totalBoughtValue;
        metalPercentages = metalPercentagesCalc;
        metalValues = metalValuesCalc;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
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
                        ' ₹${metalValues[entry.key]?.toStringAsFixed(2) ?? '--'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
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
