import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  Future<void> _openScanner(BuildContext context) async {
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const FullScreenScannerPage(),
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (result != null && result.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR scanned successfully: $result',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.maybePop(context);
                    },
                    child: const Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w500,
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
                  const SizedBox(width: 50),
                ],
              ),
            ),

            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.15,
                    child: Icon(
                      Icons.account_balance,
                      size: 100,
                      color:
                      Colors.cyanAccent.shade100,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      children: [
                        _buildCornerBracket(
                          top: 0,
                          left: 0,
                          isTop: true,
                          isLeft: true,
                        ),
                        _buildCornerBracket(
                          top: 0,
                          right: 0,
                          isTop: true,
                          isLeft: false,
                        ),
                        _buildCornerBracket(
                          bottom: 0,
                          left: 0,
                          isTop: false,
                          isLeft: true,
                        ),
                        _buildCornerBracket(
                          bottom: 0,
                          right: 0,
                          isTop: false,
                          isLeft: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius:
                        BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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

                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(14),
                      gradient:
                      const LinearGradient(
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF0D9488),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF10B981,
                          ).withOpacity(0.3),
                          blurRadius: 10,
                          offset:
                          const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openScanner(context);
                      },
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.transparent,
                        shadowColor:
                        Colors.transparent,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Start Scanning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Nearby sites with QR codes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                    ),
                  ),

                  const SizedBox(height: 10),

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

  Widget _buildCornerBracket({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    const double length = 36;
    const double thickness = 4;
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

  Widget _buildNearbySiteTile({
    required String emoji,
    required String title,
    required String xp,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
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

class FullScreenScannerPage
    extends StatefulWidget {
  const FullScreenScannerPage({
    super.key,
  });

  @override
  State<FullScreenScannerPage>
  createState() =>
      _FullScreenScannerPageState();
}

class _FullScreenScannerPageState
    extends State<FullScreenScannerPage> {
  final MobileScannerController _controller =
  MobileScannerController(
    detectionSpeed:
    DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  Timer? _timer;

  int _secondsRemaining = 30;

  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (Timer timer) {
        if (!mounted ||
            _hasFinished) {
          timer.cancel();
          return;
        }

        if (_secondsRemaining <= 1) {
          setState(() {
            _secondsRemaining = 0;
          });

          timer.cancel();

          _finishScanner();
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  Future<void> _finishScanner({
    String? result,
  }) async {
    if (_hasFinished) {
      return;
    }

    _hasFinished = true;

    _timer?.cancel();

    try {
      await _controller.stop();
    } catch (_) {
      // Ignore camera stop errors while closing.
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      result,
    );
  }

  Future<void> _handleBarcode(
      BarcodeCapture capture,
      ) async {
    if (_hasFinished) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final Barcode barcode =
        capture.barcodes.first;

    final String? value =
        barcode.rawValue;

    if (value == null ||
        value.trim().isEmpty) {
      return;
    }

    await _finishScanner(
      result: value,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult:
          (bool didPop, Object? result) {
        if (didPop) {
          _timer?.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
              errorBuilder: (
                  BuildContext context,
                  MobileScannerException error,
                  ) {
                return Container(
                  color: Colors.black,
                  alignment:
                  Alignment.center,
                  padding:
                  const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        'Unable to open camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        error.toString(),
                        textAlign:
                        TextAlign.center,
                        style: const TextStyle(
                          color:
                          Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Container(
              color: Colors.black
                  .withOpacity(0.12),
            ),

            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                  border: Border.all(
                    color:
                    Colors.greenAccent,
                    width: 3,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Container(
                      decoration:
                      const BoxDecoration(
                        color:
                        Colors.black54,
                        shape:
                        BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          _finishScanner();
                        },
                        icon: const Icon(
                          Icons.close,
                          color:
                          Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.black54,
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                      child: Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color:
                            Colors.white,
                            size: 18,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            '$_secondsRemaining s',
                            style:
                            const TextStyle(
                              color:
                              Colors.white,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 24,
              right: 24,
              bottom: 70,
              child: Container(
                padding:
                const EdgeInsets.all(
                  14,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.black54,
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Text(
                      'Scan Heritage QR',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color:
                        Colors.white,
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Place the QR code inside the green frame.\nScanner closes automatically after 30 seconds.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color:
                        Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}