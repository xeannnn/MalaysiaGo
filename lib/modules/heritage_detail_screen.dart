import 'package:flutter/material.dart';
import '../models.dart';

class HeritageDetailScreen extends StatelessWidget {
  final HeritageSite site;

  const HeritageDetailScreen({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Placeholder / Container
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_balance,
                size: 80,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),

            // Site Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    site.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(site.category),
                  backgroundColor: Colors.teal.shade50,
                  side: BorderSide(color: Colors.teal.shade200),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location & UNESCO Tag
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.teal, size: 20),
                const SizedBox(width: 4),
                Text('${site.state}, Malaysia',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.verified, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('UNESCO (${site.unescoYear})'),
              ],
            ),
            const Divider(height: 32),

            // Description
            const Text(
              'About this Site',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              site.description,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Coordinates & Action Button
            Card(
              color: Colors.grey.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.map, color: Colors.teal),
                title: const Text('Coordinates'),
                subtitle: Text(site.locationCoordinates),
                trailing: ElevatedButton(
                  onPressed: () {
                    // Trigger map navigation in mappage.dart
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('View Map', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
