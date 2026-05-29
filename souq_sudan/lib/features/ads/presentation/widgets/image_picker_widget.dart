import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_image_widget.dart';

class ImagePickerWidget extends StatelessWidget {
  final List<File> localImages;
  final List<String> networkImages;
  final void Function(List<File>) onLocalImagesChanged;
  final void Function(String) onNetworkImageRemoved;

  const ImagePickerWidget({
    super.key,
    required this.localImages,
    required this.networkImages,
    required this.onLocalImagesChanged,
    required this.onNetworkImageRemoved,
  });

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختر من المعرض'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقط صورة'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;
    final totalExisting = localImages.length + networkImages.length;

    if (action == 'gallery') {
      final remaining = 10 - totalExisting;
      if (remaining <= 0) return;
      final picked = await picker.pickMultiImage(limit: remaining);
      if (picked.isNotEmpty) {
        onLocalImagesChanged([...localImages, ...picked.map((x) => File(x.path))]);
      }
    } else {
      if (totalExisting >= 10) return;
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        onLocalImagesChanged([...localImages, File(picked.path)]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = networkImages.length + localImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الصور ($totalImages/10)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Network images
              ...networkImages.asMap().entries.map((entry) {
                return _buildImageTile(
                  child: CachedImageWidget(imageUrl: entry.value, width: 90, height: 90),
                  onRemove: () => onNetworkImageRemoved(entry.value),
                );
              }),
              // Local images
              ...localImages.asMap().entries.map((entry) {
                return _buildImageTile(
                  child: Image.file(entry.value, width: 90, height: 90, fit: BoxFit.cover),
                  onRemove: () {
                    final updated = List<File>.from(localImages);
                    updated.removeAt(entry.key);
                    onLocalImagesChanged(updated);
                  },
                );
              }),
              // Add button
              if (totalImages < 10)
                GestureDetector(
                  onTap: () => _pickImages(context),
                  child: Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.background,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 32),
                        Text('إضافة', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(left: 8, top: 4, right: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
