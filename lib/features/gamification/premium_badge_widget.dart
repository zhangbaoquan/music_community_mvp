import 'package:flutter/material.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import '../../data/models/badge.dart';
import 'dart:math' as math;

class PremiumBadgeWidget extends StatelessWidget {
  final BadgeModel badge;
  final double size;
  final bool showLabel;

  const PremiumBadgeWidget({
    super.key,
    required this.badge,
    this.size = 120,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer/Base Hexagon (Darker Gold for side/depth)
              Transform.translate(
                offset: const Offset(0, 4), // Fake depth
                child: ClipPath(
                  clipper: HexagonClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFB8860B), // Dark GoldenRod
                          const Color(0xFFDAA520), // GoldenRod
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Main Hexagon (Shiny Gold)
              ClipPath(
                clipper: HexagonClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFFD700), // Gold
                        const Color(0xFFFDB931),
                        const Color(0xFFFFD700),
                        const Color(0xFFFDB931),
                      ],
                      stops: const [0.0, 0.4, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4), // Inner Border width
                    decoration: BoxDecoration(
                      // Inner face
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: [
                          const Color(0xFFFFE57C), // Lighter Gold
                          const Color(0xFFDAA520),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Shine effect
                        Positioned(
                          top: -size / 2,
                          left: -size / 2,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),

                        // Icon & Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(size * 0.1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons
                                      .emoji_events, // TODO: Map icon_url to real icons
                                  size: size * 0.35,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 16),
          Text(
            badge.name,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ],
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final r = width / 2;

    // Flat Topped Hexagon? Or Pointy?
    // Usually vertical hexagon (pointy top) looks better for badges.
    // Points: (w/2, 0), (w, h*0.25), (w, h*0.75), (w/2, h), (0, h*0.75), (0, h*0.25)

    path.moveTo(width / 2, 0);
    path.lineTo(width, height * 0.25);
    path.lineTo(width, height * 0.75);
    path.lineTo(width / 2, height);
    path.lineTo(0, height * 0.75);
    path.lineTo(0, height * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
