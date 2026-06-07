import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageCompressor {
  ImageCompressor._();

  static const int maxWidth = 1024;
  static const int jpegQuality = 85;

  static Future<File> compressImageFile(File file) async {
    final bytes = await file.readAsBytes();
    final compressed = await compressImageBytes(bytes);
    final tempPath = '${file.path}_compressed.jpg';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(compressed);
    return tempFile;
  }

  static Future<Uint8List> compressImageBytes(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    img.Image resized = image;
    if (image.width > maxWidth) {
      resized = img.copyResize(image, width: maxWidth);
    }

    final encoded = img.encodeJpg(resized, quality: jpegQuality);
    return Uint8List.fromList(encoded);
  }

  static Future<File> compressToMaxSize(File file, int maxSizeBytes) async {
    final bytes = await file.readAsBytes();
    if (bytes.length <= maxSizeBytes) return file;

    final image = img.decodeImage(bytes);
    if (image == null) return file;

    int quality = jpegQuality;
    img.Image current = image;

    if (image.width > maxWidth) {
      current = img.copyResize(image, width: maxWidth);
    }

    Uint8List encoded = Uint8List.fromList(img.encodeJpg(current, quality: quality));

    while (encoded.length > maxSizeBytes && quality > 30) {
      quality -= 10;
      encoded = Uint8List.fromList(img.encodeJpg(current, quality: quality));
    }

    final tempPath = '${file.path}_compressed.jpg';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(encoded);
    return tempFile;
  }

  /// Deletes a file only if it is a compressor-produced temp file (recognised
  /// by the `_compressed.jpg` suffix), so callers can clean up after upload
  /// without ever deleting the user's original image.
  static Future<void> deleteIfTemp(File file) async {
    if (file.path.endsWith('_compressed.jpg')) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}
