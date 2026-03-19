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

  void refresh() {
    try {
      _bottomDrawerState?.refresh();
    } catch (e) {
      debugPrint("Can't refresh bottom drawer: ${e.toString()}");
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
      debugPrint("Can't open bottom drawer: ${e.toString()}");
    }
  }

  void setContent({required List<Card> content}) {
    try {
      _bottomDrawerState?.setContent(content);
    } catch (e) {
      debugPrint("Can't set bottom drawer content: ${e.toString()}");
    }
  }

  double getHeight() {
    return _bottomDrawerState?.height ?? 0;
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
  final BuildContext context;
  final double maxHeight;
  final double height;
  final double closedTop;
  final double dividerHeight;
  final List<Card>? content;
  final BottomDrawerController? controller;
  final ScrollController? scrollController;

  const BottomDrawer(
      {super.key,
      required this.context,
      this.controller,
      this.scrollController,
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

  final GlobalKey _key = GlobalKey();
  //  List<Card> _content = [Card(child: Text('Nothing to show'))];

  ListView _content = ListView(
    controller: ScrollController(),
    children: [Card(child: Text('Nothing to show'))],
  );

  void initState() {
    super.initState;
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void close() {
    if (mounted) {
      setState(() => height = 0);
    }
  }

  void refresh() {
    if (mounted) {
      setState(() => ()); // setContentBottom());
    }
  }

  void setContent(List<Card> content) {
    try {
      // setState(() => _content = content);
      developer.log(
          'setContent() called in bottom_drawer.dart content.length: ${content.length}',
          name: '_focus');
      _content = ListView(
        controller: widget.scrollController,
        children: content,
      );
      // _content = content;
    } catch (e) {
      developer.log('Error setting BottomDrawer setContent(): ${e.toString()}',
          name: '_focus');
    }
  }

  void open(newHeight) {
    try {
      setContentBottom();
      delay = 500;
      height = height == 0
          ? newHeight == 0
              ? widget.maxHeight
              : newHeight.toDouble()
          : 0;
      contentHeight = MediaQuery.of(context).size.height;
      developer.log(
          'bottom_drawer.dart height: $height  contentHeight: $contentHeight',
          name: '_focus');
    } catch (e) {
      developer.log('Error bottom_drawer.open(): ${e.toString()}',
          name: '_focus');
    }
    try {
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      developer.log('Error bottom_drawer.open(): ${e.toString()}',
          name: '_focus');
    }
  }

  void setHeight({double height = 0}) {
    height = height;
  }

  void dockOpenTile({required GlobalKey<State<StatefulWidget>> key}) {
    try {
      var box = key.currentContext!.findRenderObject() as RenderBox;
      height = box.size.height < 400 ? box.size.height + 4 : 400;
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0, // 0.0 = top of screen, 0.5 = middle, 1.0 = bottom
      );

      double yPos = widgetPosition(key: _key).y.toDouble();
      double yPosT = widgetPosition(key: key).y.toDouble();
      double delta = 32 + yPosT - yPos;
      if (delta > 0) {
        _content.controller!.animateTo(delta,
            duration: Duration(milliseconds: 500), curve: Curves.ease);
      }

      // Point point = widgetPosition(key: key);
    } catch (e) {
      developer.log('Error dockOpenTile(): ${e.toString()}', name: '_focus');
      // height = 400;
      // contentHeight = 380;
    }
  }

  Point widgetPosition({required GlobalKey<State<StatefulWidget>> key}) {
    Point pos = Point(0, 0);
    final bnKeyContext = key.currentContext;
    if (bnKeyContext != null) {
      final box = bnKeyContext.findRenderObject() as RenderBox;
      pos = Point(
          box.localToGlobal(Offset.zero).dx, box.localToGlobal(Offset.zero).dy);
      developer.log('widgetPosition():  $pos', name: '_focus');
    } else {
      developer.log('widgetPosition():  GlobalKey is null', name: '_focus');
    }
    return pos;
  }

  void setContentBottom({double offset = 0}) {
    try {
      contentBottom = contentBottom == 0 && widgetPosition(key: _key).y > 300
          ? widgetPosition(key: _key).y + offset
          : contentBottom;
      developer.log('setContentBottom() about to dismiss keyboard',
          name: '_focus');
      FocusManager.instance.primaryFocus?.unfocus(); // dismiss keyboard
      // setState(() => height++);
    } catch (e) {
      developer.log('Error bottom_drawer.setContentBottom(): ${e.toString()}',
          name: '_focus');
    }
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
          //   setState(() {
          Point pos = widgetPosition(key: _key);
          contentHeight = contentBottom - pos.y;
          contentHeight = contentHeight < 0 ? 0 : contentHeight;
          contentHeight =
              height > 10 ? MediaQuery.of(context).size.height : 0; // DEBUG
          //   });
          if (widget.onOpened != null) {
            widget.onOpened!(height > 10);
          }
          if (widget.onChangeHeight != null) {
            widget.onChangeHeight!(height);
          }
          developer.log(
              'AnimatedContainer.onEnd _key: $_key  pos: $pos  contentBottom: $contentBottom  contentHeight: $contentHeight',
              name: '_focus');
          if (mounted) {
            setState(() => ());
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
