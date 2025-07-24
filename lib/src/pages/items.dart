import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jevvels/new_entry/supabase_storage_adapter.dart';
import 'package:jevvels/powersync/powersync_connector.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({Key? key}) : super(key: key);

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final itemId = item['id'];
    // Get image IDs and paths
    final jewelry = await db.execute(
        'SELECT bill_images_id, item_images_id FROM jewelry_items WHERE id = ?',
        [itemId]);
    String? billImageId =
        jewelry.isNotEmpty ? jewelry.first['bill_images_id']?.toString() : null;
    String? itemImageId =
        jewelry.isNotEmpty ? jewelry.first['item_images_id']?.toString() : null;
    String? billImagePath;
    String? itemImagePath;
    if (billImageId != null) {
      final billImg = await db
          .execute('SELECT path FROM bill_images WHERE id = ?', [billImageId]);
      billImagePath = billImg.isNotEmpty ? billImg.first['path'] : null;
    }
    if (itemImageId != null) {
      final itemImg = await db
          .execute('SELECT path FROM item_images WHERE id = ?', [itemImageId]);
      itemImagePath = itemImg.isNotEmpty ? itemImg.first['path'] : null;
    }

    // Delete from Supabase storage (use $id.jpg)
    final supabase = SupabaseStorageAdapter('images');
    if (billImageId != null) {
      try {
        await supabase.deleteFile('$billImageId.jpg');
      } catch (e) {
        // ignore error, log if needed
      }
    }
    if (itemImageId != null) {
      try {
        await supabase.deleteFile('$itemImageId.jpg');
      } catch (e) {
        // ignore error, log if needed
      }
    }

    // Delete local files (path column)
    if (billImagePath != null && billImagePath.isNotEmpty) {
      try {
        final file = File(billImagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // ignore error, log if needed
      }
    }
    if (itemImagePath != null && itemImagePath.isNotEmpty) {
      try {
        final file = File(itemImagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // ignore error, log if needed
      }
    }

    // Delete from all relevant tables in schema
    // Delete metals
    await db.execute('DELETE FROM metals WHERE jewelry_item_id = ?', [itemId]);
    // Delete pricing_details
    await db.execute(
        'DELETE FROM pricing_details WHERE jewelry_item_id = ?', [itemId]);
    // Delete shop if unused
    final shopId = item['shop_id'];
    if (shopId != null) {
      final shopCount = await db.execute(
          'SELECT COUNT(*) as cnt FROM jewelry_items WHERE shop_id = ?',
          [shopId]);
      if (shopCount.isNotEmpty &&
          (shopCount.first['cnt'] == 0 || shopCount.first['cnt'] == 0.0)) {
        await db.execute('DELETE FROM shops WHERE id = ?', [shopId]);
      }
    }
    // Delete from attachments_queue (if used)
    if (billImageId != null) {
      await db
          .execute('DELETE FROM attachments_queue WHERE id = ?', [billImageId]);
    }
    if (itemImageId != null) {
      await db
          .execute('DELETE FROM attachments_queue WHERE id = ?', [itemImageId]);
    }
    // Delete jewelry_items (must be before bill_images/item_images/shops for FK constraints)
    await db.execute('DELETE FROM jewelry_items WHERE id = ?', [itemId]);

    // Delete bill_images and item_images (after jewelry_items)
    if (billImageId != null) {
      await db.execute('DELETE FROM bill_images WHERE id = ?', [billImageId]);
    }
    if (itemImageId != null) {
      await db.execute('DELETE FROM item_images WHERE id = ?', [itemImageId]);
    }

    // Delete shop if unused (after jewelry_items)
    if (shopId != null) {
      final shopCount = await db.execute(
          'SELECT COUNT(*) as cnt FROM jewelry_items WHERE shop_id = ?',
          [shopId]);
      if (shopCount.isNotEmpty &&
          (shopCount.first['cnt'] == 0 || shopCount.first['cnt'] == 0.0)) {
        await db.execute('DELETE FROM shops WHERE id = ?', [shopId]);
      }
    }

    // Delete category if unused
    final catId = item['category_id'];
    if (catId != null) {
      final catCount = await db.execute(
          'SELECT COUNT(*) as cnt FROM jewelry_items WHERE category_id = ?',
          [catId]);
      if (catCount.isNotEmpty &&
          (catCount.first['cnt'] == 0 || catCount.first['cnt'] == 0.0)) {
        await db.execute('DELETE FROM categories WHERE id = ?', [catId]);
      }
    }
    await _fetchItems();
  }

  List<Map<String, dynamic>> _items = [];
  Map<String, List<Map<String, dynamic>>> _metalsByItem = {};

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    // Get all jewelry items with their item image, category, shop, and total_weight
    final items = await db.execute('''
      SELECT ji.id, ji.total_weight, ji.item_images_id, ji.category_id, ji.shop_id,
             ii.path as item_image_path, c.name as category, s.name as shop
      FROM jewelry_items ji
      LEFT JOIN item_images ii ON ji.item_images_id = ii.id
      LEFT JOIN categories c ON ji.category_id = c.id
      LEFT JOIN shops s ON ji.shop_id = s.id
      ORDER BY ji.id DESC
    ''');
    // Get all metals for all items
    final metals = await db.execute('''
      SELECT m.id, m.jewelry_item_id, m.type, m.weight, m.karat
      FROM metals m
    ''');
    // Group metals by jewelry_item_id
    final Map<String, List<Map<String, dynamic>>> metalsByItem = {};
    for (final metal in metals) {
      final itemId = metal['jewelry_item_id'].toString();
      metalsByItem.putIfAbsent(itemId, () => []).add(metal);
    }
    setState(() {
      _items = items;
      _metalsByItem = metalsByItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF272424),
      appBar: AppBar(
        title: const Text(
          'Items',
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
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'No items found.',
                style: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Main Font',
                  fontSize: 20,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, idx) {
                final item = _items[idx];
                final metals = _metalsByItem[item['id']] ?? [];
                final totalWeight =
                    (item['total_weight'] as num?)?.toDouble() ?? 0.0;
                // Calculate percentages for each metal
                List<_MetalInfo> metalInfos = metals.map((m) {
                  final weight = (m['weight'] as num?)?.toDouble() ?? 0.0;
                  final percent =
                      (totalWeight > 0) ? (weight / totalWeight * 100) : 0.0;
                  return _MetalInfo(
                    type: m['type']?.toString() ?? '',
                    weight: weight,
                    karat: m['karat'] != null ? m['karat'].toString() : '',
                    percent: percent,
                  );
                }).toList();
                return GestureDetector(
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF272424),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Delete Item',
                            style: TextStyle(
                                color: Color(0xFFB99750),
                                fontFamily: 'Main Font',
                                fontWeight: FontWeight.bold)),
                        content: const Text(
                            'Are you sure you want to delete this item and all its details? This cannot be undone.',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Main Font')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Main Font')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(
                                    color: Color(0xFFB99750),
                                    fontFamily: 'Main Font',
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteItem(item);
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item['item_image_path'] != null
                                ? Image.file(
                                    File(item['item_image_path']),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.black26,
                                    child: const Icon(Icons.image,
                                        color: Colors.white38, size: 40),
                                  ),
                          ),
                          const SizedBox(width: 18),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['category'] ?? 'Unknown Category',
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
                                      item['shop'] ?? 'Unknown Shop',
                                      style: const TextStyle(
                                        fontFamily: 'Main Font',
                                        color: Colors.white54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      'Total: ${totalWeight.toStringAsFixed(2)}g',
                                      style: const TextStyle(
                                        fontFamily: 'Main Font',
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
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
                                      children: metalInfos
                                          .map((metal) =>
                                              _MetalChip(metal: metal))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
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
        onPressed: _fetchItems,
        backgroundColor: const Color(0xFFB99750),
        child: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }
}

class _MetalInfo {
  final String type;
  final double weight;
  final String karat;
  final double percent;
  _MetalInfo(
      {required this.type,
      required this.weight,
      required this.karat,
      required this.percent});
}

class _MetalChip extends StatelessWidget {
  final _MetalInfo metal;
  const _MetalChip({required this.metal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2F2F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFB99750)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${metal.type.toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFFB99750),
              fontFamily: 'Main Font',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${metal.percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Main Font',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${metal.weight.toStringAsFixed(2)}g',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Main Font',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          if (metal.karat.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '${metal.karat}K',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Main Font',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
