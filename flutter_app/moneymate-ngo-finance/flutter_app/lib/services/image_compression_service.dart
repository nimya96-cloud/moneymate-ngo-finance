import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressionService {
  /// Compresses a photo taken from the camera or gallery
  /// Downsamples to max 1280px dimension and 70% JPEG quality.
  /// Reduces typical 5-8MB smartphone photos down to ~90-120KB!
  static Future<File?> compressReceiptImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        final origSizeKb = file.lengthSync() / 1024;
        final compSizeKb = compressedFile.lengthSync() / 1024;
        print('Image compressed: ${origSizeKb.toStringAsFixed(1)} KB -> ${compSizeKb.toStringAsFixed(1)} KB');
        return compressedFile;
      }
      return file;
    } catch (e) {
      print('Compression error fallback: $e');
      return file;
    }
  }
}
