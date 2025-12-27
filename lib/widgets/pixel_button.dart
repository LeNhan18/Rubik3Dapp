import 'package:flutter/material.dart';
import '../theme/pixel_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Retro pixel-style button widget
/// 
/// Features:
/// - Thick pixel borders (2-4px)
/// - Sharp square corners
/// - Flat pixel shadow (offset, no blur)
/// - Pressed state animation
class PixelButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double borderWidth;
  final double shadowOffset;
  final IconData? icon;
  final bool isLarge;
  
  const PixelButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.borderWidth = 3.0,
    this.shadowOffset = 4.0,
    this.icon,
    this.isLarge = false,
  }) : super(key: key);
  
  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? PixelColors.primary;
    final textColor = widget.textColor ?? PixelColors.background;
    final borderColor = widget.borderColor ?? PixelColors.border;
    final pressedColor = widget.backgroundColor?.withOpacity(0.8) ?? PixelColors.buttonPressed;
    
    final fontSize = widget.isLarge ? 18.0 : 14.0;
    final padding = widget.isLarge 
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(
          top: _isPressed ? widget.shadowOffset : 0,
          left: _isPressed ? widget.shadowOffset : 0,
          right: _isPressed ? 0 : widget.shadowOffset,
          bottom: _isPressed ? 0 : widget.shadowOffset,
        ),
        decoration: BoxDecoration(
          color: _isPressed ? pressedColor : bgColor,
          border: Border.all(
            color: borderColor,
            width: widget.borderWidth,
          ),
          // No rounded corners - sharp square
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _isPressed ? PixelColors.shadow.withOpacity(0.1) : null,
          ),
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: textColor,
                  size: fontSize + 4,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text.toUpperCase(),
                style: GoogleFonts.pixelifySans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

