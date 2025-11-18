import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef ImagesChanged = void Function(File? billImage, File? itemImage);

class BuildImageSection extends StatefulWidget {
  final File? billImage;
  final File? itemImage;
  final ImagesChanged? onImagesChanged;
  const BuildImageSection(
      {super.key, this.billImage, this.itemImage, this.onImagesChanged});

  @override
  State<BuildImageSection> createState() => _BuildImageSectionState();
}

class _BuildImageSectionState extends State<BuildImageSection> {
  File? billImage;
  File? itemImage;
  final picker = ImagePicker();

  void _notifyParent() {
    if (widget.onImagesChanged != null) {
      widget.onImagesChanged!(billImage, itemImage);
    }
  }

  @override
  void didUpdateWidget(covariant BuildImageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent changes the image, update local state
    if (widget.billImage != billImage || widget.itemImage != itemImage) {
      setState(() {
        billImage = widget.billImage;
        itemImage = widget.itemImage;
      });
    }
  }

  Future<void> pickImage(bool isBill, {bool fromCamera = false}) async {
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked != null) {
      setState(() {
        if (isBill) {
          billImage = File(picked.path);
        } else {
          itemImage = File(picked.path);
        }
        _notifyParent();
      });
    }
  }

  Widget _buildImageUploader(String label, bool isBill, File? image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Main Font',
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => pickImage(isBill, fromCamera: false),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2B2B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB99750)),
                  ),
                  child: Center(
                    child: image == null
                        ? const Icon(Icons.upload, color: Colors.white38)
                        : Image.file(image, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => pickImage(isBill, fromCamera: true),
              child: Container(
                height: 100,
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2B2B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFB99750)),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white38),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    billImage = widget.billImage;
    itemImage = widget.itemImage;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        
        _buildImageUploader('Upload Item Image', false, itemImage),
        const SizedBox(height: 15),
        _buildImageUploader('Upload Bill Image', true, billImage),
      ],
    );
  }
}
