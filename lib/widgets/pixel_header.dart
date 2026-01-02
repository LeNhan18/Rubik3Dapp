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
      padding: const EdgeInsets.only(left: 4, right: 0, top: 8, bottom: 8),
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          if (showBackButton) ...[
            PixelButton(
              text: '<',
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              backgroundColor: PixelColors.primaryDark,
              width: 28,
              height: 28,
              borderWidth: 2,
              shadowOffset: 2,
              isLarge: false,
            ),
            const SizedBox(width: 4),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          if (logoText != null) ...[
            Flexible(
              child: Text(
                logoText!,
                style: GoogleFonts.pressStart2p(
                  fontSize: 9,
                  color: PixelColors.background,
                  letterSpacing: 0.8,
                  height: 1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.pressStart2p(
                fontSize: 9,
                color: PixelColors.background,
                letterSpacing: 0.1,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          if (actions != null) ...[
            ...actions!,
          ],
        ],
      ),
    );
  }
}

