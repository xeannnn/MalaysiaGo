import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'scutrgkv';
  static const String _uploadPreset = 'malaysiago_community';

  Future<String> uploadImage(XFile image) async {
    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset;

    final List<int> bytes = await image.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
      ),
    );

    final http.StreamedResponse response = await request.send();
    final String responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Image upload failed.');
    }

    final Map<String, dynamic> data =
        jsonDecode(responseBody) as Map<String, dynamic>;

    final String imageUrl = data['secure_url']?.toString() ?? '';

    if (imageUrl.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return imageUrl;
  }
}
