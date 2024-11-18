import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';

class ImageListIndicatorController {
  _ImageListIndicatorState? _imageListIndicatorState;

  void _addState(_ImageListIndicatorState imageListIndicatorState) {
    _imageListIndicatorState = imageListIndicatorState;
  }

  bool get isAttached => _imageListIndicatorState != null;

  void changeImageIndex(int idx) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _imageListIndicatorState?.changeImageIndex(idx);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}

class ImageListIndicator extends StatefulWidget {
  final ImageListIndicatorController controller;
  final Color selectedColor;
  final Color unSelectedColor;
  final List<Photo> photos;

  const ImageListIndicator(
      {super.key,
      required this.controller,
      required this.photos,
      this.selectedColor = Colors.blueAccent,
      this.unSelectedColor = Colors.grey});
  @override
  State<ImageListIndicator> createState() => _ImageListIndicatorState();
}

class _ImageListIndicatorState extends State<ImageListIndicator> {
  int imageIndex = 0;

  @override
  initState() {
    super.initState();
    widget.controller._addState(this);
  }

  changeImageIndex(int idx) {
    imageIndex = idx;
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(flex: 1, child: SizedBox(height: 10)),
      Expanded(
        flex: 1,
        child: Row(
          children: [
            for (int i = 0; i < widget.photos.length; i++)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: i == imageIndex
                            ? widget.selectedColor
                            : widget.unSelectedColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const Expanded(flex: 1, child: SizedBox(height: 10)),
    ]);
  }
}
