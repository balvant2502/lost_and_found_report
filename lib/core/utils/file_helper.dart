import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
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
        // On web, convert directly to a portable Base64 data URL
        final bytes = await pickedFile.readAsBytes();
        final base64Content = base64Encode(bytes);
        final extension = pickedFile.name.contains('.')
            ? pickedFile.name.split('.').last
            : 'jpeg';
        return ImagePickResult.success(
          'data:image/$extension;base64,$base64Content',
        );
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

  /// Converts a local image file into a portable Base64 data URL
  /// (e.g. data:image/jpeg;base64,...) for direct cross-device syncing via Firestore.
  static Future<String?> getPortableImageDataUrl(String filePath) async {
    final trimmed = filePath.trim();
    if (trimmed.isEmpty) return null;
    if (isBase64ImageUrl(trimmed) ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (kIsWeb) {
      return trimmed;
    }
    try {
      final file = File(trimmed);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final base64Content = base64Encode(bytes);
      final extension = trimmed.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      return 'data:image/$extension;base64,$base64Content';
    } catch (e) {
      debugPrint('Failed to convert image to portable data URL: $e');
      return null;
    }
  }

  /// Extracts raw image bytes from a Base64 data URL or raw Base64 string.
  static Uint8List? decodeBase64Image(String? dataUrl) {
    if (dataUrl == null || dataUrl.trim().isEmpty) return null;
    try {
      final commaIndex = dataUrl.indexOf(',');
      final base64Content =
          commaIndex != -1 ? dataUrl.substring(commaIndex + 1) : dataUrl;
      return base64Decode(base64Content.trim());
    } catch (_) {
      return null;
    }
  }

  /// Determines if a string is a valid Base64 data image URL.
  static bool isBase64ImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return url.startsWith('data:image');
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
