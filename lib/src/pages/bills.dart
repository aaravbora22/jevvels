import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jevvels/powersync/powersync_connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  List<Map<String, dynamic>> _bills = [];

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

    String? _offlineError;

  Future<void> _fetchBills() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('jewelry_items')
          .select('id, notes, total_weight, bill_images_id, category_id, '
              'categories(name), '
              'bill_images(path), '
              'pricing_details(total_price, making_cost, precious_metals_rate)')
          .order('id', ascending: false);

      final bills = (response as List)
          .map<Map<String, dynamic>>((item) => {
                'id': item['id'],
                'notes': item['notes'],
                'total_weight': item['total_weight'],
                'bill_images_id': item['bill_images_id'],
                'category_id': item['category_id'],
                'bill_image_path': item['bill_images']?['path'],
                'category': item['categories']?['name'],
                'total_price': item['pricing_details']?['total_price'],
                'making_cost': item['pricing_details']?['making_cost'],
                'precious_metals_rate':
                    item['pricing_details']?['precious_metals_rate'],
              })
          .toList();

      setState(() {
        _bills = bills;
        _offlineError = null;
      });
    } catch (e) {
      try {
        final result = await db.execute('''
          SELECT ji.id, ji.notes, ji.total_weight, ji.bill_images_id, ji.category_id,
                 bi.path as bill_image_path, c.name as category,
                 pd.total_price, pd.making_cost, pd.precious_metals_rate
          FROM jewelry_items ji
          LEFT JOIN bill_images bi ON ji.bill_images_id = bi.id
          LEFT JOIN categories c ON ji.category_id = c.id
          LEFT JOIN pricing_details pd ON pd.jewelry_item_id = ji.id
          ORDER BY ji.id DESC
        ''');
        setState(() {
          _bills = result;
          _offlineError = result.isEmpty
              ? "Sorry, you can't view your information without a network connection."
              : null;
        });
      } catch (e2) {
        setState(() {
          _bills = [];
          _offlineError =
              "Sorry, you can't view your information without a network connection.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF272424),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFFB99750)),
        title: const Text(
          'Bills',
          style: TextStyle(
            fontFamily: 'Main Font',
            color: Color(0xFFB99750),
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _bills.isEmpty
          ? Center(
              child: Text(
                _offlineError ?? 'No bills found.',
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Main Font',
                  fontSize: 20,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bills.length,
              itemBuilder: (context, idx) {
                final bill = _bills[idx];
                return Card(
                  color: const Color(0xFF2C2B2B),
                  elevation: 6,
                  shadowColor: Colors.black.withOpacity(0.18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFB99750), width: 1),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bill Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: bill['bill_image_path'] != null
                                  ? Image.file(
                                      File(bill['bill_image_path']),
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 90,
                                      height: 90,
                                      color: Colors.black26,
                                      child: const Icon(Icons.receipt_long,
                                          color: Colors.white38, size: 40),
                                    ),
                            ),
                            const SizedBox(width: 18),
                            // Info
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              bill['category'] ??
                                                  'Unknown Category',
                                              style: const TextStyle(
                                                fontFamily: 'Main Font',
                                                color: Color(0xFFB99750),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '#${bill['id'].toString().substring(0, 6)}',
                                            style: const TextStyle(
                                              fontFamily: 'Main Font',
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (bill['notes'] != null &&
                                          bill['notes'].toString().isNotEmpty)
                                        Text(
                                          bill['notes'],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontFamily: 'Main Font',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _InfoChip(
                                            icon: Icons.scale,
                                            label:
                                                'Wt: ${bill['total_weight']?.toStringAsFixed(2) ?? '--'}g',
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (bill['total_price'] != null)
                                  _InfoChip(
                                    icon: Icons.attach_money,
                                    label:
                                        '₹${bill['total_price'].toStringAsFixed(2)}',
                                  ),
                                if (bill['making_cost'] != null)
                                  _InfoChip(
                                    icon: Icons.build,
                                    label:
                                        'Making: ₹${bill['making_cost'].toStringAsFixed(2)}',
                                  ),
                                if (bill['precious_metals_rate'] != null)
                                  _InfoChip(
                                    icon: Icons.star,
                                    label:
                                        'Rate: ₹${bill['precious_metals_rate'].toStringAsFixed(2)}',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchBills,
        backgroundColor: const Color(0xFFB99750),
        child: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final bool isPrice = label.startsWith('₹');
    final bool isMaking = label.startsWith('Making:');
    final double fontSize =
        (isPrice || isMaking || label.startsWith('Rate:')) ? 18 : 14;
    final FontWeight fontWeight =
        (isPrice || isMaking) ? FontWeight.w900 : FontWeight.bold;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2F2F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFB99750)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFB99750), size: fontSize),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFFB99750),
              fontFamily: 'Main Font',
              fontWeight: fontWeight,
              fontSize: fontSize,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
