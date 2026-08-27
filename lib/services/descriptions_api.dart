import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'tips_services.dart';

// ============================================================
// WIKIPEDIA API HELPER
// ============================================================

class WikipediaService {
  /// Fetches summary extract and thumbnail image from Wikipedia API safely
  static Future<Map<String, String?>> fetchSiteSummary(String siteTitle) async {
    final String cleanTitle = siteTitle.trim();

    final Uri url = Uri.parse(
      'https://en.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&exintro=1&explaintext=1&titles=${Uri.encodeComponent(cleanTitle)}&pithumbsize=600&format=json&redirects=1',
    );

    try {
      final response = await http.get(
        url,
        headers: const {
          'User-Agent': 'FlutterApp_MalaysiaGo/1.0 (https://github.com/myflutterapp)',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        if (decodedData is Map<String, dynamic> && decodedData.containsKey('query')) {
          final pages = decodedData['query']['pages'] as Map<String, dynamic>?;
          if (pages != null && pages.isNotEmpty) {
            final pageId = pages.keys.first;
            if (pageId != '-1') {
              final pageData = pages[pageId] as Map<String, dynamic>;

              final String? extract = pageData['extract'] as String?;
              final String? imageUrl = pageData['thumbnail'] != null
                  ? pageData['thumbnail']['source'] as String?
                  : null;

              return {
                'title': pageData['title'] as String?,
                'description': extract,
                'imageUrl': imageUrl,
              };
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Wikipedia API error for "$siteTitle": $e');
    }

    return {
      'title': null,
      'description': null,
      'imageUrl': null,
    };
  }
}

// ============================================================
// HERITAGE API SERVICE (HYBRID OVERPASS + WIKIPEDIA + TIPS)
// ============================================================

class HeritageApiService {
  static const String _overpassUrl = "https://overpass-api.de/api/interpreter";

  /// Comprehensive list of curated fallback sites (20 sites across categories)
  static final List<HeritageSite> _baseSites = [
    // UNESCO
    HeritageSite(
      id: 'base_1',
      name: 'George Town, Penang',
      location: 'Penang',
      category: 'UNESCO',
      description: '',
      imageUrl: '',
      latitude: 5.4141,
      longitude: 100.3288,
      duration: '2–3 hours',
      xp: 250,
      visited: false,
      isEditorPick: true,
      tags: const ['UNESCO', 'History', 'Penang'],
      tips: const [],
      openingHours: 'Open 24 Hours',
      entryFee: 'Free Access',
    ),
    HeritageSite(
      id: 'base_2',
      name: 'Melaka Historic City',
      location: 'Melaka',
      category: 'UNESCO',
      description: '',
      imageUrl: '',
      latitude: 2.1944,
      longitude: 102.2491,
      duration: '2–3 hours',
      xp: 250,
      visited: false,
      isEditorPick: true,
      tags: const ['UNESCO', 'History', 'Melaka'],
      tips: const [],
      openingHours: 'Open 24 Hours',
      entryFee: 'Free Access',
    ),
    HeritageSite(
      id: 'base_3',
      name: 'Kinabalu Park',
      location: 'Sabah',
      category: 'UNESCO',
      description: '',
      imageUrl: '',
      latitude: 6.0333,
      longitude: 116.5500,
      duration: '3+ hours',
      xp: 300,
      visited: false,
      isEditorPick: false,
      tags: const ['UNESCO', 'Nature', 'Sabah'],
      tips: const [],
      openingHours: 'Daily 7:00 AM – 5:00 PM',
      entryFee: 'RM15 (Malaysian) / RM50 (Non-Malaysian)',
    ),
    HeritageSite(
      id: 'base_4',
      name: 'Gunung Mulu National Park',
      location: 'Sarawak',
      category: 'UNESCO',
      description: '',
      imageUrl: '',
      latitude: 4.0489,
      longitude: 114.8975,
      duration: '3+ hours',
      xp: 300,
      visited: false,
      isEditorPick: false,
      tags: const ['UNESCO', 'Nature', 'Sarawak'],
      tips: const [],
      openingHours: 'Daily 8:00 AM – 5:00 PM',
      entryFee: 'RM15 (Malaysian) / RM30 (Non-Malaysian)',
    ),
    HeritageSite(
      id: 'base_5',
      name: 'Lenggong Valley',
      location: 'Perak',
      category: 'UNESCO',
      description: '',
      imageUrl: '',
      latitude: 5.1052,
      longitude: 100.9678,
      duration: '2–3 hours',
      xp: 250,
      visited: false,
      isEditorPick: false,
      tags: const ['UNESCO', 'Archaeology', 'Perak'],
      tips: const [],
      openingHours: 'Daily 9:00 AM – 5:00 PM',
      entryFee: 'Free',
    ),

    // RELIGIOUS
    HeritageSite(
      id: 'base_6',
      name: 'Batu Caves',
      location: 'Selangor',
      category: 'Religious',
      description: '',
      imageUrl: '',
      latitude: 3.2379,
      longitude: 101.6840,
      duration: '1–2 hours',
      xp: 150,
      visited: false,
      isEditorPick: false,
      tags: const ['Religious', 'Cave', 'Selangor'],
      tips: const [],
      openingHours: 'Daily 6:00 AM – 9:00 PM',
      entryFee: 'Free',
    ),
    HeritageSite(
      id: 'base_7',
      name: 'Kek Lok Si Temple',
      location: 'Penang',
      category: 'Religious',
      description: '',
      imageUrl: '',
      latitude: 5.3996,
      longitude: 100.2737,
      duration: '1–2 hours',
      xp: 150,
      visited: false,
      isEditorPick: false,
      tags: const ['Religious', 'Temple', 'Penang'],
      tips: const [],
      openingHours: 'Daily 8:30 AM – 5:30 PM',
      entryFee: 'Free',
    ),
    HeritageSite(
      id: 'base_8',
      name: 'National Mosque of Malaysia',
      location: 'Kuala Lumpur',
      category: 'Religious',
      description: '',
      imageUrl: '',
      latitude: 3.1418,
      longitude: 101.6917,
      duration: '1 hour',
      xp: 150,
      visited: false,
      isEditorPick: false,
      tags: const ['Religious', 'Mosque', 'Kuala Lumpur'],
      tips: const [],
      openingHours: 'Daily 9:00 AM – 6:00 PM',
      entryFee: 'Free',
    ),
    HeritageSite(
      id: 'base_9',
      name: 'Christ Church, Malacca',
      location: 'Melaka',
      category: 'Religious',
      description: '',
      imageUrl: '',
      latitude: 2.1942,
      longitude: 102.2493,
      duration: '1 hour',
      xp: 150,
      visited: false,
      isEditorPick: false,
      tags: const ['Religious', 'Church', 'Melaka'],
      tips: const [],
      openingHours: 'Daily 9:00 AM – 5:00 PM',
      entryFee: 'Free',
    ),
    HeritageSite(
      id: 'base_10',
      name: 'Sri Mahamariamman Temple, Kuala Lumpur',
      location: 'Kuala Lumpur',
      category: 'Religious',
      description: '',
      imageUrl: '',
      latitude: 3.1447,
      longitude: 101.6964,
      duration: '1 hour',
      xp: 150,
      visited: false,
      isEditorPick: false,
      tags: const ['Religious', 'Temple', 'Kuala Lumpur'],
      tips: const [],
      openingHours: 'Daily 6:00 AM – 8:30 PM',
      entryFee: 'Free',
    ),

    // NATIONAL
    HeritageSite(
      id: 'base_11',
      name: 'Sultan Abdul Samad Building',
      location: 'Kuala Lumpur',
      category: 'National',
      description: '',
      imageUrl: '',
      latitude: 3.1486,
      longitude: 101.6944,
      duration: '1 hour',
      xp: 100,
      visited: false,
      isEditorPick: false,
      tags: const ['National', 'Architecture', 'Kuala Lumpur'],
      tips: const [],
      openingHours: 'Exterior Viewable 24 Hours',
      entryFee: 'Free',
    ),
    HeritageSite(
      id: 'base_12',
      name: 'Kellie\'s Castle',
      location: 'Perak',
      category: 'National',
      description: '',
      imageUrl: '',
      latitude: 4.4746,
      longitude: 101.0877,
      duration: '1–2 hours',
      xp: 100,
      visited: false,
      isEditorPick: false,
      tags: const ['National', 'Castle', 'Perak'],
      tips: const [],
      openingHours: 'Daily 9:00 AM – 6:00 PM',
      entryFee: 'RM5 (Malaysian) / RM10 (Non-Malaysian)',
    ),
    HeritageSite(
      id: 'base_13',
      name: 'A Famosa',
      location: 'Melaka',
      category: 'National',
      description: '',
      imageUrl: '',
      latitude: 2.1917,
      longitude: 102.2504,
      duration: '1 hour',
      xp: 100,
      visited: false,
      isEditorPick: false,
      tags: const ['National', 'Fort', 'Melaka'],
      tips: const [],
      openingHours: 'Open 24 Hours',
      entryFee: 'Free',
    ),
    HeritageSite(
      id: 'base_14',
      name: 'Fort Cornwallis',
      location: 'Penang',
      category: 'National',
      description: '',
      imageUrl: '',
      latitude: 5.4203,
      longitude: 100.3440,
      duration: '1 hour',
      xp: 100,
      visited: false,
      isEditorPick: false,
      tags: const ['National', 'Fort', 'Penang'],
      tips: const [],
      openingHours: 'Daily 8:00 AM – 10:00 PM',
      entryFee: 'RM10 (Malaysian) / RM20 (Non-Malaysian)',
    ),
    HeritageSite(
      id: 'base_15',
      name: 'Victoria Bridge, Malaysia',
      location: 'Perak',
      category: 'National',
      description: '',
      imageUrl: '',
      latitude: 4.8375,
      longitude: 100.9634,
      duration: '1 hour',
      xp: 100,
      visited: false,
      isEditorPick: false,
      tags: const ['National', 'Bridge', 'Perak'],
      tips: const [],
      openingHours: 'Open 24 Hours',
      entryFee: 'Free',
    ),

    // NATURE
    HeritageSite(
      id: 'base_16',
      name: 'Taman Negara',
      location: 'Pahang',
      category: 'Nature',
      description: '',
      imageUrl: '',
      latitude: 4.3833,
      longitude: 102.4000,
      duration: '3+ hours',
      xp: 200,
      visited: false,
      isEditorPick: false,
      tags: const ['Nature', 'Rainforest', 'Pahang'],
      tips: const [],
      openingHours: 'Daily 7:30 AM – 6:00 PM',
      entryFee: 'RM1 Entry Permit',
    ),
    HeritageSite(
      id: 'base_17',
      name: 'Royal Belum State Park',
      location: 'Perak',
      category: 'Nature',
      description: '',
      imageUrl: '',
      latitude: 5.5393,
      longitude: 101.3442,
      duration: '3+ hours',
      xp: 200,
      visited: false,
      isEditorPick: false,
      tags: const ['Nature', 'Park', 'Perak'],
      tips: const [],
      openingHours: 'Daily 8:00 AM – 5:00 PM',
      entryFee: 'Permit Required (RM15)',
    ),
    HeritageSite(
      id: 'base_18',
      name: 'Forest Research Institute Malaysia',
      location: 'Selangor',
      category: 'Nature',
      description: '',
      imageUrl: '',
      latitude: 3.2361,
      longitude: 101.6344,
      duration: '2 hours',
      xp: 150,
      visited: false,
      isEditorPick: false,
      tags: const ['Nature', 'Forest', 'Selangor'],
      tips: const [],
      openingHours: 'Tue–Sun 7:30 AM – 7:00 PM',
      entryFee: 'RM5',
    ),
    HeritageSite(
      id: 'base_19',
      name: 'Endau-Rompin National Park',
      location: 'Johor',
      category: 'Nature',
      description: '',
      imageUrl: '',
      latitude: 2.5283,
      longitude: 103.3283,
      duration: '3+ hours',
      xp: 200,
      visited: false,
      isEditorPick: false,
      tags: const ['Nature', 'Park', 'Johor'],
      tips: const [],
      openingHours: 'Daily 8:00 AM – 5:00 PM',
      entryFee: 'RM10 Entry Permit',
    ),
    HeritageSite(
      id: 'base_20',
      name: 'Niah National Park',
      location: 'Sarawak',
      category: 'Nature',
      description: '',
      imageUrl: '',
      latitude: 3.8167,
      longitude: 113.7833,
      duration: '3+ hours',
      xp: 200,
      visited: false,
      isEditorPick: false,
      tags: const ['Nature', 'Cave', 'Sarawak'],
      tips: const [],
      openingHours: 'Daily 8:00 AM – 5:00 PM',
      entryFee: 'RM10 (Malaysian) / RM20 (Non-Malaysian)',
    ),
  ];

  /// Initial load: Fetches live OSM nodes or falls back to curated Wikipedia sites
  static Future<List<HeritageSite>> fetchMalaysiaHeritage() async {
    try {
      const query = """
[out:json][timeout:15];
area["ISO3166-1"="MY"]->.searchArea;
(
  node["historic"](area.searchArea);
  way["historic"](area.searchArea);
  node["heritage"](area.searchArea);
  way["heritage"](area.searchArea);
);
out center 40;
""";

      final sitesFromOSM = await _fetchFromOverpass(query);
      if (sitesFromOSM.isNotEmpty) {
        return sitesFromOSM;
      }
    } catch (e) {
      debugPrint('Overpass API error, using static fallback: $e');
    }

    // Fallback: Fetch Wikipedia entries for predefined base sites in parallel
    return await _fetchFallbackSites();
  }

  /// Keyword Search through Overpass API
  static Future<List<HeritageSite>> searchHeritage(String keyword) async {
    if (keyword.trim().isEmpty) {
      return fetchMalaysiaHeritage();
    }

    final safeKeyword = RegExp.escape(keyword);
    final query = """
[out:json][timeout:15];
area["ISO3166-1"="MY"]->.searchArea;
(
  node["name"~"$safeKeyword",i](area.searchArea);
  way["name"~"$safeKeyword",i](area.searchArea);
);
out center 20;
""";

    try {
      final results = await _fetchFromOverpass(query);
      if (results.isNotEmpty) return results;
    } catch (e) {
      debugPrint('Search error: $e');
    }

    // Fallback search over static sites if Overpass fails
    final lowerQuery = keyword.toLowerCase();
    final matches = _baseSites.where((site) =>
    site.name.toLowerCase().contains(lowerQuery) ||
        site.location.toLowerCase().contains(lowerQuery) ||
        site.category.toLowerCase().contains(lowerQuery)).toList();

    return await _fetchFallbackSites(matches.isEmpty ? _baseSites : matches);
  }

  /// Concurrently enriches static base sites with Wikipedia summaries
  static Future<List<HeritageSite>> _fetchFallbackSites([List<HeritageSite>? targetSites]) async {
    final sitesToFetch = targetSites ?? _baseSites;

    return await Future.wait(
      sitesToFetch.map((site) async {
        final wikiData = await WikipediaService.fetchSiteSummary(site.name);

        final String description = (wikiData['description'] != null &&
            wikiData['description']!.isNotEmpty)
            ? wikiData['description']!
            : 'Explore ${site.name}, a prominent heritage landmark in Malaysia.';

        final String imageUrl = (wikiData['imageUrl'] != null &&
            wikiData['imageUrl']!.isNotEmpty)
            ? wikiData['imageUrl']!
            : site.imageUrl;

        final dynamicTips = TipsService.getTips(
          name: site.name,
          category: site.category,
        );

        return HeritageSite(
          id: site.id,
          name: site.name,
          location: site.location,
          category: site.category,
          description: description,
          imageUrl: imageUrl,
          latitude: site.latitude,
          longitude: site.longitude,
          duration: site.duration,
          xp: site.xp,
          visited: site.visited,
          isEditorPick: site.isEditorPick,
          tags: site.tags,
          tips: dynamicTips,
          openingHours: site.openingHours,
          entryFee: site.entryFee,
        );
      }),
    );
  }

  /// Internal helper to process raw Overpass responses safely
  static Future<List<HeritageSite>> _fetchFromOverpass(String query) async {
    final response = await http.post(
      Uri.parse(_overpassUrl),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
        "User-Agent": "MalaysiaGo/1.0.0 (contact@example.com)",
      },
      body: {"data": query},
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception("Failed to query Overpass API: HTTP ${response.statusCode}");
    }

    final jsonData = json.decode(response.body);
    final elements = (jsonData["elements"] as List?) ?? [];

    final validElements = elements.where((item) {
      final tags = item["tags"] ?? {};
      return tags["name"] != null && tags["name"].toString().trim().isNotEmpty;
    }).take(30).toList();

    if (validElements.isEmpty) return [];

    return Future.wait(
      validElements.map((item) async {
        final tags = (item["tags"] as Map<String, dynamic>?) ?? {};
        final String siteName = tags["name"] ?? "Unknown Heritage";

        double latitude = 0.0;
        double longitude = 0.0;

        if (item["lat"] != null && item["lon"] != null) {
          latitude = (item["lat"] as num).toDouble();
          longitude = (item["lon"] as num).toDouble();
        } else if (item["center"] != null) {
          latitude = (item["center"]["lat"] as num).toDouble();
          longitude = (item["center"]["lon"] as num).toDouble();
        }

        final category = _convertCategory(tags);

        String description = tags["description"] ?? "";
        String imageUrl = "";

        if (description.isEmpty) {
          final String? wikiTag = tags["wikipedia"] as String?;
          final wikiLookupTitle = (wikiTag != null && wikiTag.contains(':'))
              ? wikiTag.split(':')[1]
              : siteName;

          final wikiData =
          await WikipediaService.fetchSiteSummary(wikiLookupTitle);
          description = wikiData['description'] ??
              'Explore $siteName, a prominent heritage landmark in Malaysia.';
          imageUrl = wikiData['imageUrl'] ?? "";
        }

        final dynamicTips = TipsService.getTips(
          name: siteName,
          category: category,
        );

        String openingHours = tags["opening_hours"] ?? "";
        if (openingHours.isEmpty) {
          openingHours = (category == 'Religious')
              ? "Daily 6:00 AM – 9:00 PM"
              : "Daily 9:00 AM – 6:00 PM";
        }

        String entryFee = tags["charge"] ?? tags["fee"] ?? "";
        if (entryFee.isEmpty || entryFee == "no") {
          entryFee = "Free (Public Access)";
        } else if (entryFee == "yes") {
          entryFee = "Admission Fee Required";
        }

        final int xp =
        category == 'UNESCO' ? 250 : (category == 'Religious' ? 150 : 100);
        final bool isEditorPick =
            category == 'UNESCO' || siteName.contains('Melaka');

        return HeritageSite(
          id: (item["id"] ?? "").toString(),
          name: siteName,
          location: tags["addr:state"] ?? tags["addr:city"] ?? "Malaysia",
          description: description,
          category: category,
          latitude: latitude,
          longitude: longitude,
          imageUrl: imageUrl,
          tags: [category, 'Heritage'],
          duration: "1–2 hours",
          xp: xp,
          visited: false,
          isEditorPick: isEditorPick,
          tips: dynamicTips,
          openingHours: openingHours,
          entryFee: entryFee,
        );
      }),
    );
  }

  static String _convertCategory(Map<String, dynamic> tags) {
    if (tags["amenity"] == "place_of_worship") return "Religious";
    if (tags["tourism"] == "museum") return "National";
    if (tags["natural"] != null || tags["leisure"] == "park") return "Nature";
    if (tags["heritage"] != null) return "UNESCO";
    return "National";
  }
}