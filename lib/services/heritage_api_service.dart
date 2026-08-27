// lib/services/heritage_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models.dart';

/// Service that fetches heritage site data from an API.
/// Currently returns dummy data for testing.
class HeritageApiService {
  /// Fetches a list of heritage sites from the API.
  /// Returns a list of [HeritageSite] objects.
  static Future<List<HeritageSite>> fetchMalaysiaHeritage() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return dummy data
    return [
      HeritageSite(
        id: 'batu_caves',
        name: 'Batu Caves',
        location: 'Selangor',
        description: 'Sacred limestone cathedral above Kuala Lumpur',
        category: 'Religious',
        latitude: 3.2379,
        longitude: 101.6840,
        imageUrl: '',
        tags: ['Religious', 'Easy'],
        duration: '2–3 hours',
        xp: 80,
        visited: false,
        isEditorPick: true,
      ),
      HeritageSite(
        id: 'george_town',
        name: 'George Town',
        location: 'Penang',
        description: 'UNESCO-listed colonial old town with street art & food',
        category: 'UNESCO',
        latitude: 5.4141,
        longitude: 100.3288,
        imageUrl: '',
        tags: ['UNESCO', 'Moderate'],
        duration: '3–4 hours',
        xp: 120,
        visited: false,
        isEditorPick: false,
      ),
      HeritageSite(
        id: 'malacca_city',
        name: 'Malacca City',
        location: 'Melaka',
        description: 'Historic trading port shaped by Portuguese, Dutch, and British rule',
        category: 'UNESCO',
        latitude: 2.1896,
        longitude: 102.2501,
        imageUrl: '',
        tags: ['UNESCO', 'Moderate'],
        duration: '3–4 hours',
        xp: 120,
        visited: false,
        isEditorPick: false,
      ),
      HeritageSite(
        id: 'merdeka_square',
        name: 'Dataran Merdeka',
        location: 'Kuala Lumpur',
        description: 'Historic square where Malaysia\'s independence was declared in 1957',
        category: 'National',
        latitude: 3.1478,
        longitude: 101.6953,
        imageUrl: '',
        tags: ['National', 'Easy'],
        duration: '1–2 hours',
        xp: 80,
        visited: true,
        isEditorPick: false,
      ),
      HeritageSite(
        id: 'kek_lok_si',
        name: 'Kek Lok Si Temple',
        location: 'Penang',
        description: 'Malaysia\'s largest Buddhist temple complex, built up a hillside in Air Itam',
        category: 'Religious',
        latitude: 5.3994,
        longitude: 100.2739,
        imageUrl: '',
        tags: ['Religious', 'Moderate'],
        duration: '2–3 hours',
        xp: 90,
        visited: false,
        isEditorPick: false,
      ),
      HeritageSite(
        id: 'cameron_highlands',
        name: 'Cameron Highlands',
        location: 'Pahang',
        description: 'A cool hill-station region of rolling tea plantations, strawberry farms, and mossy forest trails',
        category: 'Nature',
        latitude: 4.4696,
        longitude: 101.3808,
        imageUrl: '',
        tags: ['Nature', 'Moderate'],
        duration: '4–5 hours',
        xp: 100,
        visited: false,
        isEditorPick: false,
      ),
      HeritageSite(
        id: 'lenggong_valley',
        name: 'Lenggong Valley',
        location: 'Perak',
        description: 'UNESCO-listed archaeological valley where "Perak Man" was discovered',
        category: 'UNESCO',
        latitude: 5.1075,
        longitude: 100.9717,
        imageUrl: '',
        tags: ['UNESCO', 'Moderate'],
        duration: '3–4 hours',
        xp: 120,
        visited: false,
        isEditorPick: false,
      ),
      HeritageSite(
        id: 'crystal_mosque',
        name: 'Crystal Mosque',
        location: 'Terengganu',
        description: 'A steel-and-glass mosque on an island in the Terengganu River',
        category: 'Religious',
        latitude: 5.3390,
        longitude: 103.1360,
        imageUrl: '',
        tags: ['Religious', 'Easy'],
        duration: '1–2 hours',
        xp: 90,
        visited: false,
        isEditorPick: false,
      ),
      HeritageSite(
        id: 'taman_negara',
        name: 'Taman Negara',
        location: 'Pahang',
        description: 'Widely cited as one of the world\'s oldest rainforests',
        category: 'Nature',
        latitude: 4.3806,
        longitude: 102.4048,
        imageUrl: '',
        tags: ['Nature', 'Moderate'],
        duration: '3–4 hours',
        xp: 110,
        visited: false,
        isEditorPick: false,
      ),
    ];
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