import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/image_service.dart';
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
  State<HeritageExplorerScreen> createState() => _HeritageExplorerScreenState();
}

class _HeritageExplorerScreenState extends State<HeritageExplorerScreen> {
  int _selectedTabIndex = 0;
  Set<String> _selectedStates = <String>{'All'};
  Set<String> _selectedCategories = <String>{'All'};

  final TextEditingController _searchController = TextEditingController();

  final PageController _editorPageController = PageController();
  Timer? _editorAutoTimer;
  int _currentEditorPage = 0;

  List<HeritageSite> _sites = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Search is only applied after the user submits a valid keyword.
  String _submittedSearch = '';
  String? _searchMessage;

  static const List<String> _states = [
    'All',
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Putrajaya',
    'Labuan',
  ];

  static const List<String> _categories = [
    'All',
    'UNESCO',
    'Religious',
    'Historical',
    'Archaeological',
    'Museum',
    'Royal',
    'Nature',
    'National',
    'Modern',
  ];

  @override
  void initState() {
    super.initState();
    _loadHeritage();
    _startEditorAutoSwipe();
  }

  void _startEditorAutoSwipe() {
    _editorAutoTimer?.cancel();

    _editorAutoTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final List<HeritageSite> picks = _editorPicks;

      if (!mounted || picks.length <= 1 || !_editorPageController.hasClients) {
        return;
      }

      final int nextPage = (_currentEditorPage + 1) % picks.length;

      _editorPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _editorAutoTimer?.cancel();
    _editorPageController.dispose();
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

  void _submitSearch() {
    final String query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchMessage = 'Please enter a search keyword.';
        _submittedSearch = '';
      });
      return;
    }

    if (query.length < 3) {
      setState(() {
        _searchMessage = 'Please enter at least 3 characters.';
        _submittedSearch = '';
      });
      return;
    }

    setState(() {
      _searchMessage = null;
      _submittedSearch = query;
      _selectedStates = <String>{'All'};
      _selectedCategories = <String>{'All'};
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _submittedSearch = '';
      _searchMessage = null;
      _selectedStates = <String>{'All'};
      _selectedCategories = <String>{'All'};
    });
  }

  bool _matchesSelectedState(HeritageSite site) {
    if (_selectedStates.contains('All')) {
      return true;
    }

    final String location = site.location.toLowerCase();

    for (final String state in _selectedStates) {
      if (state == 'Penang' &&
          (location.contains('penang') || location.contains('pulau pinang'))) {
        return true;
      }

      if (state == 'Melaka' &&
          (location.contains('melaka') || location.contains('malacca'))) {
        return true;
      }

      if (location.contains(state.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  List<HeritageSite> get _searchResults {
    final String query = _submittedSearch.trim().toLowerCase();

    return _sites.where((HeritageSite site) {
      return query.isEmpty ||
          site.name.toLowerCase().contains(query) ||
          site.location.toLowerCase().contains(query) ||
          site.category.toLowerCase().contains(query);
    }).toList();
  }

  bool _matchesSelectedCategory(HeritageSite site) {
    if (_selectedCategories.contains('All')) {
      return true;
    }

    return _selectedCategories.any(
          (String category) =>
      site.category.toLowerCase() == category.toLowerCase(),
    );
  }

  List<HeritageSite> get _filteredSites {
    return _searchResults.where((HeritageSite site) {
      return _matchesSelectedState(site) && _matchesSelectedCategory(site);
    }).toList();
  }

  bool get _hasActiveFilters {
    return !_selectedStates.contains('All') ||
        !_selectedCategories.contains('All');
  }

  int get _activeFilterCount {
    int count = 0;

    if (!_selectedStates.contains('All')) {
      count += _selectedStates.length;
    }

    if (!_selectedCategories.contains('All')) {
      count += _selectedCategories.length;
    }

    return count;
  }

  void _removeStateFilter(String state) {
    setState(() {
      _selectedStates.remove(state);

      if (_selectedStates.isEmpty) {
        _selectedStates.add('All');
      }
    });
  }

  void _removeCategoryFilter(String category) {
    setState(() {
      _selectedCategories.remove(category);

      if (_selectedCategories.isEmpty) {
        _selectedCategories.add('All');
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStates = <String>{'All'};
      _selectedCategories = <String>{'All'};
    });
  }

  Future<void> _openFilterSheet() async {
    Set<String> tempStates = Set<String>.from(_selectedStates);
    Set<String> tempCategories = Set<String>.from(_selectedCategories);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Filter Heritage Sites',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(bottomSheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'State',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _states.map((String state) {
                          return FilterChip(
                            label: Text(state),
                            selected: tempStates.contains(state),
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (state == 'All') {
                                  tempStates = <String>{'All'};
                                } else {
                                  tempStates.remove('All');
                                  if (selected) {
                                    tempStates.add(state);
                                  } else {
                                    tempStates.remove(state);
                                  }
                                  if (tempStates.isEmpty) {
                                    tempStates.add('All');
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((String category) {
                          return FilterChip(
                            label: Text(category),
                            selected: tempCategories.contains(category),
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (category == 'All') {
                                  tempCategories = <String>{'All'};
                                } else {
                                  tempCategories.remove('All');
                                  if (selected) {
                                    tempCategories.add(category);
                                  } else {
                                    tempCategories.remove(category);
                                  }
                                  if (tempCategories.isEmpty) {
                                    tempCategories.add('All');
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempStates = <String>{'All'};
                                  tempCategories = <String>{'All'};
                                });
                              },
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStates = Set<String>.from(
                                    tempStates,
                                  );
                                  _selectedCategories = Set<String>.from(
                                    tempCategories,
                                  );
                                });
                                Navigator.pop(bottomSheetContext);
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<HeritageSite> get _editorPicks {
    if (_sites.isEmpty) {
      return <HeritageSite>[];
    }

    final List<HeritageSite> picks = <HeritageSite>[];
    final Set<String> usedIds = <String>{};

    void addSite(HeritageSite site) {
      if (usedIds.add(site.id)) {
        picks.add(site);
      }
    }

    // 1. Prefer sites explicitly marked by the data source.
    for (final HeritageSite site in _sites) {
      if (site.isEditorPick) {
        addSite(site);
      }
    }

    // 2. Add UNESCO sites for strong nationwide variety.
    for (final HeritageSite site in _sites) {
      if (site.category.toLowerCase() == 'unesco') {
        addSite(site);
      }
    }

    // 3. Fill remaining slots with other sites.
    for (final HeritageSite site in _sites) {
      addSite(site);
      if (picks.length >= 6) {
        break;
      }
    }

    return picks.take(6).toList();
  }

  Future<void> _openHeritageDetail(HeritageSite site) async {
    final BottomTab? requestedTab = await Navigator.push<BottomTab>(
      context,
      MaterialPageRoute(
        builder: (_) => HeritageDetailScreen(site: site),
      ),
    );

    if (!mounted || requestedTab == null) {
      return;
    }

    // Heritage Detail asked to open one of the main app tabs.
    widget.onTabSelected(requestedTab);

    // Close Heritage Explorer so the user returns to the app's main shell,
    // where the selected bottom-navigation tab is displayed normally.
    Navigator.pop(context);
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedTabBar(
                selectedIndex: _selectedTabIndex,
                labels: const ['🏛 Heritage Sites', '🎫 Travel Info'],
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
                  ? TravelInfoPage(totalXp: widget.totalXp)
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHeritage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final List<HeritageSite> displaySites = _filteredSites;

    final List<HeritageSite> editorPicks = _editorPicks;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CombinedSearchFilterBar(
            controller: _searchController,
            onSearch: _submitSearch,
            onClearSearch: _clearSearch,
            onFilterTap: _openFilterSheet,
            activeFilterCount: _activeFilterCount,
          ),
        ),

        if (_searchMessage != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _searchMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ],

        if (_hasActiveFilters) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._selectedStates
                          .where((String state) => state != 'All')
                          .map(
                            (String state) => InputChip(
                          avatar: const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                          ),
                          label: Text(
                            state,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          onDeleted: () => _removeStateFilter(state),
                        ),
                      ),
                      ..._selectedCategories
                          .where((String category) => category != 'All')
                          .map(
                            (String category) => InputChip(
                          avatar: const Icon(
                            Icons.category_outlined,
                            size: 15,
                          ),
                          label: Text(
                            category,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          onDeleted: () => _removeCategoryFilter(category),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        Expanded(
          child: displaySites.isEmpty
              ? Center(
            child: Text(
              _submittedSearch.isNotEmpty
                  ? 'No heritage sites found matching "$_submittedSearch".'
                  : 'No heritage sites found for the selected filters.',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
              : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (editorPicks.isNotEmpty &&
                  _submittedSearch.isEmpty &&
                  _selectedStates.contains('All') &&
                  _selectedCategories.contains('All')) ...[
                Row(
                  children: [
                    const Text(
                      "Editor's Picks",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentEditorPage + 1}/${editorPicks.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 210,
                  child: PageView.builder(
                    controller: _editorPageController,
                    itemCount: editorPicks.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _currentEditorPage = index;
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final HeritageSite site = editorPicks[index];

                      return GestureDetector(
                        onTap: () => _openHeritageDetail(site),
                        child: EditorPickCard(site: site),
                      );
                    },
                  ),
                ),

                if (editorPicks.length > 1) ...[
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(editorPicks.length, (
                        int index,
                        ) {
                      final bool selected = index == _currentEditorPage;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: selected ? 18 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF159B72)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 5),
                  const Center(
                    child: Text(
                      'Swipe left or right · Auto changes every 15 seconds',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],

              Text(
                '${displaySites.length} sites found',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 12),

              ...displaySites.map(
                    (HeritageSite site) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      _openHeritageDetail(site);
                    },
                    child: SiteCard(site: site),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (int index) {
          final bool selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                onChanged(index);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
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
        }),
      ),
    );
  }
}

// ============================================================
// Search Bar
// ============================================================

class CombinedSearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  const CombinedSearchFilterBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClearSearch,
    required this.onFilterTap,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFilters = activeFilterCount > 0;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder:
                  (
                  BuildContext context,
                  TextEditingValue value,
                  Widget? child,
                  ) {
                return TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search heritage sites...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 21),
                    suffixIcon: value.text.trim().isNotEmpty
                        ? IconButton(
                      onPressed: onClearSearch,
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 19),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 10),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasFilters ? const Color(0xFFE9F9F1) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasFilters
                      ? const Color(0xFF159B72)
                      : Colors.grey.shade200,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune,
                    size: 22,
                    color: hasFilters
                        ? const Color(0xFF159B72)
                        : Colors.black87,
                  ),

                  if (hasFilters)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF159B72),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Category Chip
// ============================================================

class StateFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const StateFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color selectedColor = Color(0xFF0F8A5F);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
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

class EditorPickCard extends StatelessWidget {
  final HeritageSite site;

  const EditorPickCard({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF159B72),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          EditorPickImage(site: site),

          // Keeps the text readable while preserving the large image.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.42, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),

          Positioned(
            top: 14,
            left: 14,
            child: TagPill(
              label: site.category,
              background: Colors.white.withValues(alpha: 0.88),
              textColor: const Color(0xFF0F8A5F),
            ),
          ),

          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '+${site.xp} XP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  site.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        site.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  site.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditorPickImage extends StatefulWidget {
  final HeritageSite site;

  const EditorPickImage({super.key, required this.site});

  @override
  State<EditorPickImage> createState() => _EditorPickImageState();
}

class _EditorPickImageState extends State<EditorPickImage> {
  String _imageUrl = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.site.imageUrl.trim().isNotEmpty) {
      if (!mounted) return;

      setState(() {
        _imageUrl = widget.site.imageUrl;
        _loading = false;
      });
      return;
    }

    final String imageUrl = await ImageService.getHeritageImage(
      widget.site.name,
      location: widget.site.location,
      siteId: widget.site.id,
      existingImageUrl: widget.site.imageUrl,
    );

    if (!mounted) return;

    setState(() {
      _imageUrl = imageUrl;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: const Color(0xFFEAF8F1),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFEAF8F1),
        alignment: Alignment.center,
        child: const Icon(
          Icons.account_balance,
          size: 42,
          color: Color(0xFF159B72),
        ),
      );
    }

    return Image.network(
      _imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFEAF8F1),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 38,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}

class HeritageSiteThumbnail extends StatefulWidget {
  final HeritageSite site;

  const HeritageSiteThumbnail({super.key, required this.site});

  @override
  State<HeritageSiteThumbnail> createState() => _HeritageSiteThumbnailState();
}

class _HeritageSiteThumbnailState extends State<HeritageSiteThumbnail> {
  String _imageUrl = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.site.imageUrl.trim().isNotEmpty) {
      if (!mounted) return;

      setState(() {
        _imageUrl = widget.site.imageUrl;
        _loading = false;
      });
      return;
    }

    final imageUrl = await ImageService.getHeritageImage(
      widget.site.name,
      location: widget.site.location,
      siteId: widget.site.id,
      existingImageUrl: widget.site.imageUrl,
    );

    if (!mounted) return;

    setState(() {
      _imageUrl = imageUrl;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_imageUrl.isEmpty) {
      return const Icon(Icons.account_balance, color: Colors.grey);
    }

    return Image.network(
      _imageUrl,
      width: 55,
      height: 55,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.account_balance, color: Colors.grey);
      },
    );
  }
}

// ============================================================
// Heritage Site Card
// ============================================================

class SiteCard extends StatelessWidget {
  final HeritageSite site;

  const SiteCard({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFC8),
              borderRadius: BorderRadius.circular(15),
            ),
            clipBehavior: Clip.antiAlias,
            child: HeritageSiteThumbnail(site: site),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        site.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      '+${site.xp} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  site.location,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 6),

                Text(
                  site.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TagPill(
                      label: site.category,
                      background: const Color(0xFFFDECC8),
                      textColor: const Color(0xFFB8720A),
                    ),

                    ...site.tags
                        .where((String tag) => tag != site.category)
                        .map(
                          (String tag) => TagPill(
                        label: tag,
                        background: const Color(0xFFF0F0F0),
                        textColor: Colors.grey.shade700,
                      ),
                    ),

                    if (site.visited)
                      const TagPill(
                        label: '✓ Visited',
                        background: Color(0xFFE9F9EF),
                        textColor: Color(0xFF16A34A),
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