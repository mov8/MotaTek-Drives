// https://stackoverflow.com/questions/63781518/flutter-how-to-use-animated-icon-in-the-appbar-i-want-to-use-this-animated-ic
// https://api.flutter.dev/flutter/material/AnimatedIcons-class.html
import 'package:flutter/material.dart';

class LeadingWidgetController {
  _LeadingWidgetState? _leadingWidgetState;

  void _addState(_LeadingWidgetState leadingWidgetState) {
    _leadingWidgetState = leadingWidgetState;
  }

  bool get isAttached => _leadingWidgetState != null;

  void changeWidget(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _leadingWidgetState?.changeWidget(id);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}

class LeadingWidget extends StatefulWidget {
  final Function(int) onMenuTap;
  final LeadingWidgetController controller;
  final int initialValue;
  const LeadingWidget(
      {super.key,
      required this.controller,
      required this.onMenuTap,
      this.initialValue = 0});
  @override
  State<LeadingWidget> createState() => _LeadingWidgetState();
}

class _LeadingWidgetState extends State<LeadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationIconController;
  late Animation<double> animation;
  bool isarrowmenu = false;
  int _widgetId = 0; // 0 = hamburger 1 = back

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _animationIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationIconController);
    changeWidget(widget.initialValue);
  }

  @override
  void dispose() {
    // _leadingWidgetController.dispose();
    super.dispose();
  }

  void changeWidget(id) {
    setState(() {
      _widgetId = id;
      if (_widgetId == 0) {
        _animationIconController.reverse();
      } else {
        _animationIconController.forward();
      }
      animation =
          Tween<double>(begin: 0.0, end: 1.0).animate(_animationIconController);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      //GestureDetector(
      onTap: () {
        setState(() {
          widget.onMenuTap(_widgetId);
        });
      },
      child: ClipOval(
        child: SizedBox(
          width: 45,
          height: 45,
          child: Center(
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_arrow,
              progress: animation,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
