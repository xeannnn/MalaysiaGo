import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'quiz.dart';
import '../widgets/app_header.dart';

/// ---------------------------------------------------------------
/// HERITAGE MAP MODULE
/// ---------------------------------------------------------------
/// A real map (flutter_map, rendering OpenStreetMap tiles) showing
/// every heritage site at its true lat/lng, a nearby-site quiz
/// banner, category filters, and a scrollable site list. Tapping a
/// marker or a list row that has a quiz opens it via QuizIntroScreen
/// from quiz.dart.
///
/// No API key required — OSM's default tile server
/// (tile.openstreetmap.org) is free to use for light/dev traffic, on
/// the condition that requests set a real User-Agent identifying the
/// app (done below) and don't hammer the server. If this app ever
/// gets heavy production traffic, switch the tile URL to a paid
/// provider (e.g. MapTiler, Stadia Maps) or self-hosted tiles — see
/// MAPS_SETUP.md for details. "Distance away" values in
/// [heritageMapSites] are still hardcoded demo data; wiring real GPS
/// distance needs a location permission plugin (e.g. geolocator),
/// which isn't included yet.
/// ---------------------------------------------------------------

class HeritageMapSite {
  final String id;
  final String icon;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int xpReward;
  final String category; // 'UNESCO' | 'Religious' | 'Nature' | 'National'
  final bool visited;
  final bool hasQuiz;

  const HeritageMapSite({
    required this.id,
    required this.icon,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.xpReward,
    required this.category,
    required this.visited,
    required this.hasQuiz,
  });

  ll.LatLng get latLng => ll.LatLng(latitude, longitude);
}

const List<HeritageMapSite> heritageMapSites = [
  HeritageMapSite(
    id: 'batu_caves',
    icon: '⛩️',
    name: 'Batu Caves',
    location: 'Selangor',
    latitude: 3.2379,
    longitude: 101.6840,
    distanceKm: 0.3,
    xpReward: 80,
    category: 'Religious',
    visited: false,
    hasQuiz: true,
  ),
  HeritageMapSite(
    id: 'merdeka_square',
    icon: '🏳️',
    name: 'Dataran Merdeka',
    location: 'Kuala Lumpur',
    latitude: 3.1478,
    longitude: 101.6953,
    distanceKm: 2.1,
    xpReward: 80,
    category: 'National',
    visited: true,
    hasQuiz: true,
  ),
  HeritageMapSite(
    id: 'george_town',
    icon: '🏛️',
    name: 'George Town',
    location: 'Penang',
    latitude: 5.4141,
    longitude: 100.3288,
    distanceKm: 280,
    xpReward: 120,
    category: 'UNESCO',
    visited: true,
    hasQuiz: true,
  ),
  HeritageMapSite(
    id: 'malacca_city',
    icon: '🏯',
    name: 'Malacca City',
    location: 'Melaka',
    latitude: 2.1896,
    longitude: 102.2501,
    distanceKm: 145,
    xpReward: 120,
    category: 'UNESCO',
    visited: true,
    hasQuiz: true,
  ),
  HeritageMapSite(
    id: 'kek_lok_si',
    icon: '🛕',
    name: 'Kek Lok Si Temple',
    location: 'Penang',
    latitude: 5.3994,
    longitude: 100.2739,
    distanceKm: 282,
    xpReward: 90,
    category: 'Religious',
    visited: false,
    hasQuiz: false,
  ),
  HeritageMapSite(
    id: 'cameron_highlands',
    icon: '⛰️',
    name: 'Cameron Highlands',
    location: 'Pahang',
    latitude: 4.4696,
    longitude: 101.3808,
    distanceKm: 90,
    xpReward: 100,
    category: 'Nature',
    visited: false,
    hasQuiz: false,
  ),
];

const List<String> _filterCategories = ['All', 'UNESCO', 'Religious', 'Nature', 'National'];

class MapScreen extends StatefulWidget {
  final int totalXp;
  final Set<String> completedQuizIds;
  final List<QuizAttempt> quizHistory;
  final QuizCompleteCallback onQuizComplete;

  const MapScreen({
    super.key,
    required this.totalXp,
    required this.completedQuizIds,
    required this.quizHistory,
    required this.onQuizComplete,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedCategory = 'All';

  List<HeritageMapSite> get _filteredSites => _selectedCategory == 'All'
      ? heritageMapSites
      : heritageMapSites.where((s) => s.category == _selectedCategory).toList();

  HeritageMapSite get _nearestSite =>
      (List<HeritageMapSite>.from(heritageMapSites)..sort((a, b) => a.distanceKm.compareTo(b.distanceKm))).first;

  int get _visitedCount => heritageMapSites.where((s) => s.visited).length;

  bool _isCompleted(HeritageMapSite site) => widget.completedQuizIds.contains(site.id);

  void _openSite(HeritageMapSite site) {
    if (!site.hasQuiz) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz for ${site.name} is coming soon.')),
      );
      return;
    }
    if (_isCompleted(site)) {
      final attempt = widget.quizHistory.lastWhere((a) => a.siteId == site.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'You\'ve already completed the ${site.name} quiz — scored ${attempt.correctCount}/${attempt.totalQuestions}.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QuizIntroScreen(siteId: site.id, onQuizComplete: widget.onQuizComplete),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizHistoryScreen(attempts: widget.quizHistory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearest = _nearestSite;
    final showNearbyBanner = nearest.distanceKm < 1.0 && nearest.hasQuiz && !_isCompleted(nearest);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: 'Heritage Map',
                subtitle: '$_visitedCount/${heritageMapSites.length} Sites Visited',
                xp: '${widget.totalXp}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MapCanvas(sites: heritageMapSites, visitedCount: _visitedCount, onTapSite: _openSite),
              ),
              if (showNearbyBanner) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NearbyBanner(site: nearest, onTap: () => _openSite(nearest)),
                ),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filterCategories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = _filterCategories[index];
                            final selected = category == _selectedCategory;
                            return _FilterChip(
                              label: category,
                              selected: selected,
                              onTap: () => setState(() => _selectedCategory = category),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HistoryButton(count: widget.quizHistory.length, onTap: _openHistory),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('${_filteredSites.length} sites · Tap a marker to explore',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: _filteredSites
                      .map((site) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SiteListCard(site: site, completed: _isCompleted(site), onTap: () => _openSite(site)),
                  ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _HistoryButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 16, color: Color(0xFF0F8A5F)),
            const SizedBox(width: 6),
            Text('History', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F8A5F))),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The pannable/zoomable map canvas. Overlays (legend, visited
/// counter, zoom buttons) sit in a Stack on top of the FlutterMap
/// widget, which renders OpenStreetMap tiles and handles its own
/// native pan/pinch-zoom gestures.
class _MapCanvas extends StatefulWidget {
  final List<HeritageMapSite> sites;
  final int visitedCount;
  final ValueChanged<HeritageMapSite> onTapSite;

  const _MapCanvas({required this.sites, required this.visitedCount, required this.onTapSite});

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  final MapController _controller = MapController();

  // Centre + default zoom chosen to frame all of Peninsular Malaysia;
  // refined to the exact site bounds once the map has laid out below.
  static const ll.LatLng _initialCenter = ll.LatLng(3.9, 102.0);
  static const double _initialZoom = 6.3;

  /// Bounding box around every site, padded a little so markers near
  /// the edge aren't flush against the canvas border.
  LatLngBounds get _siteBounds {
    final lats = widget.sites.map((s) => s.latitude);
    final lngs = widget.sites.map((s) => s.longitude);
    return LatLngBounds(
      ll.LatLng(lats.reduce((a, b) => a < b ? a : b) - 0.35, lngs.reduce((a, b) => a < b ? a : b) - 0.35),
      ll.LatLng(lats.reduce((a, b) => a > b ? a : b) + 0.35, lngs.reduce((a, b) => a > b ? a : b) + 0.35),
    );
  }

  List<Marker> get _markers => widget.sites
      .map(
        (site) => Marker(
      point: site.latLng,
      width: 44,
      height: 54,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => widget.onTapSite(site),
        child: _MapPin(site: site),
      ),
    ),
  )
      .toList();

  void _onMapReady() {
    // Fit the view to the real site bounds once the map has laid
    // out, rather than relying on a guessed centre/zoom.
    _controller.fitCamera(CameraFit.bounds(bounds: _siteBounds, padding: const EdgeInsets.all(36)));
  }

  void _zoomBy(double delta) {
    _controller.move(_controller.camera.center, _controller.camera.zoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    const canvasHeight = 380.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: canvasHeight,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _initialZoom,
                minZoom: 5,
                maxZoom: 18,
                onMapReady: _onMapReady,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // OSM's usage policy asks every app to identify
                  // itself with a real User-Agent, not a placeholder.
                  userAgentPackageName: 'com.example.malaysiago',
                  maxZoom: 19,
                ),
                MarkerLayer(markers: _markers),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            // Fixed overlays
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _LegendRow(color: Color(0xFF4ADE80), label: 'Visited'),
                    SizedBox(height: 4),
                    _LegendRow(color: Color(0xFF60A5FA), label: 'Unvisited'),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: _Pill(label: '${widget.visitedCount}/${widget.sites.length} Visited', dark: true),
            ),
            // Explicit zoom controls, in addition to native pinch-zoom —
            // more discoverable/reliable, especially on emulators.
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                children: [
                  _ZoomButton(icon: Icons.add, onTap: () => _zoomBy(1)),
                  const SizedBox(height: 6),
                  _ZoomButton(icon: Icons.remove, onTap: () => _zoomBy(-1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

/// A conventional map-pin teardrop, anchored so its point (not its
/// centre) marks the actual site location. flutter_map's Marker
/// takes a plain widget child (unlike google_maps_flutter's bitmap
/// icons), so this is what actually gets drawn.
class _MapPin extends StatelessWidget {
  final HeritageMapSite site;
  const _MapPin({required this.site});

  @override
  Widget build(BuildContext context) {
    final baseColor = site.visited ? const Color(0xFF16A34A) : const Color(0xFF2563EB);
    return SizedBox(
      width: 44,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Icon(
            Icons.location_on,
            size: 48,
            color: baseColor,
            shadows: [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          Positioned(
            top: 6,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              alignment: Alignment.center,
              child: Text(site.icon, style: const TextStyle(fontSize: 14)),
            ),
          ),
          Positioned(
            top: -2,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: site.visited ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(
                site.visited ? Icons.check : Icons.stars,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String? icon;
  final String label;
  final bool dark;
  const _Pill({this.icon, required this.label, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 9)),
            const SizedBox(width: 4),
          ],
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ],
    );
  }
}

class _NearbyBanner extends StatelessWidget {
  final HeritageMapSite site;
  final VoidCallback onTap;
  const _NearbyBanner({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF0D9488)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(site.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 You\'re near ${site.name}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${site.distanceKm} km away · Earn +${site.xpReward} XP',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: onTap,
            child: const Text('Take Quiz →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF16A34A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF16A34A) : const Color(0xFFE5E5EA)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87)),
      ),
    );
  }
}

class _SiteListCard extends StatelessWidget {
  final HeritageMapSite site;
  final bool completed;
  final VoidCallback onTap;
  const _SiteListCard({required this.site, required this.completed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: completed ? const Color(0xFFF3F4F6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(site.icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(site.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 2),
                  Text('${site.location} · ${site.distanceKm} km',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text('Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${site.xpReward} XP',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB8720A))),
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: site.visited ? const Color(0xFF4ADE80) : const Color(0xFF60A5FA),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}