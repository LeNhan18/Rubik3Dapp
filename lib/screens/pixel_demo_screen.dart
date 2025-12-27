import 'package:flutter/material.dart';
import '../theme/pixel_theme.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_text.dart';

/// Demo screen showcasing Pixel Art Retro UI
/// 
/// Features:
/// - Header with logo + navigation
/// - Card-based layout
/// - Retro game menu style
/// - Grid layout for content
class PixelDemoScreen extends StatelessWidget {
  const PixelDemoScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Art Retro UI',
      theme: PixelTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: PixelColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              PixelHeader(
                title: 'Pixel Art Retro',
                logoText: '8BIT',
                showBackButton: false,
                actions: [
                  PixelButton(
                    text: 'MENU',
                    onPressed: () {},
                    backgroundColor: PixelColors.primaryDark,
                    width: 80,
                    height: 40,
                    borderWidth: 2,
                    shadowOffset: 2,
                  ),
                ],
              ),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title card
                      PixelCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            PixelText(
                              text: 'WELCOME TO',
                              style: PixelTextStyle.headline,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            PixelText(
                              text: 'RETRO GAME UI',
                              style: PixelTextStyle.display,
                              color: PixelColors.primary,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Menu grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildMenuCard(
                            icon: Icons.play_arrow,
                            title: 'PLAY',
                            subtitle: 'Start Game',
                            color: PixelColors.accent,
                          ),
                          _buildMenuCard(
                            icon: Icons.settings,
                            title: 'SETTINGS',
                            subtitle: 'Options',
                            color: PixelColors.primary,
                          ),
                          _buildMenuCard(
                            icon: Icons.leaderboard,
                            title: 'SCORES',
                            subtitle: 'High Scores',
                            color: PixelColors.accentDark,
                          ),
                          _buildMenuCard(
                            icon: Icons.info,
                            title: 'ABOUT',
                            subtitle: 'Info',
                            color: PixelColors.primaryLight,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      PixelText(
                        text: 'ACTIONS',
                        style: PixelTextStyle.title,
                        color: PixelColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      
                      PixelButton(
                        text: 'PRIMARY ACTION',
                        onPressed: () {},
                        backgroundColor: PixelColors.primary,
                        isLarge: true,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      PixelButton(
                        text: 'SECONDARY ACTION',
                        onPressed: () {},
                        backgroundColor: PixelColors.accent,
                        isLarge: true,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: PixelButton(
                              text: 'CANCEL',
                              onPressed: () {},
                              backgroundColor: PixelColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PixelButton(
                              text: 'CONFIRM',
                              onPressed: () {},
                              backgroundColor: PixelColors.success,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Info card
                      PixelCard(
                        backgroundColor: PixelColors.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PixelText(
                              text: 'GAME INFO',
                              style: PixelTextStyle.title,
                              color: PixelColors.primary,
                            ),
                            const SizedBox(height: 12),
                            PixelText(
                              text: 'This is a pixel art retro UI demo inspired by classic NES/SNES games.',
                              style: PixelTextStyle.body,
                            ),
                            const SizedBox(height: 8),
                            PixelText(
                              text: 'Features:',
                              style: PixelTextStyle.subtitle,
                            ),
                            const SizedBox(height: 4),
                            PixelText(
                              text: '• Thick pixel borders\n• Sharp square corners\n• Flat pixel shadows\n• Warm pastel colors\n• Pixel fonts',
                              style: PixelTextStyle.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return PixelCard(
      backgroundColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: PixelColors.background,
          ),
          const SizedBox(height: 12),
          PixelText(
            text: title,
            style: PixelTextStyle.button,
            color: PixelColors.background,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          PixelText(
            text: subtitle,
            style: PixelTextStyle.caption,
            color: PixelColors.background.withOpacity(0.9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

