import 'package:flutter/material.dart';

class Zoomer extends StatelessWidget {
  final Function onZoomChanged;
  bool isOpen = false;
  final double zoom;
  final double width;
  final double height;

  Zoomer({
    super.key,
    required this.onZoomChanged,
    required this.zoom,
    this.isOpen = false,
    this.width = 50,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      curve: Curves.easeInOut,
      height: height,
      // color: Colors.blueAccent,
      width: width,
      duration: Duration(milliseconds: 300),
      decoration: /* isOpen
          ? */
          BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(
                  45.0)) /*  : ShapeDecoration(shape: CircleBorder()),*/,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
        child: Row(
          children: <Widget>[
            IconButton(
                onPressed: () => (isOpen = !isOpen),
                icon:
                    Icon(isOpen ? Icons.cancel : Icons.zoom_out_map_outlined)),
            Slider(value: 10, max: 20, onChanged: (_) => ())
          ],
        ),
      ),
    );
  }
}

/*

                child: AnimatedContainer(
                  height: 60,
                  curve: Curves.easeInOut,
                  duration: const Duration(seconds: 3),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: _showSearch
                        ? SearchLocation(onSelect: locationLatLng)
                        : setPreferences(),
                  ),
                ),

Widget buildStar(BuildContext context, int index) {
   Icon icon;
    if (index >= rating) {
      icon = Icon(Icons.star_border,
          color: Theme.of(context).primaryColor); // Theme.of(context).);
    } else if (index > rating - 1 && index < rating) {
      icon = Icon(Icons.star_half, color: Theme.of(context).primaryColor);
    } else {
      icon = Icon(Icons.star, color: Theme.of(context).primaryColor);
    }
    return InkResponse(
      onTap: () => onRatingChanged(index + 1),
      child: icon,
    );
  }
  */
