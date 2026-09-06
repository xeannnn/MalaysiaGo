import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services/image_service.dart';
import 'passport.dart';

class HeritageDetailScreen extends StatefulWidget {
  final HeritageSite site;

  const HeritageDetailScreen({super.key, required this.site});

  @override
  State<HeritageDetailScreen> createState() => _HeritageDetailScreenState();
}

class _HeritageDetailScreenState extends State<HeritageDetailScreen> {
  int selectedTab = 0;

  List<String> _heritageImages = [];
  bool _imageLoading = true;
  int _currentPhotoIndex = 0;

  final PageController _photoController = PageController();
  final MapController _mapController = MapController();

  final List<String> tabs = const ['📖 Overview', '💡 Tips', 'ℹ️ Visit Info'];

  @override
  void initState() {
    super.initState();
    _loadHeritageImages();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadHeritageImages() async {
    try {
      final images = await ImageService.getHeritageImages(
        widget.site.name,
        location: widget.site.location,
        siteId: widget.site.id,
        existingImageUrls: widget.site.imageUrls,
        existingImageUrl: widget.site.imageUrl,
        maxImages: 5,
      );

      if (!mounted) return;

      setState(() {
        _heritageImages = images;
        _imageLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _heritageImages = [];
        _imageLoading = false;
      });

      debugPrint('Failed to load images for ${widget.site.name}: $e');
    }
  }

  String get _headerImageUrl {
    if (_heritageImages.isNotEmpty) {
      return _heritageImages.first;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildHeader(site),
                  SliverToBoxAdapter(child: _buildTitleSection(site)),
                  SliverToBoxAdapter(child: _buildTabs()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSelectedTab(site),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(HeritageSite site) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeaderImage(),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 18,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _badge(site.category, Icons.category_outlined),
                  _badge(site.difficulty, Icons.trending_up),
                  _badge('${site.xp} XP', Icons.star_outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    if (_imageLoading) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_headerImageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.account_balance, size: 70, color: Colors.grey),
        ),
      );
    }

    return Image.network(
      _headerImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 60,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitleSection(HeritageSite site) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            site.name,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 19,
                color: Colors.grey,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  site.location,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? Colors.green : Colors.transparent,
                  ),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedTab(HeritageSite site) {
    switch (selectedTab) {
      case 1:
        return _buildTips(site);
      case 2:
        return _buildVisitInfo(site);
      default:
        return _buildOverview(site);
    }
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _buildOverview(HeritageSite site) {
    final historicalText = site.history.trim().isNotEmpty
        ? site.history
        : site.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Historical Information', Icons.history_edu),
        const SizedBox(height: 10),
        _infoCard(
          child: Text(
            historicalText.isNotEmpty
                ? historicalText
                : 'Historical information is currently unavailable.',
            style: const TextStyle(height: 1.6, fontSize: 15),
          ),
        ),
        if (site.establishedYear.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _detailRowCard(
            icon: Icons.calendar_month_outlined,
            title: 'Established',
            value: site.establishedYear,
          ),
        ],
        if (site.significance.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _detailRowCard(
            icon: Icons.workspace_premium,
            title: 'Significance',
            value: site.significance,
          ),
        ],
        const SizedBox(height: 22),
        _sectionTitle('Photos', Icons.photo_library_outlined),
        const SizedBox(height: 10),
        _photoGallery(),
        const SizedBox(height: 22),
        _sectionTitle('Visit Summary', Icons.explore_outlined),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _miniInfoCard(
                icon: Icons.wb_sunny_outlined,
                label: 'Best Time',
                value: site.bestTime.isNotEmpty ? site.bestTime : 'Any time',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _miniInfoCard(
                icon: Icons.access_time,
                label: 'Duration',
                value: site.duration,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _sectionTitle('Location', Icons.location_on_outlined),
        const SizedBox(height: 10),
        _locationCard(site),
      ],
    );
  }

  // ============================================================
  // SWIPEABLE PHOTO GALLERY
  // ============================================================

  Widget _photoGallery() {
    if (_imageLoading) {
      return Container(
        height: 230,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_heritageImages.isEmpty) {
      return Container(
        height: 230,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 45,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Photos are currently unavailable.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _photoController,
                  itemCount: _heritageImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPhotoIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = _heritageImages[index];

                    return GestureDetector(
                      onTap: () {
                        _openFullScreenGallery(index);
                      },
                      child: Hero(
                        tag: 'heritage-photo-${widget.site.id}-$index',
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 230,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade100,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Image counter.
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1}/${_heritageImages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Fullscreen indicator.
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),

              // Left hint.
              if (_currentPhotoIndex > 0)
                const Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

              // Right hint.
              if (_currentPhotoIndex < _heritageImages.length - 1)
                const Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 30),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (_heritageImages.length > 1) ...[
          const SizedBox(height: 10),

          // Dot indicators.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_heritageImages.length, (index) {
              final selected = index == _currentPhotoIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? Colors.green : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),

          const SizedBox(height: 6),

          Text(
            'Swipe left or right to view more photos',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  void _openFullScreenGallery(int initialIndex) {
    if (_heritageImages.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return FullScreenHeritageGallery(
            imageUrls: _heritageImages,
            initialIndex: initialIndex,
            siteName: widget.site.name,
            siteId: widget.site.id,
          );
        },
      ),
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Widget _locationCard(HeritageSite site) {
    final bool validCoordinates = _hasValidCoordinates(site);
    final LatLng sitePosition = LatLng(site.latitude, site.longitude);

    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (site.address.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 21),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    site.address,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          if (validCoordinates) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: sitePosition,
                        initialZoom: 15,

                        // flutter_map supports mobile gestures natively:
                        // one finger = pan
                        // two fingers = pinch zoom
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.malaysiago',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: sitePosition,
                              width: 54,
                              height: 54,
                              child: const Icon(
                                Icons.location_pin,
                                size: 48,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Zoom / recenter controls.
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        children: [
                          _mapControlButton(
                            icon: Icons.add,
                            tooltip: 'Zoom in',
                            onTap: () {
                              final camera = _mapController.camera;
                              _mapController.move(
                                camera.center,
                                (camera.zoom + 1).clamp(2.0, 19.0),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _mapControlButton(
                            icon: Icons.remove,
                            tooltip: 'Zoom out',
                            onTap: () {
                              final camera = _mapController.camera;
                              _mapController.move(
                                camera.center,
                                (camera.zoom - 1).clamp(2.0, 19.0),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _mapControlButton(
                            icon: Icons.my_location,
                            tooltip: 'Recenter',
                            onTap: () {
                              _mapController.move(sitePosition, 15);
                            },
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pinch_outlined,
                              size: 15,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Pinch to zoom · Drag to move',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _coordinateBox(
                    label: 'Latitude',
                    value: site.latitude.toStringAsFixed(6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _coordinateBox(
                    label: 'Longitude',
                    value: site.longitude.toStringAsFixed(6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openGoogleMaps(site);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            const Row(
              children: [
                Icon(Icons.location_off_outlined, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location coordinates are currently unavailable.',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 21, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _coordinateBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  bool _hasValidCoordinates(HeritageSite site) {
    return site.latitude >= -90 &&
        site.latitude <= 90 &&
        site.longitude >= -180 &&
        site.longitude <= 180 &&
        !(site.latitude == 0 && site.longitude == 0);
  }

  Future<void> _openGoogleMaps(HeritageSite site) async {
    if (!_hasValidCoordinates(site)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Heritage site location is currently unavailable.'),
        ),
      );

      return;
    }

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
          '&query=${site.latitude},${site.longitude}',
    );

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open Google Maps.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
  }

  // ============================================================
  // TIPS
  // ============================================================

  Widget _buildTips(HeritageSite site) {
    if (site.tips.isEmpty) {
      return _infoCard(
        child: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 10),
            Expanded(child: Text('No travel tips are currently available.')),
          ],
        ),
      );
    }

    return Column(
      children: site.tips.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _infoCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.green.shade50,
                  child: Text(
                    '${entry.key + 1}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(entry.value, style: const TextStyle(height: 1.5)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // VISIT INFO
  // ============================================================

  Widget _buildVisitInfo(HeritageSite site) {
    return Column(
      children: [
        _visitInfoTile(
          icon: Icons.access_time,
          title: 'Operation Hours',
          value: site.openingHours.isNotEmpty ? site.openingHours : 'Unknown',
        ),
        _visitInfoTile(
          icon: Icons.confirmation_number_outlined,
          title: 'Entrance Fee',
          value: site.entryFee.isNotEmpty ? site.entryFee : 'Unknown',
        ),
        _visitInfoTile(
          icon: Icons.location_on_outlined,
          title: 'Location',
          value: site.location,
        ),
        if (site.address.trim().isNotEmpty)
          _visitInfoTile(
            icon: Icons.home_work_outlined,
            title: 'Address',
            value: site.address,
          ),
        _visitInfoTile(
          icon: Icons.category_outlined,
          title: 'Category',
          value: site.category,
        ),
        _visitInfoTile(
          icon: Icons.trending_up_outlined,
          title: 'Difficulty',
          value: site.difficulty,
        ),
        _visitInfoTile(
          icon: Icons.star_outline,
          title: 'Experience Points',
          value: '${site.xp} XP',
        ),
      ],
    );
  }

  Widget _visitInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _infoCard(
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.green.shade700),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMMON WIDGETS
  // ============================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _detailRowCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return _infoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PASSPORT BUTTON
  // ============================================================

  Widget _buildBottomButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PassportScreen(
                  showBackButton: true,
                ),
              ),
            );
          },
          icon: const Icon(Icons.card_membership),
          label: const Text('View Heritage Passport'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FULLSCREEN SWIPEABLE / ZOOMABLE PHOTO GALLERY
// ============================================================

class FullScreenHeritageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String siteName;
  final String siteId;

  const FullScreenHeritageGallery({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.siteName,
    required this.siteId,
  });

  @override
  State<FullScreenHeritageGallery> createState() =>
      _FullScreenHeritageGalleryState();
}

class _FullScreenHeritageGalleryState extends State<FullScreenHeritageGallery> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      child: Hero(
                        tag: 'heritage-photo-${widget.siteId}-$index',
                        child: Image.network(
                          widget.imageUrls[index],
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white54,
                                    size: 60,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Unable to load image.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Close button.
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),

            // Counter.
            Positioned(
              top: 18,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Site name + dot indicators.
            Positioned(
              left: 20,
              right: 20,
              bottom: 25,
              child: Column(
                children: [
                  Text(
                    widget.siteName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                  if (widget.imageUrls.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.imageUrls.length, (index) {
                        final selected = index == _currentIndex;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: selected ? 18 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}