import 'package:flutter/material.dart';
import '../models.dart';
import '../services/heritage_service.dart';
import 'heritage_detail_screen.dart';

class HeritageListScreen extends StatefulWidget {
  const HeritageListScreen({super.key});

  @override
  State<HeritageListScreen> createState() => _HeritageListScreenState();
}

class _HeritageListScreenState extends State<HeritageListScreen> {
  late Future<List<HeritageSite>> _futureSites;
  final HeritageService _heritageService = HeritageService();

  @override
  void initState() {
    super.initState();
    _futureSites = _heritageService.fetchHeritageSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malaysia Heritage Sites'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<HeritageSite>>(
        future: _futureSites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No heritage sites found.'));
          }

          final sites = snapshot.data!;
          return ListView.builder(
            itemCount: sites.length,
            itemBuilder: (context, index) {
              final site = sites[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    site.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    style: TextStyle(color: Colors.grey.shade700),
                    child: Text('${site.state} • Inscribed ${site.unescoYear}'),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HeritageDetailScreen(site: site),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
