// lib/src/pages/bills.dart

import 'package:flutter/material.dart';
import 'package:jevvels/new_entry/utils/signed_url.dart';
import 'package:jevvels/powersync/powersync_connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  List<Map<String, dynamic>> _bills = [];
  String? _offlineError;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<String?> _getBillImageUrl(String? storagePath) {
    return SignedUrlHelper.getSignedUrl(storagePath);
  }

  Future<void> _fetchBills() async {
    try {
      final result = await db.execute('''
      SELECT ji.id,
             ji.notes,
             ji.total_weight,
             ji.bill_images_id,
             ji.category_id,
             bi.path AS bill_image_path,
             c.name AS category,
             pd.total_price,
             pd.making_cost,
             pd.precious_metals_rate
      FROM jewelry_items ji
      LEFT JOIN bill_images bi ON ji.bill_images_id = bi.id
      LEFT JOIN categories c ON ji.category_id = c.id
      LEFT JOIN pricing_details pd ON pd.jewelry_item_id = ji.id
      ORDER BY ji.id DESC
    ''');

      final bills = result.map<Map<String, dynamic>>((row) {
        final mapped = {
          'id': row['id'] as String,
          'notes': row['notes'],
          'total_weight': (row['total_weight'] as num?)?.toDouble(),
          'bill_images_id': row['bill_images_id'] as String?,
          'category_id': row['category_id'] as String?,
          'bill_image_path':
              row['bill_image_path'] as String?, // 👈 direct from DB
          'category': row['category'] as String?,
          'total_price': row['total_price'] as num?,
          'making_cost': row['making_cost'] as num?,
          'precious_metals_rate': row['precious_metals_rate'] as num?,
        };

        print('🧾 bill id: ${mapped['id']}');
        print('🖼  bill_image_path (DB): ${mapped['bill_image_path']}');
        final url = _getBillImageUrl(mapped['bill_image_path'] as String?);
        print('🌐 imageUrl: $url');

        return mapped;
      }).toList();

      setState(() {
        _bills = bills;
        _offlineError = null; // you can even remove _offlineError entirely now
      });
    } catch (e, st) {
      print('❌ Error in _fetchBills (PowerSync): $e');
      print(st);
      setState(() {
        _bills = [];
        _offlineError =
            "Sorry, you can't view your information without a network connection.";
      });
    }
  }

  Future<void> _showImageDialog(String url) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF272424),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Main Font',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteBill(Map<String, dynamic> bill) async {
  // Always treat id as String
  final jewelryItemId = bill['id'].toString();

  // Get image + shop/category ids from jewelry_items
  final jiRows = await db.execute(
    'SELECT bill_images_id, item_images_id, shop_id, category_id '
    'FROM jewelry_items WHERE id = ?',
    [jewelryItemId],
  );

  if (jiRows.isEmpty) {
    print('⚠️ No jewelry_item found for id $jewelryItemId');
    return;
  }

  final ji = jiRows.first;

  String? billImageId = ji['bill_images_id']?.toString();
  String? itemImageId = ji['item_images_id']?.toString();
  final shopId = ji['shop_id'];
  final catId = ji['category_id'];

  // --- 1️⃣ Delete metals first ---
  final metalsBefore = await db.execute(
    'SELECT COUNT(*) as cnt FROM metals WHERE jewelry_item_id = ?',
    [jewelryItemId],
  );
  print('🧪 Metals before delete: ${metalsBefore.first['cnt']}');

  await db.execute(
    'DELETE FROM metals WHERE jewelry_item_id = ?',
    [jewelryItemId],
  );

  final metalsAfter = await db.execute(
    'SELECT COUNT(*) as cnt FROM metals WHERE jewelry_item_id = ?',
    [jewelryItemId],
  );
  print('🧪 Metals after delete: ${metalsAfter.first['cnt']}');

  // --- 2️⃣ Delete pricing_details ---
  await db.execute(
    'DELETE FROM pricing_details WHERE jewelry_item_id = ?',
    [jewelryItemId],
  );

  // --- 3️⃣ Resolve image paths from bill_images / item_images ---
  String? billImagePath;
  String? itemImagePath;

  if (billImageId != null) {
    final billImg = await db.execute(
      'SELECT path FROM bill_images WHERE id = ?',
      [billImageId],
    );
    billImagePath =
        billImg.isNotEmpty ? billImg.first['path'] as String? : null;
  }

  if (itemImageId != null) {
    final itemImg = await db.execute(
      'SELECT path FROM item_images WHERE id = ?',
      [itemImageId],
    );
    itemImagePath =
        itemImg.isNotEmpty ? itemImg.first['path'] as String? : null;
  }

  // --- 4️⃣ Delete from Supabase Storage (images bucket) ---
  final storage = Supabase.instance.client.storage.from('images');

  if (billImagePath != null && billImagePath.isNotEmpty) {
    try {
      await storage.remove([billImagePath]); // e.g. 'bills/<id>.jpg'
    } catch (e) {
      print('⚠️ Error deleting bill image from storage: $e');
    }
  }

  if (itemImagePath != null && itemImagePath.isNotEmpty) {
    try {
      await storage.remove([itemImagePath]); // e.g. 'items/<id>.jpg'
    } catch (e) {
      print('⚠️ Error deleting item image from storage: $e');
    }
  }

  // --- 5️⃣ Delete attachments_queue (if used) ---
  if (billImageId != null) {
    await db.execute(
      'DELETE FROM attachments_queue WHERE id = ?',
      [billImageId],
    );
  }
  if (itemImageId != null) {
    await db.execute(
      'DELETE FROM attachments_queue WHERE id = ?',
      [itemImageId],
    );
  }

  // --- 6️⃣ Delete from jewelry_items ---
  await db.execute(
    'DELETE FROM jewelry_items WHERE id = ?',
    [jewelryItemId],
  );

  // --- 7️⃣ Delete shop if unused ---
  if (shopId != null) {
    final shopCount = await db.execute(
      'SELECT COUNT(*) as cnt FROM jewelry_items WHERE shop_id = ?',
      [shopId],
    );
    if (shopCount.isNotEmpty &&
        (shopCount.first['cnt'] == 0 || shopCount.first['cnt'] == 0.0)) {
      await db.execute('DELETE FROM shops WHERE id = ?', [shopId]);
    }
  }

  // --- 8️⃣ Delete category if unused ---
  if (catId != null) {
    final catCount = await db.execute(
      'SELECT COUNT(*) as cnt FROM jewelry_items WHERE category_id = ?',
      [catId],
    );
    if (catCount.isNotEmpty &&
        (catCount.first['cnt'] == 0 || catCount.first['cnt'] == 0.0)) {
      await db.execute('DELETE FROM categories WHERE id = ?', [catId]);
    }
  }

  // --- 9️⃣ Reload list ---
  await _fetchBills();
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

                // Safely cast numeric fields for chips
                final weight = bill['total_weight'] as num?;
                final totalPrice = bill['total_price'] as num?;
                final makingCost = bill['making_cost'] as num?;
                final preciousRate = bill['precious_metals_rate'] as num?;

                final imageUrl =
                    _getBillImageUrl(bill['bill_image_path'] as String?);

                return GestureDetector(
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF272424),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Delete Entry',
                          style: TextStyle(
                            color: Color(0xFFB99750),
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          'Are you sure you want to delete this entry and all its details? This cannot be undone.',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Main Font',
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: Color(0xFFB99750),
                                fontFamily: 'Main Font',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _deleteBill(bill);
                    }
                  },
                  child: Card(
                    color: const Color(0xFF2C2B2B),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side:
                          const BorderSide(color: Color(0xFFB99750), width: 1),
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
                              // 🧾 Bill Image from Supabase
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FutureBuilder<String?>(
                                  future: _getBillImageUrl(
                                      bill['bill_image_path'] as String?),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.black26,
                                      );
                                    }

                                    final url = snapshot.data;
                                    if (url == null) {
                                      return Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.black26,
                                        child: const Icon(
                                          Icons.receipt_long,
                                          color: Colors.white38,
                                          size: 40,
                                        ),
                                      );
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        _showImageDialog(url);
                                      },
                                      child: Image.network(
                                        url,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.black26,
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.white38,
                                              size: 40,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
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
                                                  'Wt: ${weight != null ? weight.toStringAsFixed(2) : '--'}g',
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
                                  if (totalPrice != null)
                                    _InfoChip(
                                      icon: Icons.attach_money,
                                      label:
                                          '₹${totalPrice.toStringAsFixed(2)}',
                                    ),
                                  if (makingCost != null)
                                    _InfoChip(
                                      icon: Icons.build,
                                      label:
                                          'Making: ₹${makingCost.toStringAsFixed(2)}',
                                    ),
                                  if (preciousRate != null)
                                    _InfoChip(
                                      icon: Icons.star,
                                      label:
                                          'Rate: ₹${preciousRate.toStringAsFixed(2)}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
              color: const Color(0xFFB99750),
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
