import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import '../../data/models/badge.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'premium_badge_widget.dart';

class BadgePopup extends StatefulWidget {
  final BadgeModel badge;
  const BadgePopup({super.key, required this.badge});

  @override
  State<BadgePopup> createState() => _BadgePopupState();
}

class _BadgePopupState extends State<BadgePopup>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();

    // Rotation (Continuous)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Slow 3D rotation
    )..repeat(); // Loop
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background Card
          Container(
            width: 320,
            height: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Badge Entrance + Spin
                // Scale Entrance
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // Perspective
                              ..rotateY(
                                _rotationController.value * 2 * math.pi,
                              ),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                        child: PremiumBadgeWidget(
                          badge: widget.badge,
                          size: 160,
                          showLabel: false,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Text
                Text(
                  "恭喜获得勋章",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    color: Colors.grey[600],
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.badge.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.badge.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.amber[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        "关闭",
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Resimulate confetti
                        _confettiController.stop();
                        _confettiController.play();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        "再放一次",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Confetti (Top Center relative to Dialog)
          Positioned(
            top: -20,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.amber,
              ],
              createParticlePath: drawStar,
            ),
          ),

          // Close button top right
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (math.pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = 360 / numberOfPoints;
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = 360.0;
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * math.cos(degToRad(step)),
        halfWidth + externalRadius * math.sin(degToRad(step)),
      );
      path.lineTo(
        halfWidth +
            internalRadius * math.cos(degToRad(step + halfDegreesPerStep)),
        halfWidth +
            internalRadius * math.sin(degToRad(step + halfDegreesPerStep)),
      );
    }
    path.close();
    return path;
  }
}
