import 'package:flutter/material.dart';
import 'package:jevvels/new_entry/utils/build_category_section.dart';
import 'package:jevvels/new_entry/utils/build_image_section.dart';
import 'package:jevvels/new_entry/utils/build_metals_section.dart';
import 'package:jevvels/new_entry/utils/build_notes_section.dart';
import 'package:jevvels/new_entry/utils/build_pricing_section.dart';
import 'package:jevvels/new_entry/utils/build_shop_section.dart';
import 'package:jevvels/src/pages/dashboard.dart';
import 'package:jevvels/widgets/build_text_field.dart';

class JewelryFormPage extends StatefulWidget {
  const JewelryFormPage({super.key});

  @override
  State<JewelryFormPage> createState() => _JewelryFormPageState();
}

class _JewelryFormPageState extends State<JewelryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final totalWeightController = TextEditingController();

  @override
  void dispose() {
    totalWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 39, 36, 36),
      appBar: AppBar(
        title: const Text('Add Entry',
            style: TextStyle(
                fontFamily: 'Main Font',
                color: Color(0xFFB99750),
                fontWeight: FontWeight.bold,
                fontSize: 30)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const Dashboard()));
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const BuildCategorySection(),
            const SizedBox(height: 20),
            const BuildMetalsSection(),
            const SizedBox(height: 20),
            BuildTextField(
              label: 'Total Weight (g)',
              controller: totalWeightController,
              textStyle: const TextStyle(
                  fontFamily: 'Main Font', fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const BuildShopSection(),
            const SizedBox(height: 20),
            const BuildImageSection(),
            const SizedBox(height: 20),
            BuildNotesSection(),
            const SizedBox(height: 30),
            const BuildPricingSection(),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB99750),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Process and save the data
                }
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
    );
  }
}
