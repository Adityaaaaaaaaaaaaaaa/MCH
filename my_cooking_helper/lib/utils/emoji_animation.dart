import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmojiAnimation extends StatelessWidget {
  final String name;
  final double size;
  final bool repeat;
  final Key? key;

  const EmojiAnimation({
    this.key,
    required this.name,
    this.size = 30,
    this.repeat = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animated_emojis/$name.json',
        repeat: repeat,
        fit: BoxFit.contain,
      ),
    );
  }
}
