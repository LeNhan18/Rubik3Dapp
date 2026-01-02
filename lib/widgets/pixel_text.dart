import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/pixel_colors.dart';

/// Retro pixel-style text widget
/// 
/// Provides different text styles for pixel art UI
class PixelText extends StatelessWidget {
  final String text;
  final PixelTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const PixelText({
    Key? key,
    required this.text,
    this.style = PixelTextStyle.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final textColor = color ?? PixelColors.textPrimary;
    
    TextStyle textStyle;
    switch (style) {
      case PixelTextStyle.display:
        textStyle = GoogleFonts.pressStart2p(
          fontSize: 32,
          color: textColor,
          letterSpacing: 0,
        );
        break;
      case PixelTextStyle.headline:
        textStyle = GoogleFonts.pressStart2p(
          fontSize: 24,
          color: textColor,
          letterSpacing: 0,
        );
        break;
      case PixelTextStyle.title:
        textStyle = GoogleFonts.pixelifySans(
          fontSize: 18,
          color: textColor,
          fontWeight: FontWeight.bold,
        );
        break;
      case PixelTextStyle.subtitle:
        textStyle = GoogleFonts.pixelifySans(
          fontSize: 16,
          color: textColor,
          fontWeight: FontWeight.bold,
        );
        break;
      case PixelTextStyle.body:
        textStyle = GoogleFonts.vt323(
          fontSize: 20,
          color: textColor,
        );
        break;
      case PixelTextStyle.caption:
        textStyle = GoogleFonts.vt323(
          fontSize: 16,
          color: textColor,
        );
        break;
      case PixelTextStyle.button:
        textStyle = GoogleFonts.pixelifySans(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.bold,
        );
        break;
    }
    
    return Text(
      text,
      style: textStyle.copyWith(
        height: 1.2, // Thêm line height để tránh cắt chữ
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

enum PixelTextStyle {
  display,
  headline,
  title,
  subtitle,
  body,
  caption,
  button,
}

