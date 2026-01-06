import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// The Map pages BottomDrawer is to allow the following data
/// Trip details on planning and saving
/// Display of waypoints and points of interest

class BottomDrawerController {
  _BottomDrawerState? _bottomDrawerState;

  void _addState(_BottomDrawerState bottomDrawerState) {
    _bottomDrawerState = bottomDrawerState;
  }

  bool get isAttached => _bottomDrawerState != null;

  void close() {
    try {
      _bottomDrawerState?.close();
    } catch (e) {
      debugPrint("Can't close bottom drawer: ${e.toString()}");
    }
  }

  void open() {
    try {
      _bottomDrawerState?.open();
    } catch (e) {
      debugPrint("Can't close bottom drawer: ${e.toString()}");
    }
  }

  void setHeight(height) {
    try {
      _bottomDrawerState?.setHeight(height: height);
    } catch (e) {
      debugPrint("Can't close bottom drawer: ${e.toString()}");
    }
  }
}

class BottomDrawer extends StatefulWidget {
  final Function(double)? onChangeHeight;
  final double maxHeight;
  final double height;
  final double closedTop;
  final double dividerHeight;
  final Widget? content;
  final BottomDrawerController? controller;

  const BottomDrawer(
      {super.key,
      this.controller,
      this.maxHeight = 0,
      this.height = 0,
      this.closedTop = 0,
      this.onChangeHeight,
      this.dividerHeight = 30,
      this.content});
  @override
  State<BottomDrawer> createState() => _BottomDrawerState();
}

class _BottomDrawerState extends State<BottomDrawer>
    with TickerProviderStateMixin {
  double height = 0;
  double contentBottom = 0;
  double contentHeight = 0;
  int delay = 500;
  final GlobalKey _key = GlobalKey();

  void initState() {
    super.initState;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void close() {
    setState(() => height = 0);
  }

  void open() {
    setState(() => height = widget.maxHeight);
  }

  void setHeight({double height = 0}) {
    height = height;
  }

  Point widgetPosition({required GlobalKey<State<StatefulWidget>> key}) {
    Point pos = Point(0, 0);
    final bnKeyContext = key.currentContext;
    if (bnKeyContext != null) {
      final box = bnKeyContext.findRenderObject() as RenderBox;
      pos = Point(
          box.localToGlobal(Offset.zero).dx, box.localToGlobal(Offset.zero).dy);
    }
    return pos;
  }

  void setContentBottom({double offset = 0}) {
    contentBottom = contentBottom == 0 && widgetPosition(key: _key).y > 500
        ? widgetPosition(key: _key).y + offset
        : contentBottom;
    return;
  }

  @override
  Widget build(BuildContext context) {
    double _dividerHeight = 35;
    double _visibility = 0.0;

    return Align(
      alignment: Alignment.bottomLeft,
      child: AnimatedContainer(
        key: _key,
        duration: Duration(milliseconds: delay),
        curve: Curves.easeOut, // fastOutSlowIn,
        height: height + _dividerHeight,
        width: mounted ? MediaQuery.of(context).size.width : 100,
        onEnd: () {
          setState(() {
            contentHeight = contentBottom - widgetPosition(key: _key).y;
            contentHeight = contentHeight < 0 ? 0 : contentHeight;
          });
        },
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: AbsorbPointer(
                      child: Container(
                        color: const Color.fromARGB(255, 158, 158, 158),
                        height: _dividerHeight,
                        width: MediaQuery.of(context).size.width,
                        child: Icon(
                          Icons.drag_handle,
                          size: _dividerHeight,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    onTap: () => setState(() {
                      setContentBottom();
                      delay = 500;
                      height = height == 0 ? widget.maxHeight : 0;

                      contentHeight = MediaQuery.of(context).size.height;
                      debugPrint('height: $height');
                    }),
                    onVerticalDragUpdate: (DragUpdateDetails details) {
                      if (delay > 1) setContentBottom();
                      setState(() {
                        delay = 1;
                        height = height - details.delta.dy > 0
                            ? height - details.delta.dy
                            : 0;
                        contentHeight -= details.delta.dy;
                        contentHeight = contentHeight < 0 || height == 0
                            ? 0
                            : contentHeight;
                        if (widget.onChangeHeight != null) {
                          widget.onChangeHeight!(height);
                        }
                      });
                    },
                  ),
                  SingleChildScrollView(
                    child: Container(
                      height: contentHeight,
                      color: Colors.blue,
                      child: widget.content,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
