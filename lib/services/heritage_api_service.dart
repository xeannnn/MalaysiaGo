import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models.dart';

class HeritageApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static List<HeritageSite> _cachedSites = <HeritageSite>[];

  static void _cacheSites(
    Iterable<HeritageSite> sites, {
    bool replace = false,
  }) {
    final byId = <String, HeritageSite>{
      if (!replace)
        for (final site in _cachedSites) site.id: site,
      for (final site in sites) site.id: site,
    };
    _cachedSites = byId.values.toList(growable: false);
  }

  // Existing method: Fetch all sites
  static Future<List<HeritageSite>> fetchMalaysiaHeritage() async {
    try {
      final List<dynamic> response = await _supabase
          .from('heritage_sites')
          .select();
      final sites = _parseSites(response);
      if (sites.isNotEmpty) {
        _cacheSites(sites, replace: true);
      }
      return sites.isEmpty ? List<HeritageSite>.from(_cachedSites) : sites;
    } catch (e) {
      debugPrint('Error fetching sites: $e');
      return List<HeritageSite>.from(_cachedSites);
    }
  }

  // Fetch nearby sites using the PostGIS RPC function
  static Future<List<HeritageSite>> fetchNearbyHeritage({
    required double userLat,
    required double userLng,
    double radiusInMeters = 10000,
  }) async {
    try {
      final List<dynamic> response = await _supabase.rpc(
        'get_nearby_heritage_sites',
        params: {
          'user_lat': userLat,
          'user_lng': userLng,
          'radius_meters': radiusInMeters,
        },
      );

      final sites = _parseSites(response);
      if (sites.isNotEmpty) {
        _cacheSites(sites);
      }
      return sites;
    } catch (e) {
      debugPrint('Error fetching nearby sites via RPC: $e');
      return List<HeritageSite>.from(_cachedSites);
    }
  }

  // Helper method to parse JSON list safely
  static List<HeritageSite> _parseSites(List<dynamic> response) {
    List<String> parseList(dynamic input) {
      if (input == null) return [];
      if (input is List) return input.map((e) => e.toString()).toList();
      if (input is String && input.isNotEmpty) {
        try {
          final decoded = jsonDecode(input);
          if (decoded is List) {
            return decoded.map((item) => item.toString()).toList();
          }
        } catch (_) {
          return input
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      }
      return [];
    }

    double parseDouble(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    int parseInt(dynamic value, int fallback) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

    bool parseBool(dynamic value) =>
        value == true || value?.toString().toLowerCase() == 'true';

    return response
        .where((data) {
          // Supabase currently also contains the legacy alias `masjid_negara`
          // for the same National Mosque coordinates. Keep the canonical
          // `national_mosque` row so lists and map markers are not duplicated.
          return data['site_id']?.toString() != 'masjid_negara';
        })
        .map((data) {
          return HeritageSite(
            id: data['site_id']?.toString() ?? data['id']?.toString() ?? '',
            name: data['name']?.toString() ?? 'Unknown Heritage',
            location:
                data['location']?.toString() ??
                data['state']?.toString() ??
                'Malaysia',
            description: data['description']?.toString() ?? '',
            category: data['category']?.toString() ?? 'National',
            latitude: parseDouble(data['latitude']),
            longitude: parseDouble(data['longitude']),
            imageUrl:
                data['image_url']?.toString() ??
                data['imageUrl']?.toString() ??
                '',
            imageUrls: (() {
              final urls = parseList(data['image_urls']);
              final single =
                  data['image_url']?.toString() ??
                  data['imageUrl']?.toString() ??
                  '';

              if (urls.isEmpty && single.trim().isNotEmpty) {
                return <String>[single.trim()];
              }

              return urls;
            })(),
            tags: parseList(data['tags']),
            duration: data['duration']?.toString() ?? '1-2 hours',
            xp: parseInt(data['xp'], 50),
            visited: parseBool(data['visited']),
            isEditorPick: parseBool(
              data['is_editor_pick'] ?? data['isEditorPick'],
            ),
            openingHours:
                data['opening_hours']?.toString() ??
                data['openingHours']?.toString() ??
                'Unknown',
            entryFee:
                data['entry_fee']?.toString() ??
                data['entryFee']?.toString() ??
                'Free',
            difficulty: data['difficulty']?.toString() ?? 'Easy',
            bestTime:
                data['best_time']?.toString() ??
                data['bestTime']?.toString() ??
                '',
            tips: parseList(data['tips']),
            history: data['history']?.toString() ?? '',
            address: data['address']?.toString() ?? '',
            establishedYear:
                data['established_year']?.toString() ??
                data['establishedYear']?.toString() ??
                '',
            significance: data['significance']?.toString() ?? '',
          );
        })
        .toList();
  }
}
