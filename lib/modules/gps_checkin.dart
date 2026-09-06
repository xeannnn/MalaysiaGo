import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/achievement_provider.dart';
import '../services/heritage_api_service.dart';
import 'mappage.dart';

class GpsCheckInScreen extends StatefulWidget {
  final ValueChanged<String> onSiteSelected;

  const GpsCheckInScreen({super.key, required this.onSiteSelected});

  @override
  State<GpsCheckInScreen> createState() => _GpsCheckInScreenState();
}

class _GpsCheckInScreenState extends State<GpsCheckInScreen> {
  Position? _currentPosition;
  List<HeritageSite> _nearbySites = [];
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationAndFetch() async {
    try {
      // 1. Check Location Services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Location services are disabled.';
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Location permissions are denied.';
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Location permissions are permanently denied.';
            _isLoading = false;
          });
        }
        return;
      }

      // Only a fresh device reading is safe for a physical check-in.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      await _fetchSitesForPosition(position);

      // 4. Subscribe to live stream for continuous updates
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (Position newPos) => _fetchSitesForPosition(newPos),
            onError: (e) => debugPrint('GPS Stream Error: $e'),
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing GPS: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSitesForPosition(Position pos) async {
    try {
      var sites = await HeritageApiService.fetchNearbyHeritage(
        userLat: pos.latitude,
        userLng: pos.longitude,
        radiusInMeters: 10000, // 10 km
      );

      // Fall back to all remote sites, then to the bundled map catalogue.
      if (sites.isEmpty) {
        sites = await HeritageApiService.fetchMalaysiaHeritage();
      }
      if (sites.isEmpty) {
        sites = heritageMapSites.map((site) => site.toHeritageSite()).toList();
      }

      final supportedSiteIds = heritageMapSites.map((site) => site.id).toSet();
      final sitesById = <String, HeritageSite>{
        for (final site in heritageMapSites) site.id: site.toHeritageSite(),
      };
      for (final site in sites) {
        if (supportedSiteIds.contains(site.id) &&
            site.latitude != 0 &&
            site.longitude != 0) {
          sitesById[site.id] = site;
        }
      }
      sites =
          sitesById.values
              .where((site) => _distanceKm(pos, site) <= 10)
              .toList()
            ..sort(
              (a, b) => _distanceKm(pos, a).compareTo(_distanceKm(pos, b)),
            );

      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _nearbySites = sites;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sites: $e');
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLoading = false;
        });
      }
    }
  }

  double _getDistanceKm(HeritageSite site) {
    if (_currentPosition == null) return 0.0;
    return _distanceKm(_currentPosition!, site);
  }

  double _distanceKm(Position position, HeritageSite site) {
    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          site.latitude,
          site.longitude,
        ) /
        1000.0;
  }

  void _checkIn(HeritageSite site) {
    final provider = context.read<AchievementProvider>();

    final bool alreadyVisited =
    provider.visitedHeritageSiteIds.contains(site.id);

    if (!alreadyVisited) {
      provider.addHeritageVisit(
        site.id,
        site.location,
        site.xp,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-in successful! +${site.xp} XP',
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }

    widget.onSiteSelected(site.id);
  }

  void _retry() {
    _positionStream?.cancel();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _nearbySites = [];
    });
    _initLocationAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('GPS Check-In'),
        backgroundColor: const Color(0xFF0F8A5F),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0F8A5F)),
                    SizedBox(height: 12),
                    Text(
                      'Acquiring GPS location...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F8A5F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _currentPosition != null
                              ? 'Live GPS · Accuracy ~${_currentPosition!.accuracy.toStringAsFixed(0)}m'
                              : 'Location Set',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'NEARBY HERITAGE SITES (WITHIN 10 KM)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // Sites List
                  Expanded(
                    child: _nearbySites.isEmpty
                        ? const Center(
                            child: Text(
                              'No heritage sites found within 10 km.',
                            ),
                          )
                        : ListView.builder(
                            itemCount: _nearbySites.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemBuilder: (context, index) {
                              final site = _nearbySites[index];
                              final distKm = _getDistanceKm(site);
                              final canCheckIn =
                                  distKm <= 0.25 &&
                                  (_currentPosition?.accuracy ??
                                          double.infinity) <=
                                      150;
                              final checkedIn = context
                                  .watch<AchievementProvider>()
                                  .visitedHeritageSiteIds
                                  .contains(site.id);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              site.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${site.location} · ${distKm.toStringAsFixed(1)} km away',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: canCheckIn
                                              ? const Color(0xFF16A34A)
                                              : Colors.grey[300],
                                        ),
                                        onPressed: canCheckIn
                                            ? () => _checkIn(site)
                                            : null,
                                        child: Text(
                                          canCheckIn
                                              ? checkedIn
                                                    ? 'View Site'
                                                    : 'Check In'
                                              : 'Too Far',
                                          style: TextStyle(
                                            color: canCheckIn
                                                ? Colors.white
                                                : Colors.black38,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
