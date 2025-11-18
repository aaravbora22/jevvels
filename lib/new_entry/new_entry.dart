import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jevvels/new_entry/supabase_storage_adapter.dart';
import 'package:jevvels/new_entry/utils/build_category_section.dart';
import 'package:jevvels/new_entry/utils/build_image_section.dart';
import 'package:jevvels/new_entry/utils/build_metals_section.dart';
import 'package:jevvels/new_entry/utils/build_notes_section.dart';
import 'package:jevvels/new_entry/utils/build_pricing_section.dart';
import 'package:jevvels/new_entry/utils/build_shop_section.dart';
import 'package:jevvels/powersync/powersync_connector.dart';
import 'package:jevvels/new_entry/supabase_powersync_images.dart';
import 'package:jevvels/src/pages/dashboard.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jevvels/widgets/build_text_field.dart';

class JewelryFormPage extends StatefulWidget {
  const JewelryFormPage({super.key});

  @override
  State<JewelryFormPage> createState() => _JewelryFormPageState();
}

class _JewelryFormPageState extends State<JewelryFormPage> {
  late final AttachmentSyncQueue _billAttachmentQueue;
  late final AttachmentSyncQueue _itemAttachmentQueue;
  final _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  final totalWeightController = TextEditingController();
  final shopNameController = TextEditingController();
  final notesController = TextEditingController();
  final priceController = TextEditingController();
  final makingCostController = TextEditingController();
  final metalRateController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String _selectedCategory = 'Necklace';

  @override
  void dispose() {
    totalWeightController.dispose();
    shopNameController.dispose();
    notesController.dispose();
    priceController.dispose();
    makingCostController.dispose();
    metalRateController.dispose();
    super.dispose();
    _customCategoryController.dispose();
  }

  File? _billImage;
  String? _billImageId;
  File? _itemImage;
  String? _itemImageId;

  String? _category;
  String? _customCategory;
  List<Map<String, dynamic>> _metals = [
    {
      "metal": null,
      "weight": null,
      "is_karat": true,
      "karat": null,
      "purity": null,
    }
  ];

  String? _shopName;
  String? _notes;
  Map<String, dynamic>? _pricing;

  @override
  void initState() {
    super.initState();

    final remoteStorage = SupabaseStorageAdapter('images');

    _billAttachmentQueue = AttachmentSyncQueue(
      db,
      remoteStorage,
      remotePrefix: 'bills',
      idColumn: 'bill_images_id',
    );

    _itemAttachmentQueue = AttachmentSyncQueue(
      db,
      remoteStorage,
      remotePrefix: 'items',
      idColumn: 'item_images_id',
    );

    _billAttachmentQueue.init();
    _itemAttachmentQueue.init();
  }

  Future<void> _copyAndQueue(
    File picked,
    String id,
    AttachmentSyncQueue queue,
  ) async {
    final baseFilename = '$id.jpg';
    final storageDir = await queue.getStorageDirectory();

    final prefix = queue.remotePrefix; // 'bills' or 'items'
    final remotePath = prefix.isEmpty
        ? baseFilename
        : '$prefix/$baseFilename'; // 'bills/id.jpg'

    final targetPath = '$storageDir/$remotePath';

    // Ensure 'bills' or 'items' folder exists under storageDir
    final dir = Directory(
      targetPath.substring(0, targetPath.lastIndexOf('/')),
    );
    await dir.create(recursive: true);
    await File(picked.path).copy(targetPath);

    final size = await File(targetPath).length();
    await queue.saveFile(id, size);
  }

  Future<bool> _confirmUploadDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF272424),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image, size: 48, color: Color(0xFFB99750)),
                const SizedBox(height: 16),
                const Text(
                  'Upload Image?',
                  style: TextStyle(
                    fontFamily: 'Main Font',
                    color: Color(0xFFB99750),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Do you want to upload this image?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Main Font',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFFB99750),
                          side: const BorderSide(color: Color(0xFFB99750)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No',
                            style: TextStyle(
                                fontFamily: 'Main Font',
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB99750),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes',
                            style: TextStyle(
                                fontFamily: 'Main Font',
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  Future<void> _cleanupTempImages() async {
    try {
      final storage = Supabase.instance.client.storage.from('images');

      // 🔹 Clean up bill image if present
      if (_billImageId != null) {
        // Get remote path from bill_images
        final rows = await db.execute(
          'SELECT path FROM bill_images WHERE id = ?',
          [_billImageId],
        );
        final billPath = rows.isNotEmpty ? rows.first['path'] as String? : null;

        // Delete from Supabase Storage
        if (billPath != null && billPath.isNotEmpty) {
          try {
            await storage.remove([billPath]);
          } catch (e) {
            print('⚠️ Error deleting bill image from storage: $e');
          }
        }

        // Delete from attachments_queue (so it doesn't try to upload later)
        await db.execute(
          'DELETE FROM attachments_queue WHERE id = ?',
          [_billImageId],
        );

        // Delete from bill_images table
        await db.execute(
          'DELETE FROM bill_images WHERE id = ?',
          [_billImageId],
        );
      }

      // 🔹 Clean up item image if present
      if (_itemImageId != null) {
        final rows = await db.execute(
          'SELECT path FROM item_images WHERE id = ?',
          [_itemImageId],
        );
        final itemPath = rows.isNotEmpty ? rows.first['path'] as String? : null;

        if (itemPath != null && itemPath.isNotEmpty) {
          try {
            await storage.remove([itemPath]);
          } catch (e) {
            print('⚠️ Error deleting item image from storage: $e');
          }
        }

        await db.execute(
          'DELETE FROM attachments_queue WHERE id = ?',
          [_itemImageId],
        );

        await db.execute(
          'DELETE FROM item_images WHERE id = ?',
          [_itemImageId],
        );
      }

      // Clear local state
      if (mounted) {
        setState(() {
          _billImage = null;
          _billImageId = null;
          _itemImage = null;
          _itemImageId = null;
        });
      }
    } catch (e, st) {
      print('❌ Error during _cleanupTempImages: $e');
      print(st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF272424),
      appBar: AppBar(
        title: const Text(
          'Add Entry',
          style: TextStyle(
            fontFamily: 'Main Font',
            color: Color(0xFFB99750),
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFB99750)),
            onPressed: () async {
              // 🔹 Clean up any temp images first
              await _cleanupTempImages();

              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              BuildImageSection(
                billImage: _billImage,
                itemImage: _itemImage,
                onImagesChanged: (File? bill, File? item) async {
                  // Bill image logic (only if it's a new file)
                  if (bill != null && bill.path != _billImage?.path) {
                    final ok = await _confirmUploadDialog();
                    if (ok) {
                      final billId = _uuid.v4();

                      // 🔹 This is the *remote* path in Supabase
                      final remotePath = 'bills/$billId.jpg';

                      // 🔹 Store remote path in bill_images.path
                      await db.execute(
                        'INSERT INTO bill_images (id, path) VALUES (?, ?)',
                        [billId, remotePath],
                      );

                      setState(() {
                        _billImage = bill;
                        _billImageId = billId;
                      });

                      // 🔹 Copy file to local attachments/bills/<id>.jpg + queue upload
                      await _copyAndQueue(bill, billId, _billAttachmentQueue);
                    } else {
                      setState(() {
                        _billImage = null;
                        _billImageId = null;
                      });
                    }
                  }
                  // Item image logic (only if it's a new file)
                  if (item != null && item.path != _itemImage?.path) {
                    final ok = await _confirmUploadDialog();
                    if (ok) {
                      final itemId = _uuid.v4();

                      // REMOTE path for Supabase
                      final remotePath = 'items/$itemId.jpg';

                      await db.execute(
                        'INSERT INTO item_images (id, path) VALUES (?, ?)',
                        [itemId, remotePath],
                      );

                      setState(() {
                        _itemImage = item;
                        _itemImageId = itemId;
                      });

                      await _copyAndQueue(item, itemId, _itemAttachmentQueue);
                    } else {
                      setState(() {
                        _itemImage = null;
                        _itemImageId = null;
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              BuildCategorySection(
                selectedCategory: _selectedCategory,
                customCategoryController: _customCategoryController,
                onCategoryChanged: (cat, customCat) {
                  setState(() {
                    _selectedCategory = cat;
                    _category = cat;
                    _customCategory = customCat;
                  });
                },
              ),
              const SizedBox(height: 20),
              BuildMetalsSection(
                metals: _metals,
                onMetalsChanged: (List<Map<String, dynamic>> metals) {
                  setState(() {
                    _metals = metals;
                  });
                },
              ),
              const SizedBox(height: 20),
              BuildTextField(
                label: 'Total Weight (g)',
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),

                controller: totalWeightController,
                textStyle: const TextStyle(
                  fontFamily: 'Main Font',
                  fontSize: 24,
                  color: Color(0xFF2A1F1F),
                ),
              ),
              const SizedBox(height: 20),
              BuildShopSection(
                controller: shopNameController,
                onShopChanged: (shop) {
                  _shopName = shop;
                },
              ),
              const SizedBox(height: 20),
              BuildNotesSection(
                controller: notesController,
                onNotesChanged: (notes) {
                  _notes = notes;
                },
              ),
              const SizedBox(height: 30),
              BuildPricingSection(
                onPricingChanged: (pricing) {
                  _pricing = pricing;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB99750),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not logged in!')),
                    );
                    return;
                  }

                  final userId = user.id;
                  final uuid = Uuid();
                  final jewelryItemId = uuid.v4();

                  // category lookup/insert
                  final categoryName = _category ?? _customCategory ?? '';
                  String categoryId;
                  final catRes = await db.execute(
                      'SELECT id FROM categories WHERE name = ?',
                      [categoryName]);
                  if (catRes.isNotEmpty) {
                    categoryId = catRes.first['id'];
                  } else {
                    categoryId = uuid.v4();
                    await db.execute(
                      'INSERT INTO categories (id, name) VALUES (?, ?)',
                      [categoryId, categoryName],
                    );
                  }

                  // shop lookup/insert
                  final shopName = _shopName ?? '';
                  String shopId;
                  final shopRes = await db.execute(
                      'SELECT id FROM shops WHERE name = ?', [shopName]);
                  if (shopRes.isNotEmpty) {
                    shopId = shopRes.first['id'];
                  } else {
                    shopId = uuid.v4();
                    await db.execute(
                      'INSERT INTO shops (id, name) VALUES (?, ?)',
                      [shopId, shopName],
                    );
                  }

                  // insert jewelry_item
                  await db.execute(
                    '''
                    INSERT INTO jewelry_items (
                      id, user_id, category_id, shop_id,
                      total_weight, bill_images_id, item_images_id, notes
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ''',
                    [
                      jewelryItemId,
                      userId,
                      categoryId,
                      shopId,
                      double.tryParse(totalWeightController.text) ?? 0.0,
                      _billImageId,
                      _itemImageId,
                      _notes ?? '',
                    ],
                  );

                  // metals
                  for (final metal in _metals) {
                    await db.execute(
                      '''
                      INSERT INTO metals (
                        id, jewelry_item_id, type, weight, karat, purity, user_id
                      ) VALUES (?, ?, ?, ?, ?, ?, ?)
                      ''',
                      [
                        uuid.v4(),
                        jewelryItemId,
                        metal["metal"],
                        metal["weight"] != null
                            ? double.tryParse(metal["weight"].toString())
                            : null,
                        metal["karat"] != null
                            ? int.tryParse(metal["karat"].toString())
                            : null,
                        metal["purity"] != null
                            ? int.tryParse(metal["purity"].toString())
                            : null,
                        userId.toString(),
                      ],
                    );
                  }
                  // pricing details
                  if (_pricing != null) {
                    await db.execute(
                      '''
                      INSERT INTO pricing_details (
                        id, jewelry_item_id, total_price, making_cost, precious_metals_rate
                      ) VALUES (?, ?, ?, ?, ?)
                      ''',
                      [
                        uuid.v4(),
                        jewelryItemId,
                        double.tryParse(_pricing!['totalPrice'] ?? '0') ?? 0.0,
                        double.tryParse(_pricing!['makingCost'] ?? '0') ?? 0.0,
                        double.tryParse(_pricing!['metalRate'] ?? '0') ?? 0.0,
                      ],
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry saved!')),
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const Dashboard()),
                  );
                },
                child: const Text(
                  'Save Item',
                  style: TextStyle(
                    fontFamily: 'Main Font',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
