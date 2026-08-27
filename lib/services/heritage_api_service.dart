import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models.dart';

class HeritageApiService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  static Future<List<HeritageSite>> fetchMalaysiaHeritage() async {
    // Overpass QL Query: Searches for historic tags, heritage sites, and UNESCO areas within Malaysia
    const query = '''
      [out:json][timeout:25];
      area["ISO3166-1"="MY"]["admin_level"="2"]->.searchArea;
      (
        node["historic"](area.searchArea);
        way["historic"](area.searchArea);
        node["heritage"](area.searchArea);
        way["heritage"](area.searchArea);
      );
      out body center 60;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> elements = data['elements'] ?? [];

        List<HeritageSite> sites = [];

        for (var element in elements) {
          final Map<String, dynamic>? tags = element['tags'];
          if (tags == null || tags['name'] == null) continue;

          final String name = tags['name'] ?? '';
          final String rawCategory =
              tags['historic'] ?? tags['heritage'] ?? 'National';
          final String location = tags['addr:state'] ??
              tags['is_in:state'] ??
              tags['addr:city'] ??
              'Malaysia';

          // Standardize categories for app UI filters
          String category = _mapCategory(rawCategory, tags);

          // Extract coordinates safely (Node vs Way center)
          double lat = 0.0;
          double lon = 0.0;
          if (element['lat'] != null && element['lon'] != null) {
            lat = (element['lat'] as num).toDouble();
            lon = (element['lon'] as num).toDouble();
          } else if (element['center'] != null) {
            lat = (element['center']['lat'] as num).toDouble();
            lon = (element['center']['lon'] as num).toDouble();
          }

          // Generate dynamic tags based on API payload metadata
          List<String> siteTags = [category];
          if (tags.containsKey('religion')) siteTags.add(tags['religion']);
          if (tags.containsKey('building')) siteTags.add(tags['building']);

          sites.add(
            HeritageSite(
              id: (element['id'] ?? DateTime.now().millisecondsSinceEpoch)
                  .toString(),
              name: name,
              location: location,
              category: category,
              description: tags['description'] ??
                  tags['note'] ??
                  'Historic landmark located in $location, Malaysia.',
              imageUrl: tags['image'] ?? tags['wikimedia_commons'] ?? '',
              latitude: lat,
              longitude: lon,
              duration: '1–2 hours',
              xp: category == 'UNESCO' ? 150 : 100,
              isEditorPick: tags['heritage'] == '1' ||
                  tags['heritage:operator'] == 'whc',
              visited: false,
              tags: siteTags,
            ),
          );
        }

        // Deduplicate sites by name
        final uniqueSites = <String, HeritageSite>{};
        for (var site in sites) {
          uniqueSites.putIfAbsent(site.name, () => site);
        }

        return uniqueSites.values.toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching Overpass data: $e');
      rethrow;
    }
  }

  static String _mapCategory(String raw, Map<String, dynamic> tags) {
    if (tags['heritage'] == '1' ||
        tags['heritage:operator'] == 'whc' ||
        tags.containsValue('unesco')) {
      return 'UNESCO';
    }
    if (tags.containsKey('religion') ||
        raw == 'place_of_worship' ||
        raw == 'monument') {
      return 'Religious';
    }
    if (raw == 'memorial' ||
        raw == 'castle' ||
        raw == 'fort' ||
        raw == 'archaeological_site') {
      return 'National';
    }
    if (raw == 'nature_reserve' || tags.containsKey('leisure')) {
      return 'Nature';
    }
    return 'National';
  }
}