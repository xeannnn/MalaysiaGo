import 'package:flutter/material.dart';

import '../models.dart';
import '../services/heritage_api_service.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_header.dart';
import 'travel_info.dart';
import 'heritage_detail.dart';

class HeritageExplorerScreen extends StatefulWidget {
  final int totalXp;
  final ValueChanged<BottomTab> onTabSelected;

  const HeritageExplorerScreen({
    super.key,
    required this.totalXp,
    required this.onTabSelected,
  });

  @override
  State<HeritageExplorerScreen> createState() =>
      _HeritageExplorerScreenState();
}

class _HeritageExplorerScreenState
    extends State<HeritageExplorerScreen> {
  int _selectedTabIndex = 0;
  String _selectedCategory = 'All';

  final TextEditingController _searchController =
  TextEditingController();

  List<HeritageSite> _sites = [];

  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _categories = [
    'All',
    'UNESCO',
    'Religious',
    'Nature',
    'National',
  ];

  @override
  void initState() {
    super.initState();
    _loadHeritage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHeritage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<HeritageSite> result =
      await HeritageApiService.fetchMalaysiaHeritage();

      if (!mounted) {
        return;
      }

      setState(() {
        _sites = result;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Heritage API Error: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Failed to load heritage sites.';
        _isLoading = false;
      });
    }
  }

  List<HeritageSite> get _filteredSites {
    final String query =
    _searchController.text.trim().toLowerCase();

    return _sites.where((HeritageSite site) {
      final bool categoryMatch =
          _selectedCategory == 'All' ||
              site.category.toLowerCase() ==
                  _selectedCategory.toLowerCase();

      final bool searchMatch =
          query.isEmpty ||
              site.name.toLowerCase().contains(query) ||
              site.location.toLowerCase().contains(query) ||
              site.category.toLowerCase().contains(query);

      return categoryMatch && searchMatch;
    }).toList();
  }

  HeritageSite? get _editorPick {
    if (_sites.isEmpty) {
      return null;
    }

    for (final HeritageSite site in _sites) {
      if (site.isEditorPick) {
        return site;
      }
    }

    for (final HeritageSite site in _sites) {
      if (site.category.toLowerCase() == 'unesco') {
        return site;
      }
    }

    return _sites.first;

  }
  void _openHeritageDetail(HeritageSite site) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HeritageDetailScreen(
          site: site,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: "Traveller's Guide",
              subtitle: 'Heritage Sites · Travel Info',
              xp: '${widget.totalXp}',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: SegmentedTabBar(
                selectedIndex: _selectedTabIndex,
                labels: const [
                  '🏛 Heritage Sites',
                  '🎫 Travel Info',
                ],
                onChanged: (int index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: _selectedTabIndex == 1
                  ? TravelInfoPage(
                totalXp: widget.totalXp,
              )
                  : _buildHeritageSitesView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        selected: BottomTab.home,
        onSelect: (BottomTab tab) {
          if (tab == BottomTab.home) {
            Navigator.pop(context);
            return;
          }

          widget.onTabSelected(tab);

          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildHeritageSitesView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHeritage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final List<HeritageSite> displaySites =
        _filteredSites;

    final HeritageSite? editorPick =
        _editorPick;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: SearchBarField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder:
                (BuildContext context, int index) {
              return const SizedBox(width: 8);
            },
            itemBuilder:
                (BuildContext context, int index) {
              final String category =
              _categories[index];

              return CategoryChip(
                label: category,
                selected:
                _selectedCategory == category,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        Expanded(
          child: displaySites.isEmpty
              ? Center(
            child: Text(
              "No heritage sites found matching '${_searchController.text}'",
              style: const TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          )
              : ListView(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            children: [
              if (editorPick != null &&
                  _searchController.text
                      .trim()
                      .isEmpty &&
                  _selectedCategory ==
                      'All') ...[
                const Text(
                  "Editor's Pick",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                GestureDetector(
                  onTap: () {
                    _openHeritageDetail(editorPick);
                  },
                  child: EditorPickCard(
                    site: editorPick,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],

              Text(
                '${displaySites.length} sites found',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 12),

              ...displaySites.map(
                    (HeritageSite site) =>
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _openHeritageDetail(site);
                        },
                        child: SiteCard(
                          site: site,
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Segmented Tab Bar
// ============================================================

class SegmentedTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const SegmentedTabBar({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(
          labels.length,
              (int index) {
            final bool selected =
                selectedIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  onChanged(index);
                },
                child: Container(
                  margin:
                  const EdgeInsets.all(4),
                  decoration:
                  BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Search Bar
// ============================================================

class SearchBarField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBarField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText:
        'Search sites, states, categories...',
        prefixIcon:
        const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius:
          BorderRadius.circular(15),
        ),
      ),
    );
  }
}

// ============================================================
// Category Chip
// ============================================================

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  Color _getColor() {
    switch (label) {
      case 'UNESCO':
        return const Color(0xFF2563EB);

      case 'Religious':
        return const Color(0xFFB8720A);

      case 'Nature':
        return const Color(0xFF16A34A);

      case 'National':
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF0F8A5F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color categoryColor =
    _getColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? categoryColor
              : Colors.white,
          borderRadius:
          BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? categoryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.black,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Tag Pill
// ============================================================

class TagPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const TagPill({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ============================================================
// Editor Pick Card
// ============================================================

class EditorPickCard
    extends StatelessWidget {
  final HeritageSite site;

  const EditorPickCard({
    super.key,
    required this.site,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(0xFF63D6A5),
            Color(0xFF159B72),
          ],
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              TagPill(
                label: site.category,
                background:
                Colors.white.withOpacity(
                  0.18,
                ),
                textColor: Colors.white,
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color: const Color(
                    0xFFF5A623,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  '+${site.xp} XP',
                  style:
                  const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            site.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight:
              FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            site.location,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            site.description,
            maxLines: 2,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white
                  .withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Heritage Site Card
// ============================================================

class SiteCard extends StatelessWidget {
  final HeritageSite site;

  const SiteCard({
    super.key,
    required this.site,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          Colors.green.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color:
              const Color(0xFFFFEFC8),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: site.imageUrl.isNotEmpty
                ? Image.network(
              site.imageUrl,
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                  ) {
                return const Icon(
                  Icons.account_balance,
                  color: Colors.grey,
                );
              },
            )
                : const Icon(
              Icons.account_balance,
              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        site.name,
                        style:
                        const TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Text(
                      '+${site.xp} XP',
                      style:
                      const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.bold,
                        color: Color(
                          0xFF16A34A,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  site.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  site.description,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                    Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TagPill(
                      label:
                      site.category,
                      background:
                      const Color(
                        0xFFFDECC8,
                      ),
                      textColor:
                      const Color(
                        0xFFB8720A,
                      ),
                    ),

                    ...site.tags
                        .where(
                          (String tag) =>
                      tag !=
                          site.category,
                    )
                        .map(
                          (
                          String tag,
                          ) =>
                          TagPill(
                            label: tag,
                            background:
                            const Color(
                              0xFFF0F0F0,
                            ),
                            textColor:
                            Colors.grey
                                .shade700,
                          ),
                    ),

                    if (site.visited)
                      const TagPill(
                        label:
                        '✓ Visited',
                        background:
                        Color(
                          0xFFE9F9EF,
                        ),
                        textColor:
                        Color(
                          0xFF16A34A,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}