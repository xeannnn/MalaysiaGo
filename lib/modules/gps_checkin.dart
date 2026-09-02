import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models.dart';
import '../services/heritage_api_service.dart';

class GpsCheckInScreen extends StatefulWidget {
  const GpsCheckInScreen({super.key});

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

      // 3. Get immediate current location (prevents infinite loading on emulators)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).catchError((_) async {
        // Fallback to last known position if current position times out
        return await Geolocator.getLastKnownPosition() ??
            Position(
              longitude: 101.6953, // Default to Dataran Merdeka, KL
              latitude: 3.1478,
              timestamp: DateTime.now(),
              accuracy: 10.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
      });

      await _fetchSitesForPosition(position);

      // 4. Subscribe to live stream for continuous updates
      _positionStream = Geolocator.getPositionStream(
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
      // Query Supabase RPC or Fallback to all sites
      List<HeritageSite> sites = await HeritageApiService.fetchNearbyHeritage(
        userLat: pos.latitude,
        userLng: pos.longitude,
        radiusInMeters: 10000, // 10 km
      );

      // Fallback: If RPC yields no items or fails, fetch all and filter in Flutter
      if (sites.isEmpty) {
        final allSites = await HeritageApiService.fetchMalaysiaHeritage();
        sites = allSites.where((site) {
          double dist = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            site.latitude,
            site.longitude,
          ) /
              1000.0;
          return dist <= 10.0; // 10 km
        }).toList();
      }

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
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      site.latitude,
      site.longitude,
    ) /
        1000.0;
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
              Text('Acquiring GPS location...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
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
                  const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _currentPosition != null
                        ? 'Live GPS · Accuracy ~${_currentPosition!.accuracy.toStringAsFixed(0)}m'
                        : 'Location Set',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'NEARBY HERITAGE SITES (WITHIN 10 KM)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),

            // Sites List
            Expanded(
              child: _nearbySites.isEmpty
                  ? const Center(
                child: Text('No heritage sites found within 10 km.'),
              )
                  : ListView.builder(
                itemCount: _nearbySites.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  final site = _nearbySites[index];
                  final distKm = _getDistanceKm(site);
                  final canCheckIn = distKm <= 0.1; // 100 meters

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  site.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${site.location} · ${distKm.toStringAsFixed(1)} km away',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canCheckIn ? const Color(0xFF16A34A) : Colors.grey[300],
                            ),
                            onPressed: canCheckIn ? () {} : null,
                            child: Text(
                              canCheckIn ? 'Check In' : 'Too Far',
                              style: TextStyle(color: canCheckIn ? Colors.white : Colors.black38),
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