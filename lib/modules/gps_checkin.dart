import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/achievement_provider.dart';
import '../widgets/app_header.dart';

class GpsCheckInScreen extends StatefulWidget {
  final ValueChanged<int> onXpEarned;

  const GpsCheckInScreen({
    super.key,
    required this.onXpEarned,
  });

  @override
  State<GpsCheckInScreen> createState() => _GpsCheckInScreenState();
}

class _GpsCheckInScreenState extends State<GpsCheckInScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String _locationStatus = "Fetching real-time GPS location...";

  final List<HeritageSite> _allSites = [
    HeritageSite(
      id: 'site_1',
      name: 'Batu Caves',
      location: 'Selangor',
      description: 'Limestone hill with cave temples',
      category: 'National',
      latitude: 3.237293,
      longitude: 101.683684,
      imageUrl: '',
      tags: ['Temple', 'Cave'],
      duration: '1–2 hours',
      xp: 80,
      visited: false,
      isEditorPick: true,
    ),
    HeritageSite(
      id: 'site_2',
      name: 'Merdeka Square',
      location: 'Kuala Lumpur',
      description: 'Historical square where Malayan independence was declared',
      category: 'National',
      latitude: 3.147860,
      longitude: 101.693775,
      imageUrl: '',
      tags: ['History', 'Square'],
      duration: '1 hour',
      xp: 60,
      visited: false,
      isEditorPick: false,
    ),
    HeritageSite(
      id: 'site_3',
      name: 'Sultan Abdul Samad Building',
      location: 'Kuala Lumpur',
      description: '19th-century building housed government offices',
      category: 'National',
      latitude: 3.148600,
      longitude: 101.694400,
      imageUrl: '',
      tags: ['Architecture', 'History'],
      duration: '1 hour',
      xp: 70,
      visited: false,
      isEditorPick: true,
    ),
    HeritageSite(
      id: 'site_4',
      name: 'Jamek Mosque',
      location: 'Kuala Lumpur',
      description: 'One of the oldest mosques in Kuala Lumpur',
      category: 'National',
      latitude: 3.149300,
      longitude: 101.695800,
      imageUrl: '',
      tags: ['Culture', 'Mosque'],
      duration: '1 hour',
      xp: 75,
      visited: false,
      isEditorPick: true,
    ),
    HeritageSite(
      id: 'site_5',
      name: 'George Town',
      location: 'Penang',
      description: 'UNESCO World Heritage Site with rich history',
      category: 'UNESCO',
      latitude: 5.414130,
      longitude: 100.328750,
      imageUrl: '',
      tags: ['UNESCO', 'Culture'],
      duration: '2–3 hours',
      xp: 100,
      visited: false,
      isEditorPick: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition();
    });
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _locationStatus = "Location services are turned off.";
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _locationStatus = "Location permissions denied.";
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _locationStatus = "Location permissions permanently denied.";
          });
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
          _locationStatus = position != null
              ? "GPS Active • Live position tracked"
              : "GPS signal weak. Set coordinates in emulator controls.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _locationStatus = "Unable to retrieve GPS location.";
        });
      }
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return double.infinity;
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
    return distanceInMeters / 1000;
  }

  String _getBadgeIdForLocation(String location) {
    final loc = location.toLowerCase();
    if (loc.contains('kuala lumpur') || loc.contains('kl')) return 'badge_kl';
    if (loc.contains('selangor')) return 'badge_selangor';
    if (loc.contains('melaka') || loc.contains('malacca')) return 'badge_melaka';
    if (loc.contains('penang')) return 'badge_penang';
    if (loc.contains('sarawak')) return 'badge_sarawak';
    if (loc.contains('sabah')) return 'badge_sabah';
    if (loc.contains('perak')) return 'badge_perak';
    return 'badge_kl';
  }

  bool _checkIsVisited(Map<String, List<String>> visitedSites, String siteId) {
    for (var list in visitedSites.values) {
      if (list.contains(siteId)) return true;
    }
    return false;
  }

  void _handleCheckIn(HeritageSite site) {
    final provider = Provider.of<AchievementProvider>(context, listen: false);
    final badgeId = _getBadgeIdForLocation(site.location);

    // Save to Hive persistence via Provider
    provider.addSiteVisit(badgeId, site.id);

    // Pass XP reward to parent
    widget.onXpEarned(site.xp);

    // Show check-in feedback snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎉 Checked in at ${site.name}! +${site.xp} XP earned!"),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AchievementProvider>(context);

    // Filter sites within 15 km of current position
    List<HeritageSite> nearbySites = _allSites.where((site) {
      double dist = _calculateDistance(site.latitude, site.longitude);
      return dist <= 15.0;
    }).toList();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          AppHeader(
            title: 'GPS Check-In',
            subtitle: 'Visit heritage sites nearby to unlock badges',
            xp: '${provider.totalXp}',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F8A5F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'NEARBY HERITAGE SITES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  _isLoading
                      ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : nearbySites.isEmpty
                      ? const Expanded(
                    child: Center(
                      child: Text(
                        'No heritage sites found within range.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                      : Expanded(
                    child: ListView.builder(
                      itemCount: nearbySites.length,
                      itemBuilder: (context, index) {
                        final site = nearbySites[index];
                        double dist = _calculateDistance(
                          site.latitude,
                          site.longitude,
                        );
                        bool canCheckIn = dist <= 5.0;
                        bool isAlreadyVisited = _checkIsVisited(
                          provider.visitedSites,
                          site.id,
                        );

                        return Card(
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAlreadyVisited
                                  ? const Color(0xFFE9F9EF)
                                  : Colors.grey.withOpacity(0.1),
                              child: Icon(
                                isAlreadyVisited
                                    ? Icons.check_circle
                                    : Icons.account_balance,
                                color: isAlreadyVisited
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF0F8A5F),
                              ),
                            ),
                            title: Text(
                              site.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '${site.location} • ${dist.toStringAsFixed(1)} km away',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: isAlreadyVisited
                                ? const Chip(
                              label: Text(
                                'Visited',
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              backgroundColor: Color(0xFFE9F9EF),
                            )
                                : ElevatedButton(
                              onPressed: canCheckIn
                                  ? () => _handleCheckIn(site)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F8A5F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                '+${site.xp} XP',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
