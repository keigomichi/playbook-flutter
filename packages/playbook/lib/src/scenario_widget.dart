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
    canvas.drawPath(_cachedPath(size, rectSize), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final _checkeredPaths = <(Size, double), (Path, int)>{};
const _maxPathEntries = 4;
const _maxCachedCells = 500000;
var _cachedCells = 0;

Path _buildCheckeredPath(Size size, double cell, {required bool integer}) {
  final rows = size.height ~/ cell + 1;
  final columns = size.width ~/ cell + 1;
  final path = Path();
  for (var row = 0; row < rows; row++) {
    final y = row * cell;
    for (
      var column = integer ? row % 2 : 0;
      column < columns;
      column += integer ? 2 : 1
    ) {
      final x = column * cell;
      if (integer || (x ~/ cell).isOdd == (y ~/ cell).isOdd) {
        path
          ..moveTo(x, y)
          ..lineTo(x + cell, y)
          ..lineTo(x + cell, y + cell)
          ..lineTo(x, y + cell)
          ..close();
      }
    }
  }
  return path;
}

bool _integerGridIsExact(Size size, double cell) {
  const exactIntegerLimit = 9007199254740992.0;
  return cell == cell.truncateToDouble() &&
      cell > 0 &&
      cell < exactIntegerLimit &&
      (size.width ~/ cell + 1) * cell < exactIntegerLimit &&
      (size.height ~/ cell + 1) * cell < exactIntegerLimit;
}

Path _cachedPath(Size size, double cell) {
  final key = (size, cell);
  final cached = _checkeredPaths.remove(key);
  if (cached != null) {
    _checkeredPaths[key] = cached;
    return cached.$1;
  }
  final path = _buildCheckeredPath(
    size,
    cell,
    integer: _integerGridIsExact(size, cell),
  );
  final cells = (size.width ~/ cell + 1) * (size.height ~/ cell + 1);
  if (cells <= _maxCachedCells) {
    while (_checkeredPaths.length >= _maxPathEntries ||
        _cachedCells + cells > _maxCachedCells) {
      final oldest = _checkeredPaths.remove(_checkeredPaths.keys.first)!;
      _cachedCells -= oldest.$2;
    }
    _checkeredPaths[key] = (path, cells);
    _cachedCells += cells;
  }
  return path;
}
