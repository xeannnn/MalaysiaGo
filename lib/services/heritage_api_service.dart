import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';


class HeritageApiService {

  static final SupabaseClient _supabase =
      Supabase.instance.client;


  static Future<List<HeritageSite>> fetchMalaysiaHeritage() async {

    final List<dynamic> response =
    await _supabase
        .from('heritage_sites')
        .select();


    return response.map((data) {

      return HeritageSite(

        id:
        data['site_id']?.toString() ??
            data['id'].toString(),


        name:
        data['name']?.toString() ??
            'Unknown Heritage',


        location:
        data['location']?.toString() ??
            'Malaysia',


        description:
        data['description']?.toString() ??
            '',


        category:
        data['category']?.toString() ??
            'National',


        latitude:
        (data['latitude'] as num?)
            ?.toDouble() ??
            0,


        longitude:
        (data['longitude'] as num?)
            ?.toDouble() ??
            0,


        imageUrl:
        data['image_url']?.toString() ??
            '',


        tags:
        List<String>.from(
          data['tags'] ?? [],
        ),


        duration:
        data['duration']?.toString() ??
            '1-2 hours',


        xp:
        (data['xp'] as num?)
            ?.toInt() ??
            50,


        visited:
        data['visited'] as bool? ??
            false,


        isEditorPick:
        data['is_editor_pick'] as bool? ??
            false,


        openingHours:
        data['opening_hours']?.toString() ?? 'Unknown',

        entryFee:
        data['entry_fee']?.toString() ?? 'Free',

        difficulty:
        data['difficulty']?.toString() ?? 'Easy',

        bestTime:
        data['best_time']?.toString() ?? '',

        tips:
        List<String>.from(
          data['tips'] ?? [],
        ),
      );

    }).toList();

  }

}