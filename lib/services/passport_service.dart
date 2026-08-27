import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';

class PassportService {
  static const String _boxName = 'passport_collections';

  // Seed list using your existing HeritageSite model class
  static final List<HeritageSite> defaultSites = [
    HeritageSite(
      id: 'site_klcc',
      name: 'Petronas Twin Towers (KLCC)',
      location: 'Kuala Lumpur',
      description: 'Iconic landmark of modern Malaysia.',
      category: 'Landmark',
      latitude: 3.1579,
      longitude: 101.7116,
      imageUrl: '',
      tags: ['Towers'],
      duration: '1-2 hours',
      xp: 100,
      visited: false,
      isEditorPick: true,
    ),
    HeritageSite(
      id: 'site_pasar_seni',
      name: 'Central Market (Pasar Seni)',
      location: 'Kuala Lumpur',
      description: 'Cultural center for Malaysian arts and crafts.',
      category: 'Culture',
      latitude: 3.1425,
      longitude: 101.6955,
      imageUrl: '',
      tags: ['Arts'],
      duration: '1-2 hours',
      xp: 80,
      visited: false,
      isEditorPick: false,
    ),
    HeritageSite(
      id: 'site_taman_botanical',
      name: 'Perdana Botanical Garden',
      location: 'Kuala Lumpur',
      description: 'Heritage park located in the heart of the city.',
      category: 'Nature',
      latitude: 3.1486,
      longitude: 101.6860,
      imageUrl: '',
      tags: ['Park'],
      duration: '2 hours',
      xp: 60,
      visited: false,
      isEditorPick: false,
    ),
    HeritageSite(
      id: 'site_merdeka_square',
      name: 'Merdeka Square',
      location: 'Kuala Lumpur',
      description: 'Historic square where independence was declared.',
      category: 'National',
      latitude: 3.1480,
      longitude: 101.6937,
      imageUrl: '',
      tags: ['Independence'],
      duration: '1 hour',
      xp: 80,
      visited: false,
      isEditorPick: false,
    ),
  ];

  Future<Box<bool>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<bool>(_boxName);
    }
    return Hive.box<bool>(_boxName);
  }

  // Check if piece is collected locally
  Future<bool> isCollected(String siteId) async {
    final box = await _getBox();
    return box.get(siteId, defaultValue: false) ?? false;
  }

  // Record collected piece locally (offline-first)
  Future<bool> collectPiece(String siteId) async {
    final box = await _getBox();
    if (box.get(siteId, defaultValue: false) == true) {
      return false; // Already collected
    }
    await box.put(siteId, true);
    return true;
  }

  // Calculate local progress percentage
  Future<Map<String, dynamic>> getProgressStats(List<HeritageSite> sites) async {
    int collectedCount = 0;
    for (final site in sites) {
      if (await isCollected(site.id)) {
        collectedCount++;
      }
    }
    return {
      'collected': collectedCount,
      'total': sites.length,
      'percentage': sites.isNotEmpty ? collectedCount / sites.length : 0.0,
    };
  }
}