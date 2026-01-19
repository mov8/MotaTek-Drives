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

  void dockOpenTile({required GlobalKey<State<StatefulWidget>> key}) {
    try {
      _bottomDrawerState?.dockOpenTile(key: key);
    } catch (e) {
      debugPrint("Can't dock open tile: ${e.toString()}");
    }
  }

  void open({height = 0}) {
    try {
      _bottomDrawerState?.open(height);
    } catch (e) {
      debugPrint("Can't close bottom drawer: ${e.toString()}");
    }
  }

  void setContent({required Widget content}) {
    try {
      _bottomDrawerState?.setContent(content);
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
  final Function(bool)? onOpened;
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
      this.onOpened,
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
  final ScrollController _controller = ScrollController();
  final GlobalKey _key = GlobalKey();
  late Widget _content;

  void initState() {
    super.initState;
    if (widget.controller != null) {
      widget.controller!._addState(this);
      developer.log('BottomDrawer initState() called', name: '_expand');
      _content = widget.content ?? Text('Nothing to show');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void close() {
    setState(() => height = 0);
  }

  void setContent(content) {
    developer.log('BottomDrawer content updated', name: '_expand');
    _content = content;
  }

  void open(newHeight) {
    setState(() {
      setContentBottom();

      delay = 500;
      height = height == 0
          ? newHeight == 0
              ? widget.maxHeight
              : newHeight.toDouble()
          : 0;
      contentHeight = MediaQuery.of(context).size.height;
    });
  }

  void setHeight({double height = 0}) {
    height = height;
  }

  void dockOpenTile({required GlobalKey<State<StatefulWidget>> key}) {
    var box = key.currentContext!.findRenderObject() as RenderBox;
    height = box.size.height < 400 ? box.size.height : 400;

    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.0, // 0.0 = top of screen, 0.5 = middle, 1.0 = bottom
    );

    double yPos = widgetPosition(key: _key).y.toDouble();
    double yPosT = widgetPosition(key: key).y.toDouble();
    //  var box = key.currentContext!.findRenderObject() as RenderBox;
    //  height = box.size.height;
    // height = MediaQuery.of(context).size.height - height;

    (_content as ListView).controller!.animateTo(yPosT - yPos,
        duration: Duration(milliseconds: 500), curve: Curves.ease);

    Point point = widgetPosition(key: key);
    debugPrint('Position is ${point.toString()} box = ${box.toString()}');
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
    contentBottom = contentBottom == 0 && widgetPosition(key: _key).y > 300
        ? widgetPosition(key: _key).y + offset
        : contentBottom;
    return;
  }

  @override
  Widget build(BuildContext context) {
    double dividerHeight = 35;

    return Align(
      alignment: Alignment.bottomLeft,
      child: AnimatedContainer(
        key: _key,
        duration: Duration(milliseconds: delay),
        curve: Curves.easeOut, // fastOutSlowIn,
        height: height + dividerHeight,
        width: mounted ? MediaQuery.of(context).size.width : 100,
        onEnd: () {
          setState(() {
            contentHeight = contentBottom - widgetPosition(key: _key).y;
            contentHeight = contentHeight < 0 ? 0 : contentHeight;
          });
          if (widget.onOpened != null) {
            widget.onOpened!(true);
          }
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
                        height: dividerHeight,
                        width: MediaQuery.of(context).size.width,
                        child: Icon(
                          Icons.drag_handle,
                          size: dividerHeight,
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
                      child: _content,
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
/*
static Future<void> ensureVisible(
  BuildContext context, {
  double alignment = 0.0,
  Duration duration = Duration.zero,
  Curve curve = Curves.ease,
  ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
}) {
  final List<Future<void>> futures = <Future<void>>[];

  // The targetRenderObject is used to record the first target renderObject.
  // If there are multiple scrollable widgets nested, the targetRenderObject
  // is made to be as visible as possible to improve the user experience. If
  // the targetRenderObject is already visible, then let the outer
  // renderObject be as visible as possible.
  //
  // Also see https://github.com/flutter/flutter/issues/65100
  
  RenderObject? targetRenderObject;
  ScrollableState? scrollable = Scrollable.maybeOf(context);
  while (scrollable != null) {
    final List<Future<void>> newFutures;
    (newFutures, scrollable) = scrollable._performEnsureVisible(
      context.findRenderObject()!,
      alignment: alignment,
      duration: duration,
      curve: curve,
      alignmentPolicy: alignmentPolicy,
      targetRenderObject: targetRenderObject,
    );
    futures.addAll(newFutures);

    targetRenderObject ??= context.findRenderObject();
    context = scrollable.context;
    scrollable = Scrollable.maybeOf(context);
  }

  if (futures.isEmpty || duration == Duration.zero) {
    return Future<void>.value();
  }
  if (futures.length == 1) {
    return futures.single;
  }
  return Future.wait<void>(futures).then<void>((List<void> _) => null);
}
*/
