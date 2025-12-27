import 'package:flutter/material.dart';
import '../theme/pixel_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pixel_button.dart';

/// Retro pixel-style header widget
/// 
/// Features:
/// - Logo + navigation buttons
/// - Pixel art style
/// - Game menu inspired layout
class PixelHeader extends StatelessWidget {
  final String title;
  final String? logoText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  
  const PixelHeader({
    Key? key,
    required this.title,
    this.logoText,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PixelColors.primary,
        border: Border(
          bottom: BorderSide(
            color: PixelColors.border,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showBackButton) ...[
            PixelButton(
              text: '<',
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              backgroundColor: PixelColors.primaryDark,
              width: 40,
              height: 40,
              borderWidth: 2,
              shadowOffset: 2,
              isLarge: false,
            ),
            const SizedBox(width: 12),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          if (logoText != null) ...[
            Text(
              logoText!,
              style: GoogleFonts.pressStart2p(
                fontSize: 20,
                color: PixelColors.background,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                color: PixelColors.background,
                letterSpacing: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 12),
            ...actions!,
          ],
        ],
      ),
    );
  }
}

