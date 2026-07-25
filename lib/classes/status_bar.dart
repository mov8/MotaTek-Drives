import 'package:flutter/material.dart';
import '../services/services.dart';
import '../screens/screens.dart';
import 'dart:developer' as developer;

class StatusBarController {
  _StatusBarState? _statusBarState;

  void _addState(_StatusBarState statusBarState) {
    _statusBarState = statusBarState;
  }

  bool get isAttached => _statusBarState != null;

  void refresh() {
    _statusBarState?._refresh();
  }

  void update(List<String> messages) {
    if (_statusBarState != null) {
      _statusBarState?._update(messages[0]);
    }
  }

  void clear() {
    if (_statusBarState != null) {
      _statusBarState?._clear();
    }
  }
}

class StatusBar extends StatefulWidget {
  Color? color;
  double height;
  List<Widget>? items;
  TextStyle? style;
  StatusBarController? controller;
  double start = 0;
  StatusBar({
    super.key,
    List<Widget>? items,
    this.height = 50,
    Color? color,
    TextStyle? style,
    this.controller,
  })  : color = color ?? Colors.blueAccent,
        style = style ?? TextStyle(color: Colors.white, fontSize: 12),
        items = items ?? <Widget>[];
  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  double startPosition = 0;
  double keyLength = 0;
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller?._addState(this);
    }
  }

  void _refresh() async {
    setState(() {});
  }

  void _update(String message) {
    try {
      widget.items!.removeWhere((i) => i.runtimeType != MapKeyScale);
      setState(
        () => widget.items!.insert(
          0,
          BarMessage(start: 10, message: message, width: 700, height: 20),
        ),
      );
    } catch (e) {
      debugPrint('error: ${e.toString()}');
    }
  }

  void _clear() {
    try {
      widget.items!.removeWhere((i) => i.runtimeType != MapKeyScale);
      setState(
        () => widget.items!.insert(
          0,
          BarMessage(start: 10, message: ' ', width: 700, height: 20),
        ),
      );
    } catch (e) {
      debugPrint('error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = widget.items ?? [];
    return Align(
      alignment: AlignmentGeometry.bottomStart,
      child: Container(
        height: 20,
        color: Colors.blue,
        width: MediaQuery.of(context).size.width,
        child: Stack(children: [Row(children: children), MapKeyScale()]),
      ),
    );
  }
}

/* 
  child: ShaderMask(
    shaderCallback: (rect) => LinearGradient(
      colors: [Colors.black, Colors.transparent],
      stops: [0.9, 1.0], // Fade out the last 10%
    ).createShader(rect),
    blendMode: BlendMode.dstIn,
    child: CustomPaint(painter: HintPainter(hints)),
  ),
*/

class MapKeyScale extends StatelessWidget {
  final double start;
  final double width;
  final double height;
  final bool alignRight;
  final Function(double)? onDraw;

  const MapKeyScale(
      {super.key,
      this.start = 0,
      this.height = 20,
      this.width = 200,
      this.alignRight = true,
      this.onDraw});

  @override
  build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: LinearScale(
        start: start,
        width: width,
        mapWidthPixels: MapService().mapWidth,
        mapWidthMeters: MapService().mapWidthMeters,
        screenWidth: MediaQuery.of(context).size.width,
        onDraw: onDraw,
      ),
    );
  }
}

class BarMessage extends StatelessWidget {
  final double start;
  final String message;
  final double width;
  final double height;
  final bool alignLeft;
  final Function(double)? onDraw;

  const BarMessage(
      {super.key,
      this.start = 0,
      this.message = '',
      this.height = 20,
      this.width = 300,
      this.alignLeft = true,
      this.onDraw});

  @override
  build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: BarMessagePainter(
          start: start, width: width, message: message, onDraw: onDraw),
    );
  }
}
