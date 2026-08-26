import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  static Future<String> getHeritageImage(String name) async {
    final url = Uri.parse(
      'https://commons.wikimedia.org/w/api.php'
          '?action=query'
          '&generator=search'
          '&gsrsearch=${Uri.encodeComponent(name)}'
          '&gsrnamespace=6'
          '&gsrlimit=1'
          '&prop=imageinfo'
          '&iiprop=url'
          '&iiurlwidth=500' // Requests downscaled thumbnails for mobile
          '&format=json',
    );

    try {
      // Wikimedia requires a custom User-Agent header
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MalaysiaGoApp/1.0 (flutter_app; contact@example.com)',
        },
      );

      if (response.statusCode != 200) {
        return '';
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final query = data['query'] as Map<String, dynamic>?;

      if (query == null || !query.containsKey('pages')) {
        return '';
      }

      final Map<String, dynamic> pages = query['pages'];
      if (pages.isEmpty) return '';

      final firstPageKey = pages.keys.first;
      final firstPage = pages[firstPageKey] as Map<String, dynamic>?;

      final List<dynamic>? imageInfo = firstPage?['imageinfo'];
      if (imageInfo == null || imageInfo.isEmpty) return '';

      final info = imageInfo.first as Map<String, dynamic>;

      return (info['thumburl'] as String?) ?? (info['url'] as String?) ?? '';
    } catch (e) {
      return '';
    }
  }
}