import 'package:flutter/material.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark top camera background
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle back action if needed
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'QR Scanner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 50), // Balance header layout
                ],
              ),
            ),

            // Camera View Finder Area
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle building silhouette icon in center
                  Opacity(
                    opacity: 0.15,
                    child: Icon(
                      Icons.account_balance,
                      size: 100,
                      color: Colors.cyanAccent.shade100,
                    ),
                  ),

                  // Camera Target Corners Overlay
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      children: [
                        _buildCornerBracket(top: 0, left: 0, isTop: true, isLeft: true),
                        _buildCornerBracket(top: 0, right: 0, isTop: true, isLeft: false),
                        _buildCornerBracket(bottom: 0, left: 0, isTop: false, isLeft: true),
                        _buildCornerBracket(bottom: 0, right: 0, isTop: false, isLeft: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom White Sheet Content
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle indicator bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Text
                  const Text(
                    'Scan Heritage QR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Point your camera at the QR code at any MalaysiaGO heritage site to earn XP and unlock passport pieces.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start Scanning Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Action for scanner
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      label: const Text(
                        'Start Scanning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nearby Sites Header
                  const Text(
                    'Nearby sites with QR codes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nearby List Items
                  _buildNearbySiteTile(
                    emoji: '⛩️',
                    title: 'Batu Caves',
                    xp: '+80 XP',
                  ),
                  const SizedBox(height: 8),
                  _buildNearbySiteTile(
                    emoji: '🗽',
                    title: 'Merdeka Square',
                    xp: '+60 XP',
                  ),
                  const SizedBox(height: 8),
                  _buildNearbySiteTile(
                    emoji: '🏛️',
                    title: 'Sultan Abdul Samad',
                    xp: '+70 XP',
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Corner brackets helper for camera overlay
  Widget _buildCornerBracket({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    const double length = 36.0;
    const double thickness = 4.0;
    const Color color = Color(0xFF22C55E);

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: SizedBox(
        width: length,
        height: length,
        child: Stack(
          children: [
            Positioned(
              top: isTop ? 0 : null,
              bottom: !isTop ? 0 : null,
              left: 0,
              right: 0,
              child: Container(
                height: thickness,
                color: color,
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: isLeft ? 0 : null,
              right: !isLeft ? 0 : null,
              child: Container(
                width: thickness,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nearby site item tile
  Widget _buildNearbySiteTile({
    required String emoji,
    required String title,
    required String xp,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Text(
            xp,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}