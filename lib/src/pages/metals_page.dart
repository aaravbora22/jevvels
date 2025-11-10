import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jevvels/src/pages/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MetalsPage extends StatefulWidget {
  const MetalsPage({super.key});

  @override
  State<MetalsPage> createState() => _MetalsPageState();
}

class _MetalsPageState extends State<MetalsPage> {
  // Brand colors
  static const gold = Color(0xFFB99750);
  static const bgDark = Color(0xFF272424);
  static const cardDark = Color(0xFF2F2A2A);
  static const faint = Color(0xFF9B8B6B); 

  double makingCost = 0.0;
  Map<String, List<double>> metalHistory = {};
  Map<String, double> metalWeights = {};
  Map<String, double> metalTodayPrices = {};
  bool _loading = true;
  String? _largestMetal;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);

    final pricingDetails = await Supabase.instance.client
        .from('pricing_details')
        .select('id, jewelry_item_id, making_cost');

    final metals = await Supabase.instance.client
        .from('metals')
        .select('jewelry_item_id, type, weight');

    double totalMakingCost = 0.0;
    final weights = <String, double>{};

    for (final pd in pricingDetails) {
      if (pd['making_cost'] != null) {
        final itemId = pd['jewelry_item_id'];
        final itemMetals =
            (metals as List).where((m) => m['jewelry_item_id'] == itemId);
        double totalWeight = 0.0;
        for (final m in itemMetals) {
          if (m['weight'] != null) {
            final w = (m['weight'] as num).toDouble();
            totalWeight += w;
            final type = m['type'].toString().toLowerCase();
            weights[type] = (weights[type] ?? 0) + w;
          }
        }
        totalMakingCost += (pd['making_cost'] as num).toDouble() * totalWeight;
      }
    }

    String? largest;
    double maxWeight = 0.0;
    weights.forEach((k, v) {
      if (v > maxWeight) {
        maxWeight = v;
        largest = k;
      }
    });

    final today = DateTime.now();
    final tenDaysAgo = today.subtract(const Duration(days: 10));
    final metalsList = ['gold', 'silver', 'platinum', 'copper', 'zinc'];

    final history = <String, List<double>>{};
    final todayPrices = <String, double>{};

    for (final metal in metalsList) {
      final rows = await Supabase.instance.client
          .from('metals_cache')
          .select('price_in_inr, fetched_at')
          .eq('metal', metal)
          .gte('fetched_at', tenDaysAgo.toIso8601String().split('T')[0])
          .order('fetched_at', ascending: true);

      history[metal] = (rows as List)
          .map<double>((row) => (row['price_in_inr'] as num).toDouble())
          .toList();

      final todayRow = (rows as List).lastWhere(
        (row) => row['fetched_at']
            .toString()
            .startsWith(today.toIso8601String().split('T')[0]),
        orElse: () => <String, dynamic>{},
      );
      todayPrices[metal] = todayRow.isNotEmpty
          ? (todayRow['price_in_inr'] as num).toDouble()
          : 0.0;
    }

    setState(() {
      makingCost = totalMakingCost;
      metalHistory = history;
      metalWeights = weights;
      metalTodayPrices = todayPrices;
      _largestMetal = largest;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: bgDark,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const Dashboard(),
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_back,
              color: gold,
            ),
            iconSize: 28,
          )
        ],
        title: const Text(
          'Metals',
          style: TextStyle(
            fontFamily: 'Main Font',
            fontSize: 35,
            color: gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : RefreshIndicator(
              color: gold,
              backgroundColor: cardDark,
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  ..._buildMetalCards(),
                  const SizedBox(height: 18),
                  _MakingCostHeader(total: makingCost),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildMetalCards() {
    final order = [
      if (_largestMetal != null) _largestMetal!,
      ...metalHistory.keys.where((k) => k != _largestMetal)
    ];

    return order.where((metal) {
      final key = metal.toLowerCase();
      final weight = metalWeights[key] ?? 0.0;
      return weight > 0;
    }).map((metal) {
      final key = metal.toLowerCase();
      final prices = metalHistory[key] ?? const [];
      final weight = metalWeights[key] ?? 0.0;
      final todayPrice = metalTodayPrices[key] ?? 0.0;
      final isLargest = key == _largestMetal;
      return _MetalCard(
        metal: key,
        prices: prices,
        weight: weight,
        todayPrice: todayPrice,
        isLargest: isLargest,
      );
    }).toList();
  }
}

// header for making cost
class _MakingCostHeader extends StatelessWidget {
  const _MakingCostHeader({required this.total});

  static const gold = _MetalsPageState.gold;
  static const bgDark = _MetalsPageState.bgDark;
  static const faint = _MetalsPageState.faint;

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MetalsPageState.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: faint.withOpacity(0.6), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // small label
          const Text(
            'Total Making Cost',
            style: TextStyle(
              fontFamily: 'Main Font',
              color: gold,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          // big number
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Main Font',
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 30,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: faint),
          const SizedBox(height: 8),
          const Text(
            'Includes all items',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

//metal card
class _MetalCard extends StatelessWidget {
  const _MetalCard({
    required this.metal,
    required this.prices,
    required this.weight,
    required this.todayPrice,
    required this.isLargest,
  });

  static const gold = _MetalsPageState.gold;
  static const bgDark = _MetalsPageState.bgDark;
  static const cardDark = _MetalsPageState.cardDark;
  static const faint = _MetalsPageState.faint;

  final String metal;
  final List<double> prices;
  final double weight;
  final double todayPrice;
  final bool isLargest;

  String get name => metal[0].toUpperCase() + metal.substring(1);

  @override
  Widget build(BuildContext context) {
    final value = todayPrice * weight;
    final priceChange = prices.isNotEmpty ? todayPrice - prices.first : 0.0;
    final pctChange = prices.isNotEmpty && prices.first != 0
        ? (priceChange / prices.first) * 100
        : 0.0;

    if (isLargest) {
      // SPECIAL OUTLINED CARD
      return Container(
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: bgDark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // name + BIG WEIGHT pill
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Main Font',
                      color: gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      border: Border.all(color: gold, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${weight.toStringAsFixed(2)} g',
                      style: const TextStyle(
                        fontFamily: 'Main Font',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // VALUE (hero)
              Text(
                '₹${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),

              // price + change (subtle)
              Text(
                '₹${todayPrice.toStringAsFixed(2)}  (${priceChange >= 0 ? '+' : ''}${pctChange.toStringAsFixed(2)}%)',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // big chart
              SizedBox(
                height: 200,
                child: prices.isEmpty
                    ? const Center(
                        child: Text('No data',
                            style: TextStyle(color: Colors.white54)))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < prices.length; i++)
                                  FlSpot(i.toDouble(), prices[i])
                              ],
                              isCurved: true,
                              color: gold,
                              barWidth: 4,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  if (index == prices.length - 1) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: Colors.black, 
                                      strokeWidth: 2,
                                      strokeColor: _MetalsPageState
                                          .gold, 
                                    );
                                  }
                                  return FlDotCirclePainter(
                                      radius: 0); 
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    // COMPACT CARDS
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: faint.withOpacity(0.6), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // line 1: name + weight
            Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Main Font',
                    color: gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${weight.toStringAsFixed(2)} g',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                // subtle change %
                Text(
                  '${priceChange >= 0 ? '+' : ''}${pctChange.toStringAsFixed(2)}%',
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // line 2: value + today price (small)
            Row(
              children: [
                Text(
                  '₹${(todayPrice * weight).toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 10),
                Text(
                  '₹${todayPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: gold, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // mini chart
            SizedBox(
              height: 70,
              child: prices.isEmpty
                  ? const Center(
                      child: Text('No data',
                          style: TextStyle(color: Colors.white54)))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < prices.length; i++)
                                FlSpot(i.toDouble(), prices[i] * weight)
                            ],
                            isCurved: true,
                            color: gold,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                if (index == prices.length - 1) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.black, 
                                    strokeWidth: 2,
                                    strokeColor: _MetalsPageState
                                        .gold, 
                                  );
                                }
                                return FlDotCirclePainter(
                                    radius: 0); 
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
