import 'package:flutter/material.dart';

class RotatingIconController {
  _RotatingIconState? _rotatingIconState;

  void _addState(_RotatingIconState rotatingIconState) {
    _rotatingIconState = rotatingIconState;
  }

  bool get isAttached => _rotatingIconState != null;

  void rotate({double rotation = 0.5}) {
    _rotatingIconState?._rotate();
  }

  bool get rotated => _rotatingIconState!.turns != 0;
}

class RotatingIcon extends StatefulWidget {
  Icon? icon = Icon(Icons.arrow_circle_right_outlined);
  num? turns = 0.5;
  Color? color = Colors.blueAccent;
  double? size = 30;
  Function(double)? onClick;
  RotatingIconController? controller;
  RotatingIcon(
      {super.key,
      this.icon,
      this.turns,
      this.color,
      this.size,
      this.onClick,
      this.controller});

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon> {
  double turns = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
  }

  void _rotate() {
    if (widget.onClick != null) {
      widget.onClick!(turns); //turns += (widget.turns ?? 0.5));
    } else {
      setState(() => turns = turns == 0 ? 0.5 : 0); //+= (widget.turns ?? 0.5));
    }
    // turns = turns > 1 ? 0 : turns;
  }

  bool get rotated => turns > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: AnimatedRotation(
        turns: turns,
        duration: const Duration(seconds: 1),
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(0, 0, 10, 0),
          child: IconButton(
            onPressed: _rotate,
            icon: widget.icon ??
                Icon(
                  Icons.arrow_circle_right_outlined,
                  size: widget.size,
                  color: Colors.blueAccent,
                ),
          ),
        ),
      ),
    );
  }
}
