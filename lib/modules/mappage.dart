import 'package:flutter/material.dart';
import 'quiz.dart';
import '../widgets/app_header.dart';

/// ---------------------------------------------------------------
/// HERITAGE MAP MODULE
/// ---------------------------------------------------------------
/// Replaces the temporary "Map UI pending" placeholder with a real
/// (illustrative, non-GPS) heritage map: a pannable/zoomable canvas
/// of site markers, a nearby-site quiz banner, category filters, and
/// a scrollable site list. Tapping a marker or list row that has a
/// quiz opens it via QuizIntroScreen from quiz.dart.
///
/// This is a stand-in for a real GPS/Google-Maps-based map — marker
/// positions are fixed fractional coordinates on a stylised canvas,
/// not real GPS coordinates, and "GPS Active" / distances are
/// hardcoded demo values. Swap in real location data later without
/// changing how this screen talks to the quiz module.
/// ---------------------------------------------------------------

class HeritageMapSite {
  final String id;
  final String icon;
  final String name;
  final String location;
  final double distanceKm;
  final int xpReward;
  final String category; // 'UNESCO' | 'Religious' | 'Nature' | 'National'
  final bool visited;
  final bool hasQuiz;
  final Offset position; // fractional (0..1) position on the map canvas

  const HeritageMapSite({
    required this.id,
    required this.icon,
    required this.name,
    required this.location,
    required this.distanceKm,
    required this.xpReward,
    required this.category,
    required this.visited,
    required this.hasQuiz,
    required this.position,
  });
}

const List<HeritageMapSite> heritageMapSites = [
  HeritageMapSite(
    id: 'batu_caves',
    icon: '⛩️',
    name: 'Batu Caves',
    location: 'Selangor',
    distanceKm: 0.3,
    xpReward: 80,
    category: 'Religious',
    visited: false,
    hasQuiz: true,
    position: Offset(0.30, 0.48),
  ),
  HeritageMapSite(
    id: 'merdeka_square',
    icon: '🏳️',
    name: 'Dataran Merdeka',
    location: 'Kuala Lumpur',
    distanceKm: 2.1,
    xpReward: 80,
    category: 'National',
    visited: true,
    hasQuiz: true,
    position: Offset(0.36, 0.53),
  ),
  HeritageMapSite(
    id: 'george_town',
    icon: '🏛️',
    name: 'George Town',
    location: 'Penang',
    distanceKm: 280,
    xpReward: 120,
    category: 'UNESCO',
    visited: true,
    hasQuiz: true,
    position: Offset(0.21, 0.20),
  ),
  HeritageMapSite(
    id: 'malacca_city',
    icon: '🏯',
    name: 'Malacca City',
    location: 'Melaka',
    distanceKm: 145,
    xpReward: 120,
    category: 'UNESCO',
    visited: true,
    hasQuiz: true,
    position: Offset(0.28, 0.62),
  ),
  HeritageMapSite(
    id: 'kek_lok_si',
    icon: '🛕',
    name: 'Kek Lok Si Temple',
    location: 'Penang',
    distanceKm: 282,
    xpReward: 90,
    category: 'Religious',
    visited: false,
    hasQuiz: false,
    position: Offset(0.19, 0.28),
  ),
  HeritageMapSite(
    id: 'cameron_highlands',
    icon: '⛰️',
    name: 'Cameron Highlands',
    location: 'Pahang',
    distanceKm: 90,
    xpReward: 100,
    category: 'Nature',
    visited: false,
    hasQuiz: false,
    position: Offset(0.48, 0.30),
  ),
];

const List<String> _filterCategories = ['All', 'UNESCO', 'Religious', 'Nature', 'National'];

class MapScreen extends StatefulWidget {
  final int totalXp;
  final ValueChanged<int> onXpEarned;
  const MapScreen({super.key, required this.totalXp, required this.onXpEarned});

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

  void _openSite(HeritageMapSite site) {
    if (!site.hasQuiz) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz for ${site.name} is coming soon.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QuizIntroScreen(siteId: site.id, onXpEarned: widget.onXpEarned),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearest = _nearestSite;
    final showNearbyBanner = nearest.distanceKm < 1.0 && nearest.hasQuiz;

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
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    child: _SiteListCard(site: site, onTap: () => _openSite(site)),
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

/// The pannable/zoomable map canvas. Overlays (GPS badge, legend,
/// visited counter, zoom buttons) stay fixed outside the
/// InteractiveViewer so they don't zoom/pan with the map content —
/// matching how real map apps keep their HUD fixed.
class _MapCanvas extends StatefulWidget {
  final List<HeritageMapSite> sites;
  final int visitedCount;
  final ValueChanged<HeritageMapSite> onTapSite;

  const _MapCanvas({required this.sites, required this.visitedCount, required this.onTapSite});

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  final TransformationController _transformController = TransformationController();
  static const double _minScale = 1.0;
  static const double _maxScale = 3.5;
  double _scale = _minScale;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _setZoom(double newScale) {
    final clamped = newScale.clamp(_minScale, _maxScale);
    setState(() {
      _scale = clamped;
      _transformController.value = Matrix4.identity()..scale(clamped);
    });
  }

  @override
  Widget build(BuildContext context) {
    const canvasHeight = 320.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: canvasHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: const Color(0xFF0B1130)),
            ),
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: _minScale,
                maxScale: _maxScale,
                boundaryMargin: const EdgeInsets.all(100),
                // Keep the zoom buttons' displayed scale in sync when
                // the user pinch-zooms manually instead of using them.
                onInteractionEnd: (_) {
                  final currentScale = _transformController.value.getMaxScaleOnAxis();
                  if ((currentScale - _scale).abs() > 0.01) {
                    setState(() => _scale = currentScale.clamp(_minScale, _maxScale));
                  }
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        // Stylised silhouette of Peninsular Malaysia.
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MalaysiaSilhouettePainter(),
                          ),
                        ),
                        for (final site in widget.sites)
                          Positioned(
                            left: w * site.position.dx - 22,
                            top: h * site.position.dy - 22,
                            child: GestureDetector(
                              onTap: () => widget.onTapSite(site),
                              child: _MapPin(site: site),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Fixed overlays
            const Positioned(top: 12, left: 12, child: _Pill(icon: '🟢', label: 'GPS Active', dark: true)),
            const Positioned(top: 48, left: 12, child: _Pill(label: '±12 m accuracy', dark: true)),
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
            // Explicit zoom controls — more discoverable/reliable than
            // relying on a pinch gesture alone, especially on emulators.
            Positioned(
              bottom: 12,
              left: 12,
              child: Column(
                children: [
                  _ZoomButton(icon: Icons.add, onTap: () => _setZoom(_scale + 0.5)),
                  const SizedBox(height: 6),
                  _ZoomButton(icon: Icons.remove, onTap: () => _setZoom(_scale - 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a simplified silhouette of Peninsular Malaysia — wide across
/// the north with the Kelantan/Terengganu east-coast bulge, tapering
/// to a point at the southern tip (Johor) — using straight coastline
/// segments rather than heavy smoothing, so it reads clearly as a
/// landmass instead of a blob. Illustrative, not survey-accurate.
class _MalaysiaSilhouettePainter extends CustomPainter {
  // Fractional (0..1) points tracing the coastline clockwise from
  // Perlis (NW) down the east coast to the Johor tip, then back up
  // the west coast.
  static const List<Offset> _points = [
    Offset(0.42, 0.04), // Perlis (Thai border, west)
    Offset(0.58, 0.03), // north border (central)
    Offset(0.72, 0.10), // Kelantan (NE)
    Offset(0.78, 0.22), // Terengganu coast bulge
    Offset(0.74, 0.34), // Pahang east coast (Kuantan)
    Offset(0.68, 0.46), // Pahang / Johor east coast
    Offset(0.60, 0.58), // Johor east (Mersing)
    Offset(0.50, 0.70), // Johor south-central
    Offset(0.42, 0.78), // Johor southern tip
    Offset(0.34, 0.72), // Johor west (Batu Pahat)
    Offset(0.28, 0.62), // Melaka coast
    Offset(0.24, 0.50), // Negeri Sembilan / Selangor coast
    Offset(0.22, 0.38), // Selangor / Perak coast
    Offset(0.20, 0.26), // Perak coast
    Offset(0.24, 0.14), // Kedah coast
  ];

  Path _buildPath(Size size) {
    final pts = _points.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    final fillPaint = Paint()
      ..color = const Color(0xFF14532D).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF4ADE80).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MalaysiaSilhouettePainter oldDelegate) => false;
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

class _MapPin extends StatelessWidget {
  final HeritageMapSite site;
  const _MapPin({required this.site});

  @override
  Widget build(BuildContext context) {
    final baseColor = site.visited ? const Color(0xFF4ADE80) : const Color(0xFF60A5FA);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor.withOpacity(0.22),
              border: Border.all(color: baseColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(site.icon, style: const TextStyle(fontSize: 18)),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: site.visited ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                border: Border.all(color: const Color(0xFF0B1130), width: 1.5),
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
  final VoidCallback onTap;
  const _SiteListCard({required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
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