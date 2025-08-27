import 'package:flutter/material.dart';

class InitialsButton extends StatelessWidget {
  final String initials;
  final VoidCallback onPressed;
  final double radius;
  final Color backgroundColor;
  final FontWeight fontWeight;
  final Color textColor;
  final double fontSize;

  const InitialsButton({
    super.key,
    required this.initials,
    required this.onPressed,
    this.radius = 30.0,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.bold,
    this.fontSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            initials,
            style: TextStyle(
                color: textColor, fontWeight: fontWeight, fontSize: fontSize),
          ),
        ),
      ),
    );
  }
}
