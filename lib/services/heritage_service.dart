import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

class HeritageService {
  // Replace with your actual backend endpoint URL
  final String _baseUrl = 'https://api.example.com/heritage-sites';

  Future<List<HeritageSite>> fetchHeritageSites() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((data) => HeritageSite.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load heritage sites (Code: ${response.statusCode})');
      }
    } catch (e) {
      // Fallback sample data in case of network offline/testing
      return _getMockData();
    }
  }

  List<HeritageSite> _getMockData() {
    return [
      HeritageSite(
        id: '1',
        name: 'Kinabalu Park',
        state: 'Sabah',
        category: 'Natural',
        description: 'Inscribed as a World Heritage Site in 2000. Home to Mount Kinabalu with over 4,000 species of flora and fauna.',
        imageUrl: 'https://via.placeholder.com/400x200',
        rating: 4.9,
        unescoYear: '2000',
        locationCoordinates: '6.0753° N, 116.5592° E',
      ),
      HeritageSite(
        id: '2',
        name: 'Gunung Mulu National Park',
        state: 'Sarawak',
        category: 'Natural',
        description: 'Renowned for its karst formations, deep canyons, and massive cave networks including the Sarawak Chamber.',
        imageUrl: 'https://via.placeholder.com/400x200',
        rating: 4.9,
        unescoYear: '2000',
        locationCoordinates: '4.0489° N, 114.8988° E',
      ),
      HeritageSite(
        id: '3',
        name: 'Melaka and George Town',
        state: 'Melaka & Penang',
        category: 'Cultural',
        description: 'Historic cities of the Straits of Malacca showcasing 500 years of East and West cultural exchange.',
        imageUrl: 'https://via.placeholder.com/400x200',
        rating: 4.8,
        unescoYear: '2008',
        locationCoordinates: '5.4141° N, 100.3288° E',
      ),
      HeritageSite(
        id: '4',
        name: 'Lenggong Valley',
        state: 'Perak',
        category: 'Archaeological',
        description: 'Contains prehistoric cave sites uncovering ancient human activity dating back millions of years.',
        imageUrl: 'https://via.placeholder.com/400x200',
        rating: 4.6,
        unescoYear: '2012',
        locationCoordinates: '5.1052° N, 100.9678° E',
      ),
      HeritageSite(
        id: '5',
        name: 'Niah National Park Caves Complex',
        state: 'Sarawak',
        category: 'Archaeological',
        description: 'Recognized for prehistoric cave deposits and ancient modern human remains dating over 35,000 years old.',
        imageUrl: 'https://via.placeholder.com/400x200',
        rating: 4.7,
        unescoYear: '2024',
        locationCoordinates: '3.8167° N, 113.7833° E',
      ),
    ];
  }
}
