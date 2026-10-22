import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:playbook/src/scenario.dart';

typedef ScenarioWidgetBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
    );

class ScenarioWidget extends StatelessWidget {
  const ScenarioWidget({
    super.key,
    required this.scenario,
    this.canvasColor,
    this.checkeredColor,
    this.checkeredRectSize,
    this.builder,
    required this.useMaterial,
  });

  final Color? canvasColor;
  final Color? checkeredColor;
  final double? checkeredRectSize;
  final bool useMaterial;
  final Scenario scenario;
  final ScenarioWidgetBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final child = Align(
      alignment: scenario.alignment,
      child: builder?.call(context, scenario.child) ?? scenario.child,
    );

    final color = checkeredColor != null ? canvasColor : null;
    final content = checkeredColor != null
        ? Checkered(
            rectSize: checkeredRectSize ?? 5,
            color: checkeredColor!,
            child: child,
          )
        : child;

    return useMaterial
        ? Material(
            color: color,
            child: content,
          )
        : Container(
            color: color,
            child: content,
          );
  }
}

class Checkered extends StatelessWidget {
  const Checkered({
    super.key,
    required this.rectSize,
    required this.color,
    required this.child,
  });

  final double rectSize;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CheckeredPainter(
        rectSize: rectSize,
        color: color,
      ),
      child: child,
    );
  }
}

class CheckeredPainter extends CustomPainter {
  const CheckeredPainter({
    super.repaint,
    required this.rectSize,
    required this.color,
  });

  final double rectSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..shader = _shader(rectSize, color);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        (size.width ~/ rectSize + 1) * rectSize,
        (size.height ~/ rectSize + 1) * rectSize,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final _checkeredTiles = <(double, Color), (ui.Image, ui.ImageShader)>{};

ui.ImageShader _shader(double cell, Color color) {
  final key = (cell, color);
  final cached = _checkeredTiles[key];
  if (cached != null) return cached.$2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()
    ..color = color
    ..isAntiAlias = false;
  canvas
    ..drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint)
    ..drawRect(const Rect.fromLTWH(1, 1, 1, 1), paint);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(2, 2);
  picture.dispose();
  final matrix = Float64List(16)
    ..[0] = cell
    ..[5] = cell
    ..[10] = 1
    ..[15] = 1;
  final shader = ui.ImageShader(
    image,
    TileMode.repeated,
    TileMode.repeated,
    matrix,
    filterQuality: FilterQuality.none,
  );
  if (_checkeredTiles.length >= 4) {
    final oldest = _checkeredTiles.remove(_checkeredTiles.keys.first)!;
    oldest.$2.dispose();
    oldest.$1.dispose();
  }
  _checkeredTiles[key] = (image, shader);
  return shader;
}
