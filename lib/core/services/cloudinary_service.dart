import 'dart:io';

// The package currently exposes UploadParams only from this path.
// ignore: implementation_imports
import 'package:cloudinary_api/src/request/model/uploader_params.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

class CloudinaryService {
  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  static final Cloudinary _cloudinary = Cloudinary.fromCloudName(
    cloudName: _cloudName,
  );

  static Future<String> uploadImage(String filePath) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw StateError(
        'Cloudinary is not configured. Run with '
        '--dart-define=CLOUDINARY_CLOUD_NAME=... and '
        '--dart-define=CLOUDINARY_UPLOAD_PRESET=...',
      );
    }

    final response = await _cloudinary.uploader().upload(
      File(filePath),
      params: UploadParams(
        uploadPreset: _uploadPreset,
        unsigned: true,
        folder: 'campus_found/items',
      ),
    );

    final secureUrl = response?.data?.secureUrl;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw StateError(response?.error?.message ?? 'Cloudinary upload failed');
    }

    return secureUrl;
  }
}