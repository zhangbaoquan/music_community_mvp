import 'package:flutter/material.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import '../../data/models/badge.dart';
import 'dart:math' as math;

class PremiumBadgeWidget extends StatelessWidget {
  final BadgeModel badge;
  final double size;
  final bool showLabel;
  final bool isLocked;

  const PremiumBadgeWidget({
    super.key,
    required this.badge,
    this.size = 120,
    this.showLabel = true,
    this.isLocked = false,
  });

  IconData _getIconData(String? iconUrl) {
    if (iconUrl == null) return Icons.star;
    if (iconUrl.contains('first_voice')) return Icons.mic;
    if (iconUrl.contains('scribe')) return Icons.edit_note;
    if (iconUrl.contains('resonator')) return Icons.forum;
    if (iconUrl.contains('popularity')) return Icons.favorite;
    if (iconUrl.contains('community')) return Icons.people;
    return Icons.emoji_events;
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(badge.iconUrl);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer/Base Hexagon (Darker Silver for depth)
              Transform.translate(
                offset: const Offset(0, 4), // Fake depth
                child: ClipPath(
                  clipper: HexagonClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isLocked
                          ? const LinearGradient(
                              colors: [Color(0xFFBDBDBD), Color(0xFFE0E0E0)],
                            ) // Light Grey
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFB8860B), // Dark GoldenRod
                                Color(0xFFDAA520), // GoldenRod
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              // Main Hexagon (Shiny Silver/Gold)
              ClipPath(
                clipper: HexagonClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isLocked
                        ? const LinearGradient(
                            colors: [Color(0xFFEEEEEE), Color(0xFFF5F5F5)],
                          ) // Very Light Silver / White
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD700), // Gold
                              Color(0xFFFDB931),
                              Color(0xFFFFD700),
                              Color(0xFFFDB931),
                            ],
                            stops: [0.0, 0.4, 0.6, 1.0],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.15,
                        ), // Softer shadow for locked
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4), // Inner Border width
                    decoration: BoxDecoration(
                      // Inner face
                      gradient: isLocked
                          ? const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFEEEEEE)],
                            )
                          : const LinearGradient(
                              begin: Alignment.bottomRight,
                              end: Alignment.topLeft,
                              colors: [
                                Color(0xFFFFE57C), // Lighter Gold
                                Color(0xFFDAA520),
                              ],
                            ),
                    ),
                    child: Stack(
                      children: [
                        // Shine effect
                        if (!isLocked)
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
                                  color: isLocked
                                      ? Colors.grey.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                    color: isLocked
                                        ? Colors.grey.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  iconData,
                                  size: size * 0.35,
                                  color: isLocked
                                      ? Colors.grey[400]
                                      : Colors.white,
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
