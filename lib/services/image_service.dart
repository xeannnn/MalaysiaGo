import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Memory cache for the current app session.
  static final Map<String, List<String>> _cache = {};

  // Prevent several widgets from requesting the same site simultaneously.
  static final Map<String, Future<List<String>>> _pendingRequests = {};

  /// Backward-compatible method for screens that only need one image,
  /// such as the Heritage Explorer card.
  static Future<String> getHeritageImage(
    String name, {
    String? location,
    String? siteId,
    String? existingImageUrl,
  }) async {
    final images = await getHeritageImages(
      name,
      location: location,
      siteId: siteId,
      existingImageUrl: existingImageUrl,
      maxImages: 1,
    );

    return images.isNotEmpty ? images.first : '';
  }

  /// Returns multiple images for a heritage site.
  ///
  /// Priority:
  /// 1. Supabase image_urls if enough URLs are already stored.
  /// 2. Existing image_url is retained as a candidate.
  /// 3. Wikipedia lead image.
  /// 4. Wikimedia Commons results.
  /// 5. Best images are saved back to Supabase.
  static Future<List<String>> getHeritageImages(
    String name, {
    String? location,
    String? siteId,
    List<String>? existingImageUrls,
    String? existingImageUrl,
    int maxImages = 5,
  }) {
    final key = _cacheKey(name, location);

    final suppliedUrls = _cleanUrls([...?existingImageUrls, ?existingImageUrl]);

    // If Supabase already contains enough photos, do not call Wikimedia.
    if (suppliedUrls.length >= maxImages) {
      return Future.value(suppliedUrls.take(maxImages).toList());
    }

    final cached = _cache[key];
    if (cached != null && cached.length >= maxImages) {
      return Future.value(cached.take(maxImages).toList());
    }

    // Share an already-running request.
    final pending = _pendingRequests[key];
    if (pending != null) {
      return pending;
    }

    final request = _fetchImages(
      name,
      location: location,
      siteId: siteId,
      existingUrls: suppliedUrls,
      maxImages: maxImages,
    );

    _pendingRequests[key] = request;

    request.whenComplete(() {
      _pendingRequests.remove(key);
    });

    return request;
  }

  static Future<List<String>> _fetchImages(
    String name, {
    String? location,
    String? siteId,
    required List<String> existingUrls,
    required int maxImages,
  }) async {
    final key = _cacheKey(name, location);

    try {
      final candidates = <_ImageCandidate>[];

      // Keep already-stored images with a high score so they remain first,
      // unless the database was deliberately cleared.
      for (var i = 0; i < existingUrls.length; i++) {
        candidates.add(
          _ImageCandidate(
            url: existingUrls[i],
            title: 'Existing image ${i + 1}',
            score: 1000 - i,
          ),
        );
      }

      // Wikipedia lead image usually represents the landmark well.
      final wikipediaImage = await _getWikipediaMainImage(
        name,
        location: location,
        siteId: siteId,
      );

      if (wikipediaImage.isNotEmpty) {
        candidates.add(
          _ImageCandidate(
            url: wikipediaImage,
            title: 'Wikipedia lead image',
            score: 900,
          ),
        );
      }

      // Commons gives additional photos for the swipe gallery.
      final commonsCandidates = await _getCommonsImages(
        name,
        location: location,
        siteId: siteId,
      );

      candidates.addAll(commonsCandidates);

      // Sort best first, then remove duplicate URLs.
      candidates.sort((a, b) => b.score.compareTo(a.score));

      final selected = <String>[];
      final seen = <String>{};

      for (final candidate in candidates) {
        final normalized = _normalizeUrl(candidate.url);

        if (normalized.isEmpty || seen.contains(normalized)) {
          continue;
        }

        seen.add(normalized);
        selected.add(candidate.url);

        if (selected.length >= maxImages) {
          break;
        }
      }

      _cache[key] = selected;

      if (selected.isNotEmpty && siteId != null && siteId.trim().isNotEmpty) {
        await _saveImagesToSupabase(siteId: siteId.trim(), imageUrls: selected);
      }

      debugPrint(
        '[ImageService] ${selected.length} image(s) selected for $name',
      );

      return selected;
    } catch (e) {
      debugPrint('[ImageService] Error loading images for $name: $e');

      // Existing Supabase image(s) are still useful if Wikimedia failed.
      return existingUrls.take(maxImages).toList();
    }
  }

  // ============================================================
  // SEARCH QUERY ALIASES / FALLBACKS
  // ============================================================

  static List<String> _getSearchQueries(
    String name, {
    String? location,
    String? siteId,
  }) {
    final queries = <String>[];

    // Some database names are not the same as the names commonly used
    // by Wikipedia or Wikimedia Commons. Add aliases here when needed.
    switch (siteId) {
      case 'tarumt_kl':
        queries.addAll([
          'Tunku Abdul Rahman University of Management and Technology',
          'Tunku Abdul Rahman University College',
          'TAR UMT',
        ]);
        break;
    }

    final cleanName = name.trim();

    if (cleanName.isNotEmpty) {
      queries.add(cleanName);
    }

    if (location != null &&
        location.trim().isNotEmpty &&
        cleanName.isNotEmpty) {
      queries.add('$cleanName ${location.trim()}');
    }

    // Preserve insertion order while removing duplicates.
    final seen = <String>{};
    final result = <String>[];

    for (final query in queries) {
      final clean = query.trim();

      if (clean.isEmpty) {
        continue;
      }

      final key = clean.toLowerCase();

      if (seen.add(key)) {
        result.add(clean);
      }
    }

    return result;
  }

  // ============================================================
  // WIKIPEDIA MAIN / LEAD IMAGE
  // ============================================================

  static Future<String> _getWikipediaMainImage(
    String name, {
    String? location,
    String? siteId,
  }) async {
    try {
      final queries = _getSearchQueries(
        name,
        location: location,
        siteId: siteId,
      );

      for (final query in queries) {
        debugPrint('[ImageService] Wikipedia search: $query');

        final searchUrl = Uri.https('en.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'list': 'search',
          'srsearch': query,
          'srlimit': '5',
          'format': 'json',
          'origin': '*',
        });

        final searchResponse = await http.get(searchUrl, headers: _headers);

        if (searchResponse.statusCode == 429) {
          debugPrint('[ImageService] Wikipedia rate limit reached for $query');
          continue;
        }

        if (searchResponse.statusCode != 200) {
          debugPrint(
            '[ImageService] Wikipedia search failed '
            '(${searchResponse.statusCode}) for $query',
          );
          continue;
        }

        final searchData = json.decode(searchResponse.body);
        final results = searchData['query']?['search'];

        if (results is! List || results.isEmpty) {
          continue;
        }

        String? articleTitle;
        final lowerQuery = query.toLowerCase();

        // Prefer an article whose title closely matches the current query.
        for (final result in results) {
          final title = result['title']?.toString() ?? '';
          final lowerTitle = title.toLowerCase();

          if (lowerTitle == lowerQuery ||
              lowerTitle.contains(lowerQuery) ||
              lowerQuery.contains(lowerTitle)) {
            articleTitle = title;
            break;
          }
        }

        articleTitle ??= results.first['title']?.toString();

        if (articleTitle == null || articleTitle.isEmpty) {
          continue;
        }

        debugPrint('[ImageService] Wikipedia article selected: $articleTitle');

        final imageUrl = Uri.https('en.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'titles': articleTitle,
          'prop': 'pageimages',
          'pithumbsize': '1200',
          'pilicense': 'any',
          'format': 'json',
          'origin': '*',
        });

        final imageResponse = await http.get(imageUrl, headers: _headers);

        if (imageResponse.statusCode != 200) {
          continue;
        }

        final imageData = json.decode(imageResponse.body);
        final pages = imageData['query']?['pages'];

        if (pages is! Map || pages.isEmpty) {
          continue;
        }

        final page = pages.values.first;
        final image = page['thumbnail']?['source']?.toString() ?? '';

        if (image.isNotEmpty) {
          debugPrint('[ImageService] Wikipedia image found for $name');
          return image;
        }
      }

      debugPrint('[ImageService] No Wikipedia image found for $name');

      return '';
    } catch (e) {
      debugPrint('[ImageService] Wikipedia error for $name: $e');
      return '';
    }
  }

  // ============================================================
  // WIKIMEDIA COMMONS GALLERY IMAGES
  // ============================================================

  static Future<List<_ImageCandidate>> _getCommonsImages(
    String name, {
    String? location,
    String? siteId,
  }) async {
    try {
      final queries = _getSearchQueries(
        name,
        location: location,
        siteId: siteId,
      );

      final allCandidates = <_ImageCandidate>[];
      final seenUrls = <String>{};

      for (final query in queries) {
        debugPrint('[ImageService] Commons search: $query');

        final url = Uri.https('commons.wikimedia.org', '/w/api.php', {
          'action': 'query',
          'generator': 'search',
          'gsrsearch': query,
          'gsrnamespace': '6',
          'gsrlimit': '20',
          'prop': 'imageinfo',
          'iiprop': 'url|size|mime',
          'iiurlwidth': '1200',
          'format': 'json',
          'origin': '*',
        });

        final response = await http.get(url, headers: _headers);

        if (response.statusCode == 429) {
          debugPrint('[ImageService] Wikimedia rate limit reached for $query');
          continue;
        }

        if (response.statusCode != 200) {
          debugPrint(
            '[ImageService] Commons search failed '
            '(${response.statusCode}) for $query',
          );
          continue;
        }

        final data = json.decode(response.body);
        final pages = data['query']?['pages'];

        if (pages is! Map || pages.isEmpty) {
          continue;
        }

        for (final page in pages.values) {
          final title = page['title']?.toString() ?? '';
          final infoList = page['imageinfo'];

          if (infoList is! List || infoList.isEmpty) {
            continue;
          }

          final info = infoList.first;

          final imageUrl =
              info['thumburl']?.toString() ?? info['url']?.toString() ?? '';

          if (imageUrl.isEmpty) {
            continue;
          }

          final normalizedUrl = _normalizeUrl(imageUrl);

          if (!seenUrls.add(normalizedUrl)) {
            continue;
          }

          final width = _parseInt(info['thumbwidth'] ?? info['width']);

          final height = _parseInt(info['thumbheight'] ?? info['height']);

          final mime = info['mime']?.toString().toLowerCase() ?? '';

          final score = _scoreImage(
            title: title,
            siteName: name,
            location: location,
            width: width,
            height: height,
            mime: mime,
          );

          // Discard very poor candidates entirely.
          if (score <= -50) {
            continue;
          }

          allCandidates.add(
            _ImageCandidate(url: imageUrl, title: title, score: score),
          );
        }

        // Avoid unnecessary extra Wikimedia calls once enough useful
        // candidates are available for the gallery.
        if (allCandidates.length >= 5) {
          break;
        }
      }

      debugPrint(
        '[ImageService] ${allCandidates.length} '
        'Commons candidate(s) found for $name',
      );

      return allCandidates;
    } catch (e) {
      debugPrint('[ImageService] Commons error for $name: $e');
      return [];
    }
  }

  // ============================================================
  // IMAGE RANKING
  // ============================================================

  static int _scoreImage({
    required String title,
    required String siteName,
    required int width,
    required int height,
    required String mime,
    String? location,
  }) {
    var score = 0;

    final lowerTitle = title.toLowerCase();
    final lowerName = siteName.toLowerCase();
    final lowerLocation = location?.toLowerCase() ?? '';

    const goodWords = [
      'exterior',
      'building',
      'architecture',
      'panorama',
      'panoramic',
      'front',
      'facade',
      'complex',
      'temple',
      'mosque',
      'tower',
      'palace',
      'fort',
      'church',
      'monument',
      'landmark',
      'view',
      'square',
    ];

    const badWords = [
      'monkey',
      'macaque',
      'animal',
      'tourist',
      'person',
      'people',
      'selfie',
      'portrait',
      'food',
      'shop',
      'souvenir',
      'sign',
      'signboard',
      'interior',
      'inside',
      'close-up',
      'closeup',
      'detail',
      'face',
    ];

    final nameWords = lowerName
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2);

    for (final word in nameWords) {
      if (lowerTitle.contains(word)) {
        score += 6;
      }
    }

    if (lowerTitle.contains(lowerName)) {
      score += 25;
    }

    if (lowerLocation.isNotEmpty) {
      final locationWords = lowerLocation
          .split(RegExp(r'\s+'))
          .where((word) => word.length > 2);

      for (final word in locationWords) {
        if (lowerTitle.contains(word)) {
          score += 4;
        }
      }
    }

    for (final word in goodWords) {
      if (lowerTitle.contains(word)) {
        score += 10;
      }
    }

    for (final word in badWords) {
      if (lowerTitle.contains(word)) {
        score -= 100;
      }
    }

    if (width > 0 && height > 0) {
      final ratio = width / height;

      if (ratio >= 1.30) {
        score += 20;
      } else if (ratio >= 1.0) {
        score += 8;
      } else {
        score -= 10;
      }
    }

    if (mime == 'image/jpeg') {
      score += 3;
    } else if (mime == 'image/png') {
      score += 1;
    } else if (mime == 'image/svg+xml') {
      score -= 30;
    }

    return score;
  }

  // ============================================================
  // SUPABASE CACHE
  // ============================================================

  static Future<void> _saveImagesToSupabase({
    required String siteId,
    required List<String> imageUrls,
  }) async {
    try {
      final response = await _supabase
          .from('heritage_sites')
          .update({
            // Keep image_url for old/existing UI code.
            'image_url': imageUrls.first,

            // New multiple-image field.
            'image_urls': imageUrls,
          })
          .eq('site_id', siteId)
          .select('site_id, image_url, image_urls');

      if (response.isEmpty) {
        debugPrint(
          '[ImageService] WARNING: Supabase update matched 0 rows for $siteId',
        );
        return;
      }

      debugPrint(
        '[ImageService] Saved ${imageUrls.length} image(s) '
        'to Supabase: $siteId',
      );
    } catch (e) {
      // Displaying the images should still work even if DB caching fails.
      debugPrint('[ImageService] Failed to save images for $siteId: $e');
    }
  }

  static Map<String, String> get _headers => const {
    'User-Agent': 'MalaysiaGo/1.0 Heritage Explorer Flutter Application',
    'Accept': 'application/json',
  };

  static String _cacheKey(String name, String? location) {
    return '${name.trim().toLowerCase()}|'
        '${location?.trim().toLowerCase() ?? ''}';
  }

  static List<String> _cleanUrls(List<String> values) {
    final result = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final url = value.trim();

      if (url.isEmpty) {
        continue;
      }

      final normalized = _normalizeUrl(url);

      if (seen.add(normalized)) {
        result.add(url);
      }
    }

    return result;
  }

  static String _normalizeUrl(String value) {
    final uri = Uri.tryParse(value.trim());

    if (uri == null) {
      return value.trim();
    }

    // Ignore tracking parameters when comparing duplicates.
    return uri.replace(query: '').toString();
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static void clearCache() {
    _cache.clear();
    _pendingRequests.clear();
  }
}

class _ImageCandidate {
  final String url;
  final String title;
  final int score;

  const _ImageCandidate({
    required this.url,
    required this.title,
    required this.score,
  });
}
