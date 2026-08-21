import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models.dart';
import 'image_service.dart';

class HeritageApiService {
  static const String _url =
      "https://overpass-api.de/api/interpreter";

  // Initial loading
  static Future<List<HeritageSite>> fetchMalaysiaHeritage() async {
    const query = """
[out:json][timeout:60];

area["ISO3166-1"="MY"]->.searchArea;

(
  node["historic"](area.searchArea);
  way["historic"](area.searchArea);
);

out center;
""";

    return _fetchData(query);
  }

  // Search
  static Future<List<HeritageSite>> searchHeritage(
      String keyword) async {
    final safeKeyword = RegExp.escape(keyword);

    final query = """
[out:json][timeout:25];

area["ISO3166-1"="MY"]->.searchArea;

(
  node["name"~"$safeKeyword",i](area.searchArea);
  way["name"~"$safeKeyword",i](area.searchArea);
);

out center;
""";

    return _fetchData(query);
  }

  static Future<List<HeritageSite>> _fetchData(
      String query) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        "Content-Type":
        "application/x-www-form-urlencoded",
        "Accept": "application/json",
        "User-Agent": "MalaysiaGo Flutter App",
      },
      body: {
        "data": query,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load heritage data",
      );
    }

    final jsonData =
    json.decode(response.body);

    final elements =
    jsonData["elements"] as List;

    return Future.wait(
      elements
          .where((item) {
        final tags =
            item["tags"] ?? {};

        return tags["name"] != null;
      })
          .map((item) async {
        final tags =
            item["tags"] ?? {};

        double latitude = 0;
        double longitude = 0;

        if (item["lat"] != null &&
            item["lon"] != null) {
          latitude =
              (item["lat"] as num)
                  .toDouble();

          longitude =
              (item["lon"] as num)
                  .toDouble();
        } else if (item["center"] !=
            null) {
          latitude =
              (item["center"]["lat"]
              as num)
                  .toDouble();

          longitude =
              (item["center"]["lon"]
              as num)
                  .toDouble();
        }

        final category =
        _convertCategory(tags);

        return HeritageSite(
          id: item["id"].toString(),
          name: tags["name"] ??
              "Unknown Heritage",
          location:
          tags["addr:state"] ??
              "Malaysia",
          description:
          tags["description"] ??
              "Heritage site in Malaysia",
          category: category,
          latitude: latitude,
          longitude: longitude,
          imageUrl:
          await ImageService
              .getHeritageImage(
            tags["name"] ?? "",
          ),
          tags: [category],
          duration: "1-2 hours",
          xp: 50,
          visited: false,
          isEditorPick: false,
        );
      }),
    );
  }

  static String _convertCategory(
      Map<String, dynamic> tags) {
    if (tags["amenity"] ==
        "place_of_worship") {
      return "Religious";
    }

    if (tags["tourism"] ==
        "museum") {
      return "National";
    }

    if (tags["natural"] != null ||
        tags["leisure"] == "park") {
      return "Nature";
    }

    if (tags["heritage"] != null) {
      return "UNESCO";
    }

    return "National";
  }
}