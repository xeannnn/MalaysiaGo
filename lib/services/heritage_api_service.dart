import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class HeritageApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Existing method: Fetch all sites
  static Future<List<HeritageSite>> fetchMalaysiaHeritage() async {
    try {
      final List<dynamic> response = await _supabase.from('heritage_sites').select();
      return _parseSites(response);
    } catch (e) {
      print('Error fetching sites: $e');
      return [];
    }
  }

  // NEW METHOD: Fetch nearby sites using the PostGIS RPC function
  static Future<List<HeritageSite>> fetchNearbyHeritage({
    required double userLat,
    required double userLng,
    double radiusInMeters = 10000, // Default 10 km
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

      return _parseSites(response);
    } catch (e) {
      print('Error fetching nearby sites via RPC: $e');
      return [];
    }
  }

  // Helper method to parse JSON list safely
  static List<HeritageSite> _parseSites(List<dynamic> response) {
    List<String> parseList(dynamic input) {
      if (input == null) return [];
      if (input is List) return input.map((e) => e.toString()).toList();
      return [];
    }

    return response.map((data) {
      return HeritageSite(
        id: data['site_id']?.toString() ?? data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? 'Unknown Heritage',
        location: data['location']?.toString() ?? data['state']?.toString() ?? 'Malaysia',
        description: data['description']?.toString() ?? '',
        category: data['category']?.toString() ?? 'National',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
        imageUrl: data['image_url']?.toString() ?? data['imageUrl']?.toString() ?? '',
        tags: parseList(data['tags']),
        duration: data['duration']?.toString() ?? '1-2 hours',
        xp: (data['xp'] as num?)?.toInt() ?? 50,
        visited: data['visited'] as bool? ?? false,
        isEditorPick: (data['is_editor_pick'] ?? data['isEditorPick']) as bool? ?? false,
        openingHours: data['opening_hours']?.toString() ?? data['openingHours']?.toString() ?? 'Unknown',
        entryFee: data['entry_fee']?.toString() ?? data['entryFee']?.toString() ?? 'Free',
        difficulty: data['difficulty']?.toString() ?? 'Easy',
        bestTime: data['best_time']?.toString() ?? data['bestTime']?.toString() ?? '',
        tips: parseList(data['tips']),
      );
    }).toList();
  }
}