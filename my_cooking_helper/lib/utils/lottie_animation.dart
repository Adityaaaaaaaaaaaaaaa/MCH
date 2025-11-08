import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieOverlay extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool repeat;
  final Color? backgroundColor;
  final VoidCallback? onCompleted;
  final FrameRate? frameRate;

  const LottieOverlay({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.repeat = true,
    this.backgroundColor,
    this.onCompleted,
    this.frameRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      child: Center(
        child: Lottie.asset(
          assetPath,
          frameRate: FrameRate.max,
          width: width ?? 300,
          height: height ?? 300,
          fit: BoxFit.contain,
          repeat: repeat,
          onLoaded: (composition) {
            if (!repeat && onCompleted != null) {
              Future.delayed(composition.duration, onCompleted!);
            }
          },
        ),
      ),
    );
  }
}

class LottieAnimationController {
  BuildContext? _context;
  bool _isShown = false;

  void show({
    required BuildContext context,
    required String assetPath,
    double? width,
    double? height,
    bool repeat = true,
    Color? backgroundColor,
    VoidCallback? onCompleted,
    bool barrierDismissible = false,
  }) {
    if (_isShown) return;
    _context = context;
    _isShown = true;
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (_) => LottieOverlay(
        assetPath: assetPath,
        width: width,
        height: height,
        repeat: repeat,
        backgroundColor: backgroundColor,
        onCompleted: () {
          if (onCompleted != null) onCompleted();
          hide();
        },
      ),
    );
  }

  void hide() {
    if (_isShown && _context != null) {
      Navigator.of(_context!, rootNavigator: true).pop();
      _isShown = false;
      _context = null;
    }
  }
}
