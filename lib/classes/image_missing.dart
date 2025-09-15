import 'package:flutter/material.dart';

class ImageMissing extends StatelessWidget {
  final double width;
  const ImageMissing({super.key, required this.width});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: width / 3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  Icons.no_photography,
                  size: width / 3,
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Image removed',
                style: TextStyle(fontSize: width / 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
