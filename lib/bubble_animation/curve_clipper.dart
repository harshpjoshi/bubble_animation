import 'package:flutter/material.dart';

class CurveClipper extends CustomClipper<Path> {
  CurveClipper(this.path, this.height, this.width);

  Path path;
  double height;
  double width;

  @override
  Path getClip(Size size) {
    Path fillPath = Path()..addPath(path, Offset.zero);
    Rect rect = path.getBounds();
    print(rect.size);
    print(rect.bottomLeft);
    print(rect.bottomRight);

    fillPath.lineTo(width, height);
    fillPath.lineTo(rect.bottomLeft.dx, height);
    fillPath.close();

    return fillPath;
  }

  @override
  bool shouldReclip(CurveClipper oldClipper) => false;
}
