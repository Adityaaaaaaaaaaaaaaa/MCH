import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

Widget loader(
  Color color,
  double size,
  double lineWidth,
  int itemCount,
  int milliseconds,
) {
  return SpinKitSpinningLines(
    color: color,
    size: size,
    lineWidth: lineWidth,
    itemCount: itemCount,
    duration: Duration(milliseconds: milliseconds),
  );
}
