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
  final Function() onMenuTap;
  final LeadingWidgetController controller;
  const LeadingWidget(
      {super.key, required this.controller, required this.onMenuTap});
  @override
  State<LeadingWidget> createState() => _LeadingWidgetState();
}

class _LeadingWidgetState extends State<LeadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationIconController;
  bool isarrowmenu = false;
  int _widgetId = 0; // 0 = hamburger 1 = back

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _animationIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      reverseDuration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    // _leadingWidgetController.dispose();
    super.dispose();
  }

  void changeWidget(id) {
    setState(() => _widgetId = id);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      //GestureDetector(
      onTap: () {
        setState(() {
          widget.onMenuTap();
        });
      },
      child: ClipOval(
        child: SizedBox(
          width: 45,
          height: 45,
          child: Center(
            child: AnimatedIcon(
              icon: _widgetId == 0
                  ? AnimatedIcons.menu_arrow
                  : AnimatedIcons.arrow_menu,
              progress: _animationIconController,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
  /*
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isarrowmenu
              ? _animationIconController1.reverse()
              : _animationIconController1.forward();
          isarrowmenu = !isarrowmenu;
          widget.onMenuTap();
        });
      },
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 2.5,
              color: Colors.green,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(50.0),
            ),
          ),
          width: 75,
          height: 75,
          child: Center(
            child: AnimatedIcon(
              icon: AnimatedIcons.arrow_menu,
              progress: _animationIconController1,
              color: Colors.red,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }
  */

