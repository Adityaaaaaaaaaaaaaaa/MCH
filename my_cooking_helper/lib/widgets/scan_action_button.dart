import 'package:flutter/material.dart';

import '/utils/colors.dart';

class ScanActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const ScanActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
      ),
      onPressed: onPressed,
      icon: Icon(
        icon, size: 30,
        color: Colors.white,),
      label: Text(
        label,
        style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w600, 
            color: textColor(context),
          ),
      ),
    );
  }
}
