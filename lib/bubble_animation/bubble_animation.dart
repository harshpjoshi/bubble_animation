import 'dart:math';
import 'dart:ui';

import 'package:bubble_animation/bubble_animation/curve_clipper.dart';
import 'package:bubble_animation/bubble_animation/inverse_path_painter.dart';
import 'package:bubble_animation/bubble_animation/path_painter.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

class BubbleAnimation extends StatefulWidget {
  const BubbleAnimation({super.key});

  @override
  State<StatefulWidget> createState() {
    return BubbleAnimationState();
  }
}

class BubbleAnimationState extends State<BubbleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _animation;
  late Path _path;
  late Path _inversePath;

  Map<double, double> values = {0: 10, 25: 0, 75: -15, 90: 0, 150: 0};
  Map<double, double> inverseValues = {0: -10, 25: 0, 75: 15, 90: 0, 150: 0};

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5000));
    super.initState();
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward();
    _path = drawPath();
    _inversePath = inverseDrawPath(inverseValues);

    _animation.addListener(() {
      if (_animation.status == AnimationStatus.forward) {
        double pos = scrollController.offset;
        pos += 30;
        scrollController.animateTo(pos,
            duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.withOpacity(0.6),
      body: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(child: SizedBox()),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 400,
                width: 700,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 290,
                      child: CustomPaint(
                        painter: InversePathPainter(_inversePath),
                      ),
                    ),
                    Positioned(
                      top: calculateInverse(_animation.value).dy,
                      left: calculateInverse(_animation.value).dx,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        width: 25,
                        height: 25,
                      ),
                    ),
                    ClipPath(
                      clipper: CurveClipper(
                        _path,
                        MediaQuery.of(context).size.height,
                        MediaQuery.of(context).size.width,
                      ),
                      child: GlassContainer(
                        blur: 8,
                        height: 900,
                        width: 700,
                        color: Colors.blueAccent.withOpacity(0.3),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.grey.withOpacity(0.8),
                          ],
                        ),
                        shadowStrength: 5,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(0),
                        shadowColor: Colors.white.withOpacity(0.24),
                      ),
                    ),
                    Positioned(
                      top: calculate(_animation.value).dy,
                      left: calculate(_animation.value).dx,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/images/ball.png"),
                              fit: BoxFit.fitWidth),
                        ),
                        width: 80,
                        height: 80,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: CustomPaint(
                        painter: PathPainter(_path),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Path drawPath() {
    Size size = const Size(300, 300);
    Path path = Path();
    double yMin = double.infinity, yMax = double.negativeInfinity;
    values.forEach((key, value) {
      yMin = min(value.toDouble(), yMin);
      yMax = max(value.toDouble(), yMax);
    });

    double yStep = _calcStepSize(yMax - yMin, 20);
    yMin = yMin - (yMin % yStep);
    yMax = ((yMax / yStep).floor() + 1) * yStep;

    double paddingX = 0;
    double paddingY = 0;

    const xStart = 0;
    const xEnd = 100;

    // sort values by x position
    List<double> xValues = values.keys.toList();
    xValues.sort((a, b) => (a - b).floor());
    double xRatio = (size.width - paddingX) / (xEnd - xStart);
    double yRatio = (size.height - paddingY) / (yMax - yMin);
    for (int i = 0; i < xValues.length; i++) {
      if (i == 0) {
        if (xValues[0] == 0) {
          path.moveTo(
              paddingX,
              size.height -
                  paddingY -
                  ((values[xValues[0]] ?? 0) - yMin) * yRatio);
        } else {
          path.moveTo(paddingX, size.height - paddingY - yMin);
        }
      } else {
        final yPrevious = size.height -
            paddingY -
            ((values[xValues[i - 1]] ?? 0) - yMin) * yRatio;
        final xPrevious = xValues[i - 1] * xRatio + paddingX;
        final controlPointX =
            xPrevious + (xValues[i] * xRatio + paddingX - xPrevious) / 2;

        final yValue = size.height -
            paddingY -
            ((values[xValues[i]] ?? 0) - yMin) * yRatio;

        path.cubicTo(controlPointX, yPrevious, controlPointX, yValue,
            xValues[i] * xRatio + paddingX, yValue);
      }
    }
    return path;
  }

  Path inverseDrawPath(Map<double, double> values) {
    Size size = const Size(300, 300);
    Path path = Path();
    double yMin = double.infinity, yMax = double.negativeInfinity;
    values.forEach((key, value) {
      yMin = min(value.toDouble(), yMin);
      yMax = max(value.toDouble(), yMax);
    });

    double yStep = _calcStepSize(yMax - yMin, 20);
    yMin = yMin - (yMin % yStep);
    yMax = ((yMax / yStep).floor() + 1) * yStep;

    double paddingX = 0;
    double paddingY = 0;

    const xStart = 0;
    const xEnd = 100;

    // sort values by x position
    List<double> xValues = values.keys.toList();
    xValues.sort((a, b) => (a - b).floor());
    double xRatio = (size.width - paddingX) / (xEnd - xStart);
    double yRatio = (size.height - paddingY) / (yMax - yMin);
    for (int i = 0; i < xValues.length; i++) {
      if (i == 0) {
        if (xValues[0] == 0) {
          path.moveTo(
              paddingX,
              size.height -
                  paddingY -
                  ((values[xValues[0]] ?? 0) - yMin) * yRatio);
        } else {
          path.moveTo(paddingX, size.height - paddingY - yMin);
        }
      } else {
        final yPrevious = size.height -
            paddingY -
            ((values[xValues[i - 1]] ?? 0) - yMin) * yRatio;
        final xPrevious = xValues[i - 1] * xRatio + paddingX;
        final controlPointX =
            xPrevious + (xValues[i] * xRatio + paddingX - xPrevious) / 2;

        final yValue = size.height -
            paddingY -
            ((values[xValues[i]] ?? 0) - yMin) * yRatio;

        path.cubicTo(controlPointX, yPrevious, controlPointX, yValue,
            xValues[i] * xRatio + paddingX, yValue);
      }
    }
    return path;
  }

  Offset calculate(value) {
    PathMetrics pathMetrics = _path.computeMetrics();
    PathMetric pathMetric = pathMetrics.elementAt(0);
    value = pathMetric.length * value;
    Tangent? pos = pathMetric.getTangentForOffset(value);
    return Offset((pos?.position.dx ?? 0) - 42, (pos?.position.dy ?? 0) - 42);
  }

  Offset calculateInverse(value) {
    PathMetrics pathMetrics = _inversePath.computeMetrics();
    PathMetric pathMetric = pathMetrics.elementAt(0);
    value = pathMetric.length * value;
    Tangent? pos = pathMetric.getTangentForOffset(value);
    return Offset(
        (pos?.position.dx ?? 0) - 8, 290 + (pos?.position.dy ?? 0) - 12);
  }

  double _calcStepSize(double range, int targetSteps) {
    double tempStep = range / targetSteps;
    var magPow = pow(10, (log(tempStep) / ln10).floor());
    var magMsd = (tempStep / magPow + 0.5);
    if (magMsd > 5) {
      magMsd = 10;
    } else if (magMsd > 2) {
      magMsd = 5;
    } else if (magMsd > 1) {
      magMsd = 2;
    }
    return magMsd * magPow;
  }
}
