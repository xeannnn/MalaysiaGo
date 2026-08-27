import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/achievement_provider.dart';
import '../services/passport_service.dart';
import 'package:malaysiago/widgets/app_bottom_bar.dart';

class GPSCheckInScreen extends StatefulWidget {
  final HeritageSite? site;
  final Function(BottomTab)? onTabSelected; // Optional callback to switch tabs in MainScreen

  const GPSCheckInScreen({
    super.key,
    this.site,
    this.onTabSelected,
  });

  @override
  State<GPSCheckInScreen> createState() => _GPSCheckInScreenState();
}

class _GPSCheckInScreenState extends State<GPSCheckInScreen> {
  final PassportService _passportService = PassportService();

  final List<Map<String, dynamic>> _uiSites = [
    {
      'site': HeritageSite(
        id: 'site_batu_caves',
        name: 'Batu Caves',
        location: 'Selangor',
        description: 'Iconic limestone hill and Hindu shrine.',
        category: 'Landmark',
        latitude: 3.2379,
        longitude: 101.6840,
        imageUrl: '',
        tags: ['Temple'],
        duration: '1-2 hours',
        xp: 100,
        visited: true,
        isEditorPick: true,
      ),
      'icon': '⛩️',
      'distance': '0.3 km away',
    },
    {
      'site': HeritageSite(
        id: 'site_george_town',
        name: 'George Town',
        location: 'Penang',
        description: 'UNESCO World Heritage city.',
        category: 'Heritage',
        latitude: 5.4164,
        longitude: 100.3327,
        imageUrl: '',
        tags: ['UNESCO'],
        duration: 'Half day',
        xp: 150,
        visited: true,
        isEditorPick: true,
      ),
      'icon': '🏛️',
      'distance': '280 km away',
    },
    {
      'site': HeritageSite(
        id: 'site_malacca_city',
        name: 'Malacca City',
        location: 'Malacca',
        description: 'Historic city rich in colonial history.',
        category: 'Heritage',
        latitude: 2.1896,
        longitude: 102.2501,
        imageUrl: '',
        tags: ['History'],
        duration: 'Half day',
        xp: 120,
        visited: true,
        isEditorPick: false,
      ),
      'icon': '🏯',
      'distance': '145 km away',
    },
    {
      'site': HeritageSite(
        id: 'site_kinabalu_park',
        name: 'Kinabalu Park',
        location: 'Sabah',
        description: 'Malaysia\'s first World Heritage Site.',
        category: 'Nature',
        latitude: 6.0084,
        longitude: 116.5416,
        imageUrl: '',
        tags: ['Mountain'],
        duration: 'Full day',
        xp: 200,
        visited: false,
        isEditorPick: false,
      ),
      'icon': '⛰️',
      'distance': '1,620 km away',
    },
    {
      'site': HeritageSite(
        id: 'site_merdeka_square',
        name: 'Merdeka Square',
        location: 'Kuala Lumpur',
        description: 'Historic independence square.',
        category: 'National',
        latitude: 3.1480,
        longitude: 101.6937,
        imageUrl: '',
        tags: ['Independence'],
        duration: '1 hour',
        xp: 80,
        visited: true,
        isEditorPick: false,
      ),
      'icon': '🗽',
      'distance': '1.2 km away',
    },
  ];

  Map<String, bool> _collectedMap = {};
  bool _isLoading = true;
  String? _activeVerificationId;

  // TOGGLE THIS TO 'true' IF YOU WANT TO TEST CHECK-INS WITHOUT BEING NEAR THE LOCATION
  final bool _bypassDistanceCheckForTesting = false;

  @override
  void initState() {
    super.initState();
    _loadCollectedStates();
  }

  Future<void> _loadCollectedStates() async {
    Map<String, bool> temp = {};
    for (var item in _uiSites) {
      final HeritageSite site = item['site'];
      bool isSaved = await _passportService.isCollected(site.id);
      temp[site.id] = isSaved;
    }
    setState(() {
      _collectedMap = temp;
      _isLoading = false;
    });
  }

  Future<void> _handleCheckIn(HeritageSite site) async {
    setState(() => _activeVerificationId = site.id);

    try {
      bool isWithinRange = _bypassDistanceCheckForTesting;

      if (!_bypassDistanceCheckForTesting) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showSnackBar('Location services are disabled. Please enable GPS.');
          setState(() => _activeVerificationId = null);
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _showSnackBar('Location permissions are denied.');
            setState(() => _activeVerificationId = null);
            return;
          }
        }

        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );

        double distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          site.latitude,
          site.longitude,
        );

        isWithinRange = distanceMeters <= 100.0;
      }

      if (isWithinRange) {
        // 1. Save local passport collection
        await _passportService.collectPiece(site.id);

        // 2. Award XP via AchievementProvider
        if (mounted) {
          final achievementProvider = Provider.of<AchievementProvider>(
            context,
            listen: false,
          );
          achievementProvider.addXp(site.xp);
        }

        // 3. Update local state
        setState(() {
          _collectedMap[site.id] = true;
        });

        // 4. Prompt dialog and route user to Badges screen
        _showSuccessAndRedirectDialog(site);
      } else {
        _showSnackBar('Outside 100m range. Visit the physical location to check in!');
      }
    } catch (e) {
      _showSnackBar('Check-in failed: $e');
    } finally {
      setState(() => _activeVerificationId = null);
    }
  }

  void _showSuccessAndRedirectDialog(HeritageSite site) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: const [
              Text('🎉 Check-In Complete!', textAlign: TextAlign.center),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 60),
              const SizedBox(height: 12),
              Text(
                'You collected ${site.name} passport piece!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '+${site.xp} XP Earned!',
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                // Route to Badges Tab if callback passed, else fallback to named route
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(BottomTab.badges);
                } else {
                  Navigator.pushNamed(context, '/badges');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'View & Claim Badges',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievementProvider = Provider.of<AchievementProvider>(context);

    int total = _uiSites.length;
    int collectedCount = _collectedMap.values.where((v) => v).length;
    int percentage = total > 0 ? ((collectedCount / total) * 100).round() : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP HEADER (XP syncs live with AchievementProvider)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'GPS Check-In',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Collect passport pieces by visiting\nsites',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7CD),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${achievementProvider.totalXp}\nXP',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. GPS ACTIVE BANNER
            Container(
              width: double.infinity,
              color: const Color(0xFF064E3B),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pin_drop,
                      size: 16,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'GPS Active • ±12 m accuracy',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '3.1579° N, 101.7116° E · Kuala Lumpur area',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$collectedCount/$total',
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        'collected',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. PASSPORT PROGRESS BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Passport Collection Progress',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? collectedCount / total : 0,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0D9488),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$collectedCount of $total passport pieces collected',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // 4. SITE LIST
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT A SITE TO CHECK IN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF064E3B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.circle, size: 8, color: Color(0xFF4ADE80)),
                        SizedBox(width: 8),
                        Text(
                          'Within 100 m · GPS verified location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Column(
                      children: _uiSites.map((item) {
                        final HeritageSite site = item['site'];
                        final String icon = item['icon'];
                        final String distance = item['distance'];
                        final bool isCollected = _collectedMap[site.id] ?? false;
                        final bool isVerifyingThis = _activeVerificationId == site.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(icon, style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            site.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCollected) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              '✓ Collected',
                                              style: TextStyle(
                                                color: Color(0xFF166534),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${site.location} · $distance',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (isCollected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Done',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: isVerifyingThis
                                      ? null
                                      : () => _handleCheckIn(site),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: isVerifyingThis
                                      ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text(
                                    'Check In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}