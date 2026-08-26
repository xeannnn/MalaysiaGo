import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'quiz.dart';
import 'travel_info.dart';
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
  final String briefInfo;

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
    required this.briefInfo,
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
    briefInfo:
    'A dramatic limestone cave complex crowned by a giant golden statue of Lord Murugan, reached by 272 rainbow-painted steps. It\'s one of the most visited Hindu shrines outside India and the centre of Malaysia\'s annual Thaipusam festival.',
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
    briefInfo:
    'The historic padang where Malaysia\'s independence was declared at midnight on 31 August 1957. Ringed by Mughal-style colonial buildings, with one of the world\'s tallest flagpoles at its centre.',
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
    briefInfo:
    'A UNESCO World Heritage colonial port city blending Chinese, Malay, Indian, and European influences across its shophouses, temples, and street art. Best explored slowly, on foot, through its historic core.',
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
    briefInfo:
    'A UNESCO-listed trading port shaped in turn by Portuguese, Dutch, and British rule, still visible in its forts, churches, and Peranakan townhouses. Jonker Street is the heart of its antique-shop and night-market culture.',
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
    briefInfo:
    'Malaysia\'s largest Buddhist temple complex, built up a hillside in Air Itam around a seven-tier pagoda blending Chinese, Thai, and Burmese architecture. A giant bronze statue of Kuan Yin overlooks the grounds.',
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
    briefInfo:
    'A cool hill-station region of rolling tea plantations, strawberry farms, and mossy forest trails, first developed by the British in the 1920s. A popular escape from Malaysia\'s lowland heat.',
  ),
  HeritageMapSite(
    id: 'masjid_zahir',
    icon: '🕌',
    name: 'Zahir Mosque',
    location: 'Kedah',
    latitude: 6.1216,
    longitude: 100.3672,
    distanceKm: 400,
    xpReward: 90,
    category: 'Religious',
    visited: false,
    hasQuiz: true,
    briefInfo:
    'One of Malaysia\'s oldest and grandest mosques, completed in 1912 in a Moorish-Mughal style with five distinctive black domes. It stands on ground where Kedah warriors who fell defending the state in 1821 are buried.',
  ),
  HeritageMapSite(
    id: 'lenggong_valley',
    icon: '🏺',
    name: 'Lenggong Valley',
    location: 'Perak',
    latitude: 5.1075,
    longitude: 100.9717,
    distanceKm: 200,
    xpReward: 120,
    category: 'UNESCO',
    visited: false,
    hasQuiz: true,
    briefInfo:
    'A UNESCO World Heritage archaeological valley where stone tools and the roughly 11,000-year-old skeleton known as "Perak Man" were unearthed. Its caves and open-air sites trace continuous human activity spanning hundreds of thousands of years.',
  ),
  HeritageMapSite(
    id: 'crystal_mosque',
    icon: '🕌',
    name: 'Crystal Mosque',
    location: 'Terengganu',
    latitude: 5.3390,
    longitude: 103.1360,
    distanceKm: 480,
    xpReward: 90,
    category: 'Religious',
    visited: false,
    hasQuiz: true,
    briefInfo:
    'A striking steel-and-glass mosque on an island in the Terengganu River, illuminated in shifting colours after dark. Opened in 2008 as part of the Islamic Heritage Park.',
  ),
  HeritageMapSite(
    id: 'taman_negara',
    icon: '🌳',
    name: 'Taman Negara',
    location: 'Pahang',
    latitude: 4.3806,
    longitude: 102.4048,
    distanceKm: 150,
    xpReward: 110,
    category: 'Nature',
    visited: false,
    hasQuiz: true,
    briefInfo:
    'Widely cited as one of the world\'s oldest rainforests, home to a canopy walkway strung high above the forest floor. Kuala Tahan village is the usual gateway for jungle treks and river trips.',
  ),
  HeritageMapSite(
    id: 'sultan_abu_bakar_mosque',
    icon: '🕌',
    name: 'Sultan Abu Bakar State Mosque',
    location: 'Johor',
    latitude: 1.4667,
    longitude: 103.7576,
    distanceKm: 340,
    xpReward: 90,
    category: 'Religious',
    visited: false,
    hasQuiz: true,
    briefInfo:
    'A grand Victorian-Moorish mosque perched above the Johor Strait with views toward Singapore, built under Sultan Abu Bakar, the "Father of Modern Johor." Its blend of British and Islamic architecture is unusual among Malaysian mosques.',
  ),
];

const List<String> _filterCategories = [
  'All',
  'UNESCO',
  'Religious',
  'Nature',
  'National',
];

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

  HeritageMapSite get _nearestSite => (List<HeritageMapSite>.from(
    heritageMapSites,
  )..sort((a, b) => a.distanceKm.compareTo(b.distanceKm))).first;

  int get _visitedCount => heritageMapSites.where((s) => s.visited).length;

  bool _isCompleted(HeritageMapSite site) =>
      widget.completedQuizIds.contains(site.id);

  /// Actually starts the quiz flow for a site — handles the "no quiz
  /// yet" and "already completed" cases with a toast, otherwise pushes
  /// the quiz intro screen. Called from the site options sheet's
  /// "Take Quiz" button (and directly wherever a quiz-only action
  /// makes sense, e.g. the nearby-site banner).
  void _startQuiz(HeritageMapSite site) {
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
            'You\'ve already completed the ${site.name} quiz — scored ${attempt.correctCount}/${attempt.totalQuestions}.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QuizIntroScreen(
          siteId: site.id,
          onQuizComplete: widget.onQuizComplete,
        ),
      ),
    );
  }

  /// Opens the brief site info screen for a site.
  void _openGuide(HeritageMapSite site) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SiteGuideScreen(
          site: site,
          completed: _isCompleted(site),
          totalXp: widget.totalXp,
          onTakeQuiz: () => _startQuiz(site),
        ),
      ),
    );
  }

  /// Tapping a heritage site — a map marker, a list card, or the
  /// nearby-site banner — opens a small options sheet rather than
  /// jumping straight into the quiz, so the user can choose between
  /// taking the quiz or reading the brief site info first.
  void _openSite(HeritageMapSite site) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SiteOptionsSheet(
        site: site,
        completed: _isCompleted(site),
        onTakeQuiz: () {
          Navigator.of(context).pop();
          _startQuiz(site);
        },
        onOpenGuide: () {
          Navigator.of(context).pop();
          _openGuide(site);
        },
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
    final showNearbyBanner =
        nearest.distanceKm < 1.0 && nearest.hasQuiz && !_isCompleted(nearest);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: 'Heritage Map',
                subtitle:
                '$_visitedCount/${heritageMapSites.length} Sites Visited',
                xp: '${widget.totalXp}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MapCanvas(
                  sites: heritageMapSites,
                  visitedCount: _visitedCount,
                  onTapSite: _openSite,
                ),
              ),
              if (showNearbyBanner) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NearbyBanner(
                    site: nearest,
                    onTap: () => _openSite(nearest),
                  ),
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
                              onTap: () =>
                                  setState(() => _selectedCategory = category),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HistoryButton(
                      count: widget.quizHistory.length,
                      onTap: _openHistory,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${_filteredSites.length} sites · Tap a marker to explore',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: _filteredSites
                      .map(
                        (site) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SiteListCard(
                        site: site,
                        completed: _isCompleted(site),
                        onTap: () => _openSite(site),
                      ),
                    ),
                  )
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
            Text(
              'History',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F8A5F),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
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

  const _MapCanvas({
    required this.sites,
    required this.visitedCount,
    required this.onTapSite,
  });

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
      ll.LatLng(
        lats.reduce((a, b) => a < b ? a : b) - 0.35,
        lngs.reduce((a, b) => a < b ? a : b) - 0.35,
      ),
      ll.LatLng(
        lats.reduce((a, b) => a > b ? a : b) + 0.35,
        lngs.reduce((a, b) => a > b ? a : b) + 0.35,
      ),
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
    _controller.fitCamera(
      CameraFit.bounds(bounds: _siteBounds, padding: const EdgeInsets.all(36)),
    );
  }

  void _zoomBy(double delta) {
    _controller.move(
      _controller.camera.center,
      _controller.camera.zoom + delta,
    );
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
                  flags:
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
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
              child: _Pill(
                label: '${widget.visitedCount}/${widget.sites.length} Visited',
                dark: true,
              ),
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
    final baseColor = site.visited
        ? const Color(0xFF16A34A)
        : const Color(0xFF2563EB);
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
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          Positioned(
            top: 6,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
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
                color: site.visited
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFF59E0B),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(site.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 You\'re near ${site.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${site.distanceKm} km away · Earn +${site.xpReward} XP',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: onTap,
            child: const Text(
              'Take Quiz →',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
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
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          border: Border.all(
            color: selected ? const Color(0xFF16A34A) : const Color(0xFFE5E5EA),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _SiteListCard extends StatelessWidget {
  final HeritageMapSite site;
  final bool completed;
  final VoidCallback onTap;
  const _SiteListCard({
    required this.site,
    required this.completed,
    required this.onTap,
  });

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
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(site.icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${site.location} · ${site.distanceKm} km',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${site.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB8720A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: site.visited
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF60A5FA),
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

/// Bottom sheet shown when a heritage site is tapped — from a map
/// marker, a list card, or the nearby-site banner. Lets the user
/// choose between jumping into the quiz or reading the brief site
/// info first, rather than assuming quiz intent.
class _SiteOptionsSheet extends StatelessWidget {
  final HeritageMapSite site;
  final bool completed;
  final VoidCallback onTakeQuiz;
  final VoidCallback onOpenGuide;

  const _SiteOptionsSheet({
    required this.site,
    required this.completed,
    required this.onTakeQuiz,
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(site.icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        site.location,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              site.briefInfo,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTakeQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  completed ? Icons.check_circle : Icons.quiz,
                  size: 18,
                ),
                label: Text(
                  !site.hasQuiz
                      ? 'Quiz coming soon'
                      : completed
                      ? 'Quiz completed — view score'
                      : 'Take Quiz · +${site.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenGuide,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F8A5F),
                  side: const BorderSide(color: Color(0xFFE5E5EA)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.menu_book, size: 18),
                label: const Text(
                  "Site Info",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A brief, self-contained info page for one heritage site —
/// reachable from the site options sheet. Shows the site's category,
/// location, and a short description, with a "Take Quiz" call-to-action
/// if one exists, and a "Full Guide" button linking to the app's
/// general Traveller's Guide (transport / etiquette / safety info).
class SiteGuideScreen extends StatelessWidget {
  final HeritageMapSite site;
  final bool completed;
  final int totalXp;
  final VoidCallback onTakeQuiz;

  const SiteGuideScreen({
    super.key,
    required this.site,
    required this.completed,
    required this.totalXp,
    required this.onTakeQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      site.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF16A34A), Color(0xFF0F8A5F)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(site.icon, style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    Text(
                      site.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          site.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            site.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Text(
                  'About this site',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  site.briefInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _GuideStat(
                        label: 'XP Reward',
                        value: '+${site.xpReward}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GuideStat(
                        label: 'Status',
                        value: site.visited ? 'Visited' : 'Unvisited',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTakeQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      completed ? Icons.check_circle : Icons.quiz,
                      size: 18,
                    ),
                    label: Text(
                      !site.hasQuiz
                          ? 'Quiz coming soon'
                          : completed
                          ? 'Quiz completed — view score'
                          : 'Take Quiz · +${site.xpReward} XP',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: Colors.white,
                            appBar: AppBar(
                              title: const Text(
                                "Traveller's Guide",
                                style: TextStyle(color: Colors.black),
                              ),
                              backgroundColor: Colors.white,
                              elevation: 0,
                              iconTheme: const IconThemeData(color: Colors.black),
                            ),
                            body: TravelInfoPage(totalXp: totalXp),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F8A5F),
                      side: const BorderSide(color: Color(0xFF0F8A5F)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text(
                      'Full Guide',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
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

class _GuideStat extends StatelessWidget {
  final String label;
  final String value;
  const _GuideStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}