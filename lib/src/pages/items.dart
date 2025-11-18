// lib/src/pages/items.dart
import 'package:flutter/material.dart';
import 'package:jevvels/powersync/powersync_connector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jevvels/new_entry/utils/signed_url.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({Key? key}) : super(key: key);

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  List<Map<String, dynamic>> _items = [];
  Map<String, List<Map<String, dynamic>>> _metalsByItem = {};

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  /// 🔗 Build a Supabase Storage URL for an item image
  /// item_image_path should be something like: 'items/<uuid>.jpg'
  // String? _getItemImageUrl(String? storagePath) {
  //   if (storagePath == null || storagePath.isEmpty) return null;

  //   final supabase = Supabase.instance.client;

  //   // bucket name = 'images'
  //   return supabase.storage.from('images').getPublicUrl(storagePath);
  // }
  Future<String?> _getItemImageUrl(String? storagePath) {
    return SignedUrlHelper.getSignedUrl(storagePath);
  }

  Future<void> _fetchItems() async {
    // Everything from local PowerSync DB (online or offline)
    final items = await db.execute('''
      SELECT ji.id, ji.total_weight, ji.item_images_id, ji.category_id, ji.shop_id,
             ii.path as item_image_path,
             c.name as category,
             s.name as shop
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

    // Optional debug
    for (final it in items) {
      print('💍 item id: ${it['id']}');
      print('🖼  item_image_path (DB): ${it['item_image_path']}');
      final url = _getItemImageUrl(it['item_image_path'] as String?);
      print('🌐 imageUrl: $url');
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
                      color: Colors.white70,
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

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final itemId = item['id'];

    // Get image ids from jewelry_items
    final jewelry = await db.execute(
      'SELECT bill_images_id, item_images_id FROM jewelry_items WHERE id = ?',
      [itemId],
    );

    String? billImageId =
        jewelry.isNotEmpty ? jewelry.first['bill_images_id']?.toString() : null;
    String? itemImageId =
        jewelry.isNotEmpty ? jewelry.first['item_images_id']?.toString() : null;

    // Get stored *paths* from bill_images / item_images
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

    // 🔥 Delete from Supabase Storage (images bucket)
    final storage = Supabase.instance.client.storage.from('images');

    if (billImagePath != null && billImagePath.isNotEmpty) {
      try {
        await storage.remove([billImagePath]); // e.g. 'bills/<id>.jpg'
      } catch (e) {
        // log if you want
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

    // Delete metals
    await db.execute('DELETE FROM metals WHERE jewelry_item_id = ?', [itemId]);

    // Delete pricing_details
    await db.execute(
      'DELETE FROM pricing_details WHERE jewelry_item_id = ?',
      [itemId],
    );

    // Delete from attachments_queue (if used)
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

    // Delete jewelry_items
    await db.execute('DELETE FROM jewelry_items WHERE id = ?', [itemId]);

    // Delete bill_images and item_images
    if (billImageId != null) {
      await db.execute('DELETE FROM bill_images WHERE id = ?', [billImageId]);
    }
    if (itemImageId != null) {
      await db.execute('DELETE FROM item_images WHERE id = ?', [itemImageId]);
    }

    // Delete shop if unused
    final shopId = item['shop_id'];
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

    // Delete category if unused
    final catId = item['category_id'];
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

    await _fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF272424),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFFB99750)),
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

                // calculate percentages for each metal
                final List<_MetalInfo> metalInfos = metals.map((m) {
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

                final imageUrl =
                    _getItemImageUrl(item['item_image_path'] as String?);

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
                          'Delete Item',
                          style: TextStyle(
                            color: Color(0xFFB99750),
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          'Are you sure you want to delete this item and all its details? This cannot be undone.',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Main Font',
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
                              ),
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
                      await _deleteItem(item);
                    }
                  },
                  child: Card(
                    color: const Color(0xFF2C2B2B),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFFB99750),
                        width: 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🧺 Item image from Supabase
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FutureBuilder<String?>(
                              future: _getItemImageUrl(
                                  item['item_image_path'] as String?),
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
                                      Icons.image,
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
                                    errorBuilder: (context, error, stackTrace) {
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
  _MetalInfo({
    required this.type,
    required this.weight,
    required this.karat,
    required this.percent,
  });
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
            metal.type.toUpperCase(),
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
