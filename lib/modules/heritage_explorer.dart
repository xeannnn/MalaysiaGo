import 'package:flutter/material.dart';

import '../models.dart';
import 'travel_info.dart';
import '../services/heritage_api_service.dart';
import '../services/heritage_api_service.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_header.dart';
import 'travel_info.dart';

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
  String _selectedCategory = "All";
  final TextEditingController _searchController = TextEditingController();

  List<HeritageSite> _sites = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _categories = [
    'All',
    'UNESCO',
    'Religious',
    'Nature',
    'National',
  static const List<String> _categories = [
    "All",
    "UNESCO",
    "Religious",
    "Nature",
    "National",
  ];

  List<HeritageSite> _sites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHeritage();
  }

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

  /// Initial load from API
  Future<void> _loadHeritage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await HeritageApiService.fetchMalaysiaHeritage();
      if (mounted) {
        setState(() {
          _sites = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Heritage API Error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load heritage sites.";
          _isLoading = false;
        });
      }
    }
  }

  /// In-memory filter matching category + local search text
  List<HeritageSite> get _filteredSites {
    final query = _searchController.text.trim().toLowerCase();

    return _sites.where((site) {
      final matchesCategory =
          _selectedCategory == 'All' || site.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
      final categoryMatch =
          _selectedCategory == "All" ||
          site.category.toLowerCase() == _selectedCategory.toLowerCase();

      final searchMatch =
          query.isEmpty ||
          site.name.toLowerCase().contains(query) ||
          site.location.toLowerCase().contains(query);

      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: "Traveller's Guide",
              subtitle: "Heritage Sites · Travel Info",
              xp: "${widget.totalXp}",
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedTabBar(
                selectedIndex: _selectedTabIndex,
                labels: const ["🏛 Heritage Sites", "🎫 Travel Info"],
                onChanged: (index) {
                  setState(() => _selectedTabIndex = index);
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
        onSelect: (tab) {
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
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final displaySites = _filteredSites;

    // Safely retrieve editor pick or fallback
    final HeritageSite? editorPick = _sites.isNotEmpty
        ? _sites.where((site) => site.category == "UNESCO").firstOrNull ??
        _sites[0]
    // Safely retrieve editor pick or fallback without index out of bounds error
    final HeritageSite? editorPick = _sites.isNotEmpty
        ? _sites.where((site) => site.category == "UNESCO").firstOrNull ??
              _sites[0]
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SearchBarField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onChanged: (value) {
              // Local instantaneous filtering
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CategoryChip(
                label: category,
                selected: _selectedCategory == category,
                onTap: () {
                  setState(() => _selectedCategory = category);
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
              style: const TextStyle(color: Colors.grey),
            ),
          )
              : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (editorPick != null &&
                  _searchController.text.isEmpty &&
                  _selectedCategory == "All") ...[
                const Text(
                  "Editor's Pick",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                EditorPickCard(site: editorPick),
                const SizedBox(height: 20),
              ],
              Text(
                "${displaySites.length} sites found",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ...displaySites.map(
                    (site) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SiteCard(site: site),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- Segmented tab (Heritage Sites / Travel Info) ----------
                  child: Text(
                    "No heritage sites found matching '${_searchController.text}'",
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (editorPick != null &&
                        _searchController.text.isEmpty &&
                        _selectedCategory == "All") ...[
                      const Text(
                        "Editor's Pick",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      EditorPickCard(site: editorPick),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      "${displaySites.length} sites found",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ...displaySites.map(
                      (site) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SiteCard(site: site),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------- Sub-Widgets ----------

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
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
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
        hintText: "Search sites, states, categories...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}

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

  static const Map<String, Color> _categoryColors = {
    'UNESCO': Color(0xFF2563EB),
    'Religious': Color(0xFFB8720A),
    'Nature': Color(0xFF16A34A),
    'National': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
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

// ---------- Small status/tag pill used on cards ----------
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
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

// ---------- Editor's Pick large card ----------
class EditorPickCard extends StatelessWidget {
  final HeritageSite site;

  const EditorPickCard({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff63D6A5), Color(0xff159B72)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const TagPill(label: '📍', background: Colors.transparent, textColor: Colors.white),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF5A623), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '+${site.xp} XP',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          TagPill(text: site.category),
          const Spacer(),
          Text(
            site.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            site.location,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            site.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            '${site.location} · ${site.description}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

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
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFDECC8),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: site.imageUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                site.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.account_balance, color: Colors.grey);
                },
              ),
            )
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xffffefc8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: site.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),

                    child: Image.network(
                      site.imageUrl,

                      width: 55,

                      height: 55,

                      fit: BoxFit.cover,

                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.account_balance,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(Icons.account_balance, color: Colors.grey),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        site.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '+${site.xp} XP',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
                Text(site.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  site.description,
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
                    ...site.tags.where((t) => t != site.category).map(
                          (t) => TagPill(
                        label: t,
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
                Text(
                  site.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  site.location,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  site.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TagPill(text: site.category),
              ],
            ),
          ),
          Text(
            "+${site.xp} XP",
            style: const TextStyle(color: Colors.green, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class TagPill extends StatelessWidget {
  final String text;

  const TagPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffffe6a8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }
}
