import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoldPriceCard extends StatefulWidget {
  const GoldPriceCard({super.key});

  @override
  State<GoldPriceCard> createState() => _GoldPriceCardState();
}

class _GoldPriceCardState extends State<GoldPriceCard> {
  Map<String, double>? metals;
  DateTime? updatedDate;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMetals();
  }

Future<void> _fetchMetals() async {
  try {
    final data = await Supabase.instance.client
        .from('metals_cache')
        .select('metal, price_in_inr, fetched_at')
        .order('fetched_at', ascending: false);   // ← newest first

    final metalsMap = <String, double>{};

    // Pick ONLY the latest value for each metal
    for (final row in data) {
      final metal = row['metal'].toString();
      final price = (row['price_in_inr'] as num).toDouble();

      // only take first (latest) value per metal
      if (!metalsMap.containsKey(metal)) {
        metalsMap[metal] = price;
      }
    }

    final DateTime latestFetchedAt = data.isNotEmpty
        ? DateTime.parse(data.first['fetched_at'].toString())
        : DateTime.now();

    setState(() {
      metals = metalsMap;
      updatedDate = latestFetchedAt;
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
      return const Center(
          child: Text('Failed to load metal prices',
              style: TextStyle(color: Colors.white)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: 300,
        height: 260,
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Color(0xFFB99750), 
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
            _buildMetalRow('Gold', metals?['gold']),
            _buildMetalRow('Silver', metals?['silver']),
            _buildMetalRow('Platinum', metals?['platinum']),
            _buildMetalRow('Copper', metals?['copper']),
            _buildMetalRow('Zinc', metals?['zinc']),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Updated • ${updatedDate?.toLocal().toString().split(' ')[0] ?? ''}',
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
