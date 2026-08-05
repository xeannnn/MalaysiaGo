import 'package:flutter/material.dart';
import '../models.dart';

class HeritageSearchScreen extends StatefulWidget {
  final List<HeritageSite> sites;

  const HeritageSearchScreen({
    super.key,
    this.sites = sampleHeritageSites,
  });

  @override
  State<HeritageSearchScreen> createState() => _HeritageSearchScreenState();
}

class _HeritageSearchScreenState extends State<HeritageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HeritageSite> _filteredSites = [];
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Historical',
    'Natural',
    'Cultural'
  ];

  @override
  void initState() {
    super.initState();
    _filteredSites = widget.sites;
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSites = widget.sites.where((site) {
        final matchesQuery = site.name.toLowerCase().contains(query) ||
            site.state.toLowerCase().contains(query) ||
            site.category.toLowerCase().contains(query) ||
            site.description.toLowerCase().contains(query);

        final matchesCategory = _selectedCategory == 'All' ||
            site.category.toLowerCase() == _selectedCategory.toLowerCase();

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Heritage Sites'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Input Field
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by site, state, or category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: Colors.teal.shade100,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _applyFilter();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results List View
          Expanded(
            child: _filteredSites.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No heritage sites found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSites.length,
                    itemBuilder: (context, index) {
                      final site = _filteredSites[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.teal.shade50,
                            ),
                            child: const Icon(Icons.account_balance,
                                color: Colors.teal),
                          ),
                          title: Text(
                            site.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${site.state} • ${site.category}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(site.rating.toString()),
                            ],
                          ),
                          onTap: () {
                            // Navigate to details screen or perform action
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
