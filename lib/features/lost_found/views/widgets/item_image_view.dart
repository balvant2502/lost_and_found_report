import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/utils/file_helper.dart';

/// A unified, cross-platform image view for Lost & Found items.
/// Seamlessly supports:
/// 1. Portable Base64 data URLs (`data:image/jpeg;base64,...` or `data:image/png;base64,...`)
/// 2. Remote URLs (Cloudinary, Firebase Storage, HTTP/HTTPS, Web blob)
/// 3. Local device files (when running on device where image was picked)
/// 4. Graceful custom fallback placeholders when image is missing or inaccessible.
class ItemImageView extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext context) placeholderBuilder;

  const ItemImageView({
    super.key,
    required this.imageUrl,
    required this.placeholderBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImage(context);
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildImage(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return placeholderBuilder(context);
    }

    // 1. Portable Base64 data URL (e.g. data:image/jpeg;base64,...)
    if (FileHelper.isBase64ImageUrl(url)) {
      final bytes = FileHelper.decodeBase64Image(url);
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => placeholderBuilder(context),
        );
      }
      return placeholderBuilder(context);
    }

    // 2. Remote URL or Web Blob
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('blob:')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholderBuilder(context),
      );
    }

    // 3. Local device file path
    if (!kIsWeb && FileHelper.doesLocalImageExist(url)) {
      return Image.file(
        File(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholderBuilder(context),
      );
    }

    // 4. Inaccessible cross-device path or fallback
    return placeholderBuilder(context);
  }
}
