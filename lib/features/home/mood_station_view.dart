import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MoodStationView extends StatelessWidget {
  const MoodStationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "How are you feeling?",
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Select your mood to tune into your vibe.",
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[500]),
            ),

            const SizedBox(height: 60),

            // Mood Grid
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive grid count based on width
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : (constraints.maxWidth > 600 ? 2 : 1);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.2,
                  children: [
                    _buildMoodCard(
                      label: "Happy",
                      icon: Icons.sunny,
                      color: Colors.orange[50]!,
                      iconColor: Colors.orange,
                      description: "Upbeat & Energetic",
                    ),
                    _buildMoodCard(
                      label: "Melancholy",
                      icon: Icons.cloud,
                      color: Colors.blueGrey[50]!,
                      iconColor: Colors.blueGrey,
                      description: "Sad & Reflective",
                    ),
                    _buildMoodCard(
                      label: "Peaceful",
                      icon: Icons.spa,
                      color: Colors.green[50]!,
                      iconColor: Colors.green,
                      description: "Calm & Relaxing",
                    ),
                    _buildMoodCard(
                      label: "Focused",
                      icon: Icons.coffee,
                      color: Colors.brown[50]!,
                      iconColor: Colors.brown,
                      description: "Deep Work & Study",
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard({
    required String label,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String description,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Play music based on mood
          Get.snackbar(
            "Mood Selected",
            "Playing $label tunes...",
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: 24),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
