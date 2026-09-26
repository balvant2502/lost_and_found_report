import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class ImagePickResult {
  final String? filePath;
  final String? errorMessage;

  ImagePickResult.success(this.filePath) : errorMessage = null;
  ImagePickResult.error(this.errorMessage) : filePath = null;
  ImagePickResult.cancelled()
      : filePath = null,
        errorMessage = null;

  bool get isSuccess => filePath != null;
  bool get hasError => errorMessage != null;
}

class FileHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from Gallery or Camera, enforces the 10 MB limit,
  /// and saves it locally inside the application documents directory.
  static Future<ImagePickResult> pickAndSaveReportImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return ImagePickResult.cancelled();
      }

      // Enforce 10 MB limit
      final int fileBytes = await pickedFile.length();
      if (fileBytes > AppConstants.maxImageSizeBytes) {
        final double mbSize = fileBytes / (1024 * 1024);
        return ImagePickResult.error(
          'Selected image is ${mbSize.toStringAsFixed(1)} MB. '
          'Maximum allowed size is 10 MB.',
        );
      }

      if (kIsWeb) {
        // On web, XFile path is a browser blob URL and path_provider is not supported
        return ImagePickResult.success(pickedFile.path);
      }

      // Save locally using path_provider
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/item_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final String extension = pickedFile.name.contains('.')
          ? pickedFile.name.split('.').last
          : 'jpg';
      final String localFileName = '${const Uuid().v4()}.$extension';
      final String targetPath = '${imagesDir.path}/$localFileName';

      final File localFile = File(targetPath);
      await pickedFile.saveTo(localFile.path);

      return ImagePickResult.success(localFile.path);
    } catch (e) {
      return ImagePickResult.error('Failed to pick or save image: $e');
    }
  }

  /// Checks if a given local image path exists on the device.
  static bool doesLocalImageExist(String? path) {
    if (kIsWeb) return false;
    if (path == null || path.trim().isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
