import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
// import 'maplibre_map.dart';
import 'dart:developer' as developer;

class ZoomFabController {
  _ZoomFabState? _zoomFabState;
  void _addState(_ZoomFabState zoomFabState) {
    _zoomFabState = zoomFabState;
  }

  bool get isAttached => _zoomFabState != null;

  void update() => _zoomFabState?.update();
}

class ZoomFab extends StatefulWidget {
  double width;
  double height;

  MapLibreMapController controller;
  ZoomFabController zfController;
  int zoom = 0;

  ZoomFab(
      {super.key,
      required this.controller,
      required this.zfController,
      this.width = 20,
      this.height = 20});

  @override
  State<ZoomFab> createState() => _ZoomFabState();
}

class _ZoomFabState extends State<ZoomFab> {
  String _zoom = '';

  @override
  void initState() {
    super.initState();
    widget.zfController._addState(this);
  }

  update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.vertical(
          top: Radius.circular(widget.width / 2),
          bottom: Radius.circular(widget.width / 2)), //horizontal(left: R, ),

      child: Container(
        /* couldn't get shadow to work - have another go later  
          decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black54,
                offset: const Offset(1, 3),
                blurRadius: 5,
                spreadRadius: 0)
          ],
          color: Colors.blue,
          borderRadius: BorderRadius.circular(widget.width / 2)), 
        */
        color: Colors.blue,
        height: widget.height,
        width: widget.width,
        child: PointerInterceptor(
          // absorbing: false,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: IconButton(
                  onPressed: () => setState(() =>
                      (widget.controller.animateCamera(CameraUpdate.zoomIn()))),
                  icon: Icon(Icons.add_circle),
                  iconSize: widget.width * .5,
                  color: Colors.white,
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(0, 10, 0, 0),
                  child: Text(
                      widget.controller.cameraPosition!.zoom.toStringAsFixed(0),
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ),
              Expanded(
                flex: 2,
                child: IconButton(
                  onPressed: () => setState(() => (widget.controller
                      .animateCamera(CameraUpdate.zoomOut()))),
                  icon: Icon(Icons.do_not_disturb_on_rounded),
                  iconSize: widget.width * .5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
