import 'package:flutter/material.dart';
import '../theme/pixel_colors.dart';

/// Retro pixel-style card widget
/// 
/// Features:
/// - Thick pixel borders (2-4px)
/// - Sharp square corners
/// - Flat pixel shadow (offset, no blur)
/// - Card-based layout like game menu cards
class PixelCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double shadowOffset;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  
  const PixelCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 3.0,
    this.shadowOffset = 4.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? PixelColors.card;
    final borderColor = this.borderColor ?? PixelColors.border;
    
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        // No rounded corners - sharp square
        boxShadow: [
          BoxShadow(
            color: PixelColors.shadow,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0, // No blur - flat pixel shadow
            spreadRadius: 0,
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

